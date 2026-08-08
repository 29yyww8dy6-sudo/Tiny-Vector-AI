// Tiny-Vector-AI Tier 0 core.
//
// Bring-up choice (ADR-004): VDOT starts at lane=1, serial.  LANES is kept
// as a microarchitecture parameter so the exact same binary can later run
// with 4/8/16 parallel INT8xINT8 MACs per cycle.
// Lane count is a microarchitecture parameter hidden from the ISA
// (isa_spec_1.md "lane 은닉 조항"): moving to lane=4/8/16 later only changes
// cycle count, never the binary or the result.
//
// v1 has no branches (isa_spec_1.md #7 Non-goals), so every program is
// straight-line and this FSM never stalls beyond fixed memory/VDOT latency.
module tiny_npu_core #(
    parameter NVREG      = 2,
    parameter ELEMS      = 32,
    parameter LANES      = 1,
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

    // VDOT consumes LANES elements at once, then adds their reduction to acc.
    // lane_base is an element index, not an ISA-visible vector length.
    reg [15:0] lane_base;
    integer lane;
    reg signed [31:0] lane_sum;
    reg signed [7:0] a_elem;
    reg signed [7:0] b_elem;
    always @* begin
        lane_sum = 32'sd0;
        for (lane = 0; lane < LANES; lane = lane + 1) begin
            a_elem = vreg_rdata1[(lane_base + lane)*8 +: 8];
            b_elem = vreg_rdata2[(lane_base + lane)*8 +: 8];
            lane_sum = lane_sum + a_elem * b_elem;
        end
    end

// synthesis translate_off
    initial begin
        if (LANES < 1 || LANES > ELEMS || (ELEMS % LANES) != 0)
            $fatal(1, "LANES=%0d must be a positive divisor of ELEMS=%0d", LANES, ELEMS);
    end
// synthesis translate_on

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
            lane_base    <= 16'd0;
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
                    lane_base <= 16'd0;
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
                acc_wdata <= lane_sum;
                if (lane_base == ELEMS - LANES) begin
                    pc    <= pc + 16'd1;
                    state <= S_FETCH;
                end else begin
                    lane_base <= lane_base + LANES;
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
