// Tiny-Vector-AI Tier 0 -- single-file bundle for ModelSim.
//
// Everything needed to simulate and view waveforms in one .v file:
// imem, dmem, vregfile, accfile, tiny_npu_core, and two testbenches
// (tb_tiny_npu = K=64 dot-product self-check, tb_align_violation =
// misaligned-VLD negative test). The canonical, one-module-per-file
// sources this was assembled from live in rtl/ and verification/ --
// keep changes in sync with those if you edit this copy.
//
// ModelSim, from the project root:
//   vlib work
//   vlog verification/tb_tiny_npu_bundle.v
//   vsim -voptargs=+acc work.tb_tiny_npu          ; K=64 self-check
//   vsim -voptargs=+acc work.tb_align_violation    ; negative test
//   (then Objects pane -> select all -> Add to Wave, or `add wave -r /*`)
//
// $readmemh below uses paths relative to the simulator's working
// directory ("verification/prog/*.hex"), so vsim must be launched from
// the project root, same as the multi-file build.

// ===========================================================================
// rtl/imem.v
// ===========================================================================
// Synchronous single-port instruction memory, 1-cycle read latency
// (addr presented one cycle, dout valid the next -- matches BRAM timing).
module imem #(
    parameter WORDS     = 512,
    parameter INIT_FILE = ""
)(
    input             clk,
    input      [15:0] addr,
    output reg [31:0] dout
);
    reg [31:0] mem [0:WORDS-1];

    initial if (INIT_FILE != "") $readmemh(INIT_FILE, mem);

    always @(posedge clk)
        dout <= mem[addr];
endmodule

// ===========================================================================
// rtl/dmem.v
// ===========================================================================
// Tier 0 data memory: one synchronous single port, byte addressed, shared by
// VLD's 32B-wide load and ACC_ST's 4B-wide store (never concurrent per
// isa_spec_1.md #5 -- v1 is single-port and hides banking behind alignment).
// 1-cycle latency: en/addr held one cycle, result registered the next.
module dmem #(
    parameter BYTES = 262144  // 0x40000, matches the v1 memory map
)(
    input                 clk,
    input                 ld_en,
    input      [18:0]     ld_addr,
    output reg [255:0]    ld_data,

    input                 st_en,
    input      [18:0]     st_addr,
    input      [31:0]     st_data
);
    reg [7:0] mem [0:BYTES-1];

    integer i;
    always @(posedge clk) begin
        if (ld_en)
            for (i = 0; i < 32; i = i + 1)
                ld_data[i*8 +: 8] <= mem[ld_addr + i];
        if (st_en)
            for (i = 0; i < 4; i = i + 1)
                mem[st_addr + i] <= st_data[i*8 +: 8];
    end
endmodule

// ===========================================================================
// rtl/vregfile.v
// ===========================================================================
// Tier 0 vector register file. NREG is an implementation choice, independent
// of the 3-bit encoding field (which can address up to 8). Out-of-range
// writes are fatal in simulation -- see isa_spec_1.md #1 "구현 범위".
module vregfile #(
    parameter NREG  = 2,
    parameter ELEMS = 32
)(
    input                       clk,
    input                       we,
    input      [2:0]            waddr,
    input      [ELEMS*8-1:0]    wdata,
    input      [2:0]            raddr1,
    input      [2:0]            raddr2,
    output     [ELEMS*8-1:0]    rdata1,
    output     [ELEMS*8-1:0]    rdata2
);
    reg [ELEMS*8-1:0] regs [0:NREG-1];

    assign rdata1 = regs[raddr1];
    assign rdata2 = regs[raddr2];

    always @(posedge clk)
        if (we) regs[waddr] <= wdata;

// synthesis translate_off
    always @(posedge clk)
        if (we && waddr >= NREG)
            $fatal(1, "vreg %0d out of range (NREG=%0d)", waddr, NREG);
// synthesis translate_on
endmodule

// ===========================================================================
// rtl/accfile.v
// ===========================================================================
// Tier 0 accumulator file. clr implements ACC_CLR; !clr accumulates wdata
// (a signed delta) into accs[addr], which is exactly VDOT's "+=" semantics
// applied one lane-product per cycle by tiny_npu_core.
module accfile #(
    parameter NACC = 1
)(
    input             clk,
    input             we,
    input             clr,
    input      [2:0]  addr,
    input      [31:0] wdata,
    output     [31:0] rdata
);
    reg [31:0] accs [0:NACC-1];

    assign rdata = accs[addr];

    always @(posedge clk)
        if (we) begin
            if (clr) accs[addr] <= 32'd0;
            else     accs[addr] <= accs[addr] + wdata;
        end

// synthesis translate_off
    always @(posedge clk)
        if (we && addr >= NACC)
            $fatal(1, "acc %0d out of range (NACC=%0d)", addr, NACC);
// synthesis translate_on
endmodule

// ===========================================================================
// rtl/tiny_npu_core.v
// ===========================================================================
// Tiny-Vector-AI Tier 0 core.
//
// Bring-up choice (ADR-004): VDOT is implemented lane=1, serial -- one
// INT8xINT8 MAC per cycle, 32 cycles per VDOT. This trades throughput for
// the simplest possible control path (no adder tree), matching PLANNING.md's
// M2 strategy of proving fetch/decode/regfile/memory before optimizing.
// Lane count is a microarchitecture parameter hidden from the ISA
// (isa_spec_1.md "lane 은닉 조항"): moving to lane=4/8/16 later only changes
// cycle count, never the binary or the result.
//
// v1 has no branches (isa_spec_1.md #7 Non-goals), so every program is
// straight-line and this FSM never stalls beyond fixed memory/VDOT latency.
module tiny_npu_core #(
    parameter NVREG      = 2,
    parameter ELEMS      = 32,
    parameter NACC       = 1,
    parameter IMEM_WORDS = 512,
    parameter DMEM_BYTES = 262144,
    parameter IMEM_INIT  = ""
)(
    input  wire clk,
    input  wire rst,
    output reg  done
);
    localparam OP_NOP     = 4'h0;
    localparam OP_VLD     = 4'h1;
    localparam OP_ACC_CLR = 4'h3;
    localparam OP_VDOT    = 4'h4;
    localparam OP_ACC_ST  = 4'h5;
    localparam OP_HALT    = 4'h6;

    localparam S_FETCH      = 3'd0;
    localparam S_FETCH_WAIT = 3'd1;
    localparam S_DECODE     = 3'd2;
    localparam S_EXEC       = 3'd3;
    localparam S_VLD_ADDR   = 3'd4;
    localparam S_VLD_CAP    = 3'd5;
    localparam S_VDOT       = 3'd6;
    localparam S_HALT       = 3'd7;

    reg [2:0]  state;
    reg [15:0] pc;
    reg [31:0] instr;

    wire [3:0]  opcode = instr[31:28];
    wire [2:0]  rd     = instr[27:25];
    wire [2:0]  rs1    = instr[24:22];
    wire [2:0]  rs2    = instr[21:19];
    wire [18:0] imm    = instr[18:0];

    // instruction memory (1-cycle synchronous read)
    reg  [15:0] imem_addr;
    wire [31:0] imem_dout;
    imem #(.WORDS(IMEM_WORDS), .INIT_FILE(IMEM_INIT)) imem_i (
        .clk(clk), .addr(imem_addr), .dout(imem_dout)
    );

    // data memory (1-cycle synchronous access, single port)
    reg          dmem_ld_en;
    reg  [18:0]  dmem_ld_addr;
    wire [255:0] dmem_ld_data;
    reg          dmem_st_en;
    reg  [18:0]  dmem_st_addr;
    reg  [31:0]  dmem_st_data;
    dmem #(.BYTES(DMEM_BYTES)) dmem_i (
        .clk(clk),
        .ld_en(dmem_ld_en), .ld_addr(dmem_ld_addr), .ld_data(dmem_ld_data),
        .st_en(dmem_st_en), .st_addr(dmem_st_addr), .st_data(dmem_st_data)
    );

    // vector register file (2 read ports for VDOT, 1 write port for VLD)
    reg                 vreg_we;
    reg  [2:0]          vreg_waddr;
    reg  [ELEMS*8-1:0]  vreg_wdata;
    wire [ELEMS*8-1:0]  vreg_rdata1, vreg_rdata2;
    vregfile #(.NREG(NVREG), .ELEMS(ELEMS)) vregfile_i (
        .clk(clk),
        .we(vreg_we), .waddr(vreg_waddr), .wdata(vreg_wdata),
        .raddr1(rs1), .raddr2(rs2),
        .rdata1(vreg_rdata1), .rdata2(vreg_rdata2)
    );

    // accumulator file
    reg         acc_we;
    reg         acc_clr;
    reg  [31:0] acc_wdata;
    wire [31:0] acc_rdata;
    accfile #(.NACC(NACC)) accfile_i (
        .clk(clk),
        .we(acc_we), .clr(acc_clr), .addr(rd), .wdata(acc_wdata),
        .rdata(acc_rdata)
    );

    // lane=1 serial VDOT: element index into the 32-element (VLEN=256b) vectors
    reg [4:0] lane_i;

    wire signed [7:0]  a_elem   = vreg_rdata1[lane_i*8 +: 8];
    wire signed [7:0]  b_elem   = vreg_rdata2[lane_i*8 +: 8];
    wire signed [31:0] mac_term = a_elem * b_elem;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= S_FETCH;
            pc           <= 16'd0;
            done         <= 1'b0;
            vreg_we      <= 1'b0;
            acc_we       <= 1'b0;
            acc_clr      <= 1'b0;
            dmem_ld_en   <= 1'b0;
            dmem_st_en   <= 1'b0;
            lane_i       <= 5'd0;
        end else begin
            // pulsed control signals default low every cycle unless a
            // branch below re-asserts them
            vreg_we    <= 1'b0;
            acc_we     <= 1'b0;
            acc_clr    <= 1'b0;
            dmem_ld_en <= 1'b0;
            dmem_st_en <= 1'b0;

            case (state)

            S_FETCH: begin
                imem_addr <= pc;
                state     <= S_FETCH_WAIT;
            end

            // imem samples imem_addr held during S_FETCH; its registered
            // dout is only valid from the following cycle, captured below.
            S_FETCH_WAIT: begin
                state <= S_DECODE;
            end

            S_DECODE: begin
                instr <= imem_dout;
                state <= S_EXEC;
            end

            S_EXEC: begin
                case (opcode)

                OP_NOP: begin
                    pc    <= pc + 16'd1;
                    state <= S_FETCH;
                end

                OP_VLD: begin
// synthesis translate_off
                    if (imm[4:0] != 5'd0)
                        $fatal(1, "VLD misaligned address 0x%05h at pc=%0d (must be 32B aligned)", imm, pc);
// synthesis translate_on
                    dmem_ld_en   <= 1'b1;
                    dmem_ld_addr <= imm[18:0];
                    vreg_waddr   <= rd;
                    state        <= S_VLD_ADDR;
                end

                OP_ACC_CLR: begin
                    acc_we  <= 1'b1;
                    acc_clr <= 1'b1;
                    pc      <= pc + 16'd1;
                    state   <= S_FETCH;
                end

                OP_VDOT: begin
// synthesis translate_off
                    if (rs1 >= NVREG || rs2 >= NVREG)
                        $fatal(1, "VDOT vreg src out of range (rs1=%0d rs2=%0d, NVREG=%0d) at pc=%0d", rs1, rs2, NVREG, pc);
// synthesis translate_on
                    lane_i <= 5'd0;
                    state  <= S_VDOT;
                end

                OP_ACC_ST: begin
// synthesis translate_off
                    if (imm[1:0] != 2'd0)
                        $fatal(1, "ACC_ST misaligned address 0x%05h at pc=%0d (must be 4B aligned)", imm, pc);
                    if (rd >= NACC)
                        $fatal(1, "ACC_ST acc %0d out of range (NACC=%0d) at pc=%0d", rd, NACC, pc);
// synthesis translate_on
                    dmem_st_en   <= 1'b1;
                    dmem_st_addr <= imm[18:0];
                    dmem_st_data <= acc_rdata;
                    pc           <= pc + 16'd1;
                    state        <= S_FETCH;
                end

                OP_HALT: begin
                    done  <= 1'b1;
                    state <= S_HALT;
                end

                default: begin
// synthesis translate_off
                    $fatal(1, "unimplemented opcode 0x%0h at pc=%0d", opcode, pc);
// synthesis translate_on
                    state <= S_HALT;
                end

                endcase
            end

            // dmem samples ld_en/ld_addr held during S_VLD_ADDR; its
            // registered ld_data is only valid from the following cycle,
            // captured here in S_VLD_CAP.
            S_VLD_ADDR: begin
                state <= S_VLD_CAP;
            end

            S_VLD_CAP: begin
                vreg_we    <= 1'b1;
                vreg_wdata <= dmem_ld_data;
                pc         <= pc + 16'd1;
                state      <= S_FETCH;
            end

            S_VDOT: begin
                acc_we    <= 1'b1;
                acc_clr   <= 1'b0;
                acc_wdata <= mac_term;
                if (lane_i == 5'd31) begin
                    pc    <= pc + 16'd1;
                    state <= S_FETCH;
                end else begin
                    lane_i <= lane_i + 5'd1;
                    state  <= S_VDOT;
                end
            end

            S_HALT: begin
                state <= S_HALT;
            end

            endcase
        end
    end
endmodule

// ===========================================================================
// verification/tb_tiny_npu.v
// ===========================================================================
// Self-checking testbench for the Tier 0 K=64 INT8 dot-product program
// (isa_spec_1.md #6). Loads A/B directly into dmem via hierarchical
// reference (host-load over AXI is Tier 2/M5 scope, not needed yet),
// computes the expected result with a behavioral signed sum, and compares
// it against what the RTL wrote to the output region after HALT.
//
// Two cases:
//   mode 0 - pseudo-random INT8 pairs
//   mode 1 - worst case (-128 * -128) x64, exercising the overflow-margin
//            claim in isa_spec_1.md #4 (64 * 127^2 << 2^31)
`timescale 1ns/1ps

module tb_tiny_npu;
    localparam ADDR_A   = 19'h00000;
    localparam ADDR_B   = 19'h10000;
    localparam ADDR_OUT = 19'h30000;
    localparam K        = 64;

    reg clk = 0;
    reg rst;
    wire done;

    tiny_npu_core #(
        .NVREG(2), .ELEMS(32), .NACC(1),
        .IMEM_WORDS(9), .DMEM_BYTES(262144),
        .IMEM_INIT("verification/prog/dot64.hex")
    ) dut (
        .clk(clk), .rst(rst), .done(done)
    );

    always #5 clk = ~clk;

    integer i;
    integer errors = 0;
    integer timeout;
    reg [31:0] seed = 32'hC0FFEE;
    reg signed [7:0]  a_byte, b_byte;
    reg signed [31:0] expected;
    reg [31:0] got;

    task load_case(input integer mode);
        begin
            expected = 32'sd0;
            for (i = 0; i < K; i = i + 1) begin
                if (mode == 0) begin
                    a_byte = $random(seed);
                    b_byte = $random(seed);
                end else begin
                    a_byte = -8'sd128;
                    b_byte = -8'sd128;
                end
                dut.dmem_i.mem[ADDR_A + i] = a_byte;
                dut.dmem_i.mem[ADDR_B + i] = b_byte;
                expected = expected + a_byte * b_byte;
            end
            // poison the output region so a silent no-op can't look like a pass
            for (i = 0; i < 4; i = i + 1)
                dut.dmem_i.mem[ADDR_OUT + i] = 8'hDE;
        end
    endtask

    task run_case(input integer mode);
        begin
            load_case(mode);

            rst = 1;
            @(posedge clk); @(posedge clk);
            rst = 0;

            timeout = 0;
            while (!done && timeout < 2000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (!done) begin
                $display("[FAIL] mode=%0d timed out waiting for HALT", mode);
                errors = errors + 1;
            end else begin
                got = {dut.dmem_i.mem[ADDR_OUT+3], dut.dmem_i.mem[ADDR_OUT+2],
                       dut.dmem_i.mem[ADDR_OUT+1], dut.dmem_i.mem[ADDR_OUT+0]};
                if ($signed(got) === expected) begin
                    $display("[PASS] mode=%0d expected=%0d got=%0d", mode, expected, $signed(got));
                end else begin
                    $display("[FAIL] mode=%0d expected=%0d got=%0d", mode, expected, $signed(got));
                    errors = errors + 1;
                end
            end
        end
    endtask

    initial begin
        $dumpfile("build/tb_tiny_npu.vcd");
        $dumpvars(0, tb_tiny_npu);

        run_case(0); // pseudo-random
        run_case(1); // overflow-margin worst case

        if (errors == 0) $display("ALL TESTS PASSED");
        else              $display("%0d TEST(S) FAILED", errors);

        $finish;
    end
endmodule

// ===========================================================================
// verification/tb_align_violation.v
// ===========================================================================
// Negative test: VLD v0, 0x00001 is not 32B-aligned. This must be caught by
// tiny_npu_core's own $fatal (isa_spec_1.md #5 alignment requirement). If
// that guard is ever removed or broken, the timeout below fires our own
// $fatal instead, so this test fails loudly either way rather than passing
// silently.
module tb_align_violation;
    reg clk = 0;
    reg rst;
    wire done;

    tiny_npu_core #(
        .NVREG(2), .ELEMS(32), .NACC(1),
        .IMEM_WORDS(2), .DMEM_BYTES(262144),
        .IMEM_INIT("verification/prog/bad_align.hex")
    ) dut (
        .clk(clk), .rst(rst), .done(done)
    );

    always #5 clk = ~clk;

    integer timeout;

    initial begin
        rst = 1;
        @(posedge clk); @(posedge clk);
        rst = 0;

        timeout = 0;
        while (!done && timeout < 200) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (done)
            $fatal(1, "REGRESSION: misaligned VLD (imm=0x00001) was not caught -- alignment check is broken");
        else
            $fatal(1, "REGRESSION: neither the alignment $fatal nor HALT fired within timeout");
    end
endmodule
