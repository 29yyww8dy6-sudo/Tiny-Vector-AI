//======================================================================
// tb_tva_top.v -- self-checking testbench
//
// 외부 파일에 의존하지 않는다. 프로그램/데이터/golden 을 전부 TB 안에서
// 만든다 (.gitignore 가 *.hex 를 무시하므로 파일로 두면 저장소에서
// 사라진다).
//
// 검사 항목
//   1. isa_spec_1.md §6 예제 프로그램 -- K=64 INT8 내적
//   2. HALT 후 PC 정지
//   3. 미구현 opcode      → ILLEGAL_OP
//   4. 32byte 정렬 위반   → MISALIGN
//   5. 구현 범위 밖 vreg  → BAD_REG
//   6. 메모리 맵 밖 주소  → MEM_RANGE
//
// LANES 는 make 에서 덮어쓴다 (-Ptb_tva_top.LANES=4).
// 어떤 LANES 에서도 같은 프로그램이 같은 결과를 내야 한다 -- §1 lane
// 은닉 조항의 직접 검증이며, 달라지는 것은 cycles 출력뿐이다.
//======================================================================
`timescale 1ns/1ps
`include "tva_defs.vh"

module tb_tva_top;

    parameter LANES = 8;

    localparam ELEMS      = 32;         // VLEN 256bit / INT8
    localparam NVREG      = 2;
    localparam NACC       = 1;
    localparam IMEM_DEPTH = 1024;
    localparam K          = 64;         // 내적 길이

    // ------------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------------
    reg  clk   = 1'b0;
    reg  rst_n = 1'b0;
    reg  start = 1'b0;
    wire busy, done, error;
    wire [`TVA_ERR_W-1:0] err_code;

    always #5 clk = ~clk;               // 100MHz

    tva_top #(
        .NVREG      (NVREG),
        .NACC       (NACC),
        .ELEMS      (ELEMS),
        .LANES      (LANES),
        .IMEM_DEPTH (IMEM_DEPTH)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (start),
        .busy     (busy),
        .done     (done),
        .error    (error),
        .err_code (err_code)
    );

    integer errors = 0;
    integer cycles;

    // ------------------------------------------------------------------
    // 인코딩 (§3) -- assembler 가 생길 때까지의 임시 인코더
    // ------------------------------------------------------------------
    function [31:0] enc;
        input [3:0]  op;
        input [2:0]  rd;
        input [2:0]  rs1;
        input [2:0]  rs2;
        input [18:0] imm;
        begin
            enc = {op, rd, rs1, rs2, imm};
        end
    endfunction

    // ------------------------------------------------------------------
    // 자극 데이터와 golden
    //
    // golden 을 numpy 가 아니라 여기서 정수로 직접 계산한다. §4 의
    // 반올림 규약이 걸리는 건 requantize 뿐이고, INT32 누산까지는
    // 정수 연산이 유일한 정답이기 때문이다.
    // ------------------------------------------------------------------
    reg signed [7:0] A [0:K-1];
    reg signed [7:0] B [0:K-1];
    integer golden;

    task gen_data;
        integer i;
        begin
            golden = 0;
            for (i = 0; i < K; i = i + 1) begin
                A[i] = (i*13 + 7)   % 256 - 128;    // -128..127, 음수 포함
                B[i] = (i*29 + 131) % 256 - 128;
                golden = golden + A[i] * B[i];
            end
        end
    endtask

    // ------------------------------------------------------------------
    // 메모리 적재 (계층 접근)
    // ------------------------------------------------------------------
    task clear_imem;
        integer i;
        begin
            for (i = 0; i < IMEM_DEPTH; i = i + 1)
                dut.u_imem.u_ram.mem[i] = 32'h0;
        end
    endtask

    task load_data;
        integer i;
        reg [ELEMS*8-1:0] line;
        begin
            // 활성화: 0x00000 = 줄0(A[0:31]), 0x00020 = 줄1(A[32:63])
            for (i = 0; i < ELEMS; i = i + 1) line[i*8 +: 8] = A[i];
            dut.u_dmem.u_act.mem[0] = line;
            for (i = 0; i < ELEMS; i = i + 1) line[i*8 +: 8] = A[ELEMS+i];
            dut.u_dmem.u_act.mem[1] = line;

            // 가중치: 0x10000 = 줄0, 0x10020 = 줄1
            for (i = 0; i < ELEMS; i = i + 1) line[i*8 +: 8] = B[i];
            dut.u_dmem.u_wgt.mem[0] = line;
            for (i = 0; i < ELEMS; i = i + 1) line[i*8 +: 8] = B[ELEMS+i];
            dut.u_dmem.u_wgt.mem[1] = line;

            // 출력 영역은 0 으로 -- 안 쓰였는데 통과하는 일이 없도록
            dut.u_dmem.u_out.mem[0] = {(ELEMS*8){1'b0}};
        end
    endtask

    // ------------------------------------------------------------------
    // 실행 제어 (hw-sw-contract §5)
    // ------------------------------------------------------------------
    task reset_dut;
        begin
            start = 1'b0;
            rst_n = 1'b0;
            repeat (3) @(posedge clk);
        end
    endtask

    task run;
        input integer max_cycles;
        begin
            rst_n = 1'b1;
            @(posedge clk);
            start = 1'b1;
            @(posedge clk);             // 이 edge 에서 IDLE → FETCH
            start = 1'b0;
            cycles = 0;
            while (!done && !error && (cycles < max_cycles)) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!done && !error)
                fail("timeout");
        end
    endtask

    task fail;
        input [8*40-1:0] msg;
        begin
            errors = errors + 1;
            $display("  FAIL  %0s", msg);
        end
    endtask

    // ------------------------------------------------------------------
    // 1. §6 예제 프로그램
    // ------------------------------------------------------------------
    task test_dot64;
        reg [`TVA_PC_W-1:0] pc_at_done;
        reg [31:0] got;
        begin
            $display("[1] dot64 (isa_spec_1.md §6)");
            reset_dut;
            clear_imem;
            load_data;

            dut.u_imem.u_ram.mem[0] = enc(`TVA_OP_ACC_CLR, 3'd0, 3'd0, 3'd0, 19'h00000);
            dut.u_imem.u_ram.mem[1] = enc(`TVA_OP_VLD,     3'd0, 3'd0, 3'd0, 19'h00000);
            dut.u_imem.u_ram.mem[2] = enc(`TVA_OP_VLD,     3'd1, 3'd0, 3'd0, 19'h10000);
            dut.u_imem.u_ram.mem[3] = enc(`TVA_OP_VDOT,    3'd0, 3'd0, 3'd1, 19'h00000);
            dut.u_imem.u_ram.mem[4] = enc(`TVA_OP_VLD,     3'd0, 3'd0, 3'd0, 19'h00020);
            dut.u_imem.u_ram.mem[5] = enc(`TVA_OP_VLD,     3'd1, 3'd0, 3'd0, 19'h10020);
            dut.u_imem.u_ram.mem[6] = enc(`TVA_OP_VDOT,    3'd0, 3'd0, 3'd1, 19'h00000);
            dut.u_imem.u_ram.mem[7] = enc(`TVA_OP_ACC_ST,  3'd0, 3'd0, 3'd0, 19'h30000);
            dut.u_imem.u_ram.mem[8] = enc(`TVA_OP_HALT,    3'd0, 3'd0, 3'd0, 19'h00000);

            run(1000);

            if (error) begin
                fail("unexpected error");
                $display("        err_code=%0d", err_code);
            end else if (!done) begin
                fail("never reached HALT");
            end else begin
                got = dut.u_dmem.u_out.mem[0][31:0];
                if ($signed(got) !== golden) begin
                    fail("mem[0x30000] mismatch");
                    $display("        got=%0d expected=%0d", $signed(got), golden);
                end else begin
                    $display("  ok    mem[0x30000]=%0d, cycles=%0d (LANES=%0d)",
                             $signed(got), cycles, LANES);
                end
            end

            // 2. HALT 후 PC 정지
            pc_at_done = dut.u_core.pc;
            repeat (20) @(posedge clk);
            if (dut.u_core.pc !== pc_at_done) begin
                fail("pc moved after HALT");
                $display("        %0d -> %0d", pc_at_done, dut.u_core.pc);
            end else begin
                $display("  ok    pc frozen after HALT (pc=%0d)", pc_at_done);
            end
        end
    endtask

    // ------------------------------------------------------------------
    // 3-6. 에러 의미론 (hw-sw-contract §8)
    // ------------------------------------------------------------------
    task test_error;
        input [8*32-1:0] name;
        input [31:0]     instr;
        input [`TVA_ERR_W-1:0] exp_code;
        begin
            reset_dut;
            clear_imem;
            dut.u_imem.u_ram.mem[0] = instr;
            dut.u_imem.u_ram.mem[1] = enc(`TVA_OP_HALT, 3'd0, 3'd0, 3'd0, 19'h00000);

            run(200);

            if (!error) begin
                fail("no error raised");
                $display("        %0s (done=%0b)", name, done);
            end else if (err_code !== exp_code) begin
                fail("wrong err_code");
                $display("        %0s got=%0d expected=%0d", name, err_code, exp_code);
            end else begin
                $display("  ok    %0s -> err_code=%0d", name, err_code);
            end
        end
    endtask

    // ------------------------------------------------------------------
    initial begin
`ifdef DUMP_VCD
        $dumpfile("verification/waveforms/tb_tva_top.vcd");
        $dumpvars(0, tb_tva_top);
`endif
        $display("=== tb_tva_top  LANES=%0d  VLEN=%0d bit ===", LANES, ELEMS*8);
        gen_data;

        test_dot64;

        $display("[2] error semantics");
        // VRELU: 인코딩은 예약됐지만 미구현 (§2)
        test_error("illegal opcode (VRELU)",
                   enc(`TVA_OP_VRELU, 3'd0, 3'd0, 3'd0, 19'h00000),
                   `TVA_ERR_ILLEGAL_OP);
        // 32byte 정렬 위반 (§5)
        test_error("misaligned VLD",
                   enc(`TVA_OP_VLD, 3'd0, 3'd0, 3'd0, 19'h00010),
                   `TVA_ERR_MISALIGN);
        // v2 는 인코딩 가능하지만 NVREG=2 라 구현되지 않았다 (§1)
        test_error("vreg out of impl range",
                   enc(`TVA_OP_VDOT, 3'd0, 3'd2, 3'd0, 19'h00000),
                   `TVA_ERR_BAD_REG);
        // 0x40000 은 메모리 맵 밖 (§5)
        test_error("address outside memory map",
                   enc(`TVA_OP_VLD, 3'd0, 3'd0, 3'd0, 19'h40000),
                   `TVA_ERR_MEM_RANGE);

        if (errors == 0)
            $display("=== PASS ===");
        else
            $display("=== FAIL: %0d check(s) ===", errors);

        $finish;
    end

endmodule
