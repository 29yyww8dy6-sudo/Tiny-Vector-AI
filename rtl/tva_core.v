//======================================================================
// tva_core.v -- PC / IR 와 서브모듈 결선
//
// 메모리를 갖지 않는다. imem/dmem 인터페이스만 내보내므로 BRAM 이든
// AXI 래퍼든 바깥에서 붙일 수 있다.
//
// 파라미터는 전부 isa_spec_1.md §1 의 "인코딩 상한 != 구현 개수" 를
// 표현하기 위한 것이다. Tier 0 은 NVREG=2 / NACC=1 로 합성한다.
//======================================================================
`timescale 1ns/1ps
`include "tva_defs.vh"

module tva_core #(
    parameter NVREG = 2,        // Tier 0: 2 → Tier 1: 8
    parameter NACC  = 1,
    parameter ELEMS = 32,       // VLEN 256bit / INT8
    parameter LANES = 8         // 마이크로아키텍처 파라미터. ISA 에 안 보인다
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // ---- 실행 제어 (hw-sw-contract §5) ----
    input  wire                  start,
    output wire                  busy,
    output wire                  done,
    output wire                  error,
    output wire [`TVA_ERR_W-1:0] err_code,

    // ---- instruction memory: 동기 read, latency 1 ----
    output wire                  imem_en,
    output wire [`TVA_PC_W-1:0]  imem_addr,
    input  wire [`TVA_ILEN-1:0]  imem_rdata,

    // ---- data memory: req/gnt + rvalid, 폭 = VLEN ----
    output wire                  dmem_req,
    output wire                  dmem_we,
    output wire [`TVA_IMM_W-1:0] dmem_addr,
    output wire [ELEMS-1:0]      dmem_be,
    output wire [ELEMS*8-1:0]    dmem_wdata,
    input  wire                  dmem_gnt,
    input  wire                  dmem_err,
    input  wire                  dmem_rvalid,
    input  wire [ELEMS*8-1:0]    dmem_rdata
);

    // ------------------------------------------------------------------
    // 제어 신호 (tva_ctrl 출력)
    // ------------------------------------------------------------------
    wire imem_en_w, ir_en, pc_inc, pc_clr;
    wire mem_req, mem_we, vreg_we, acc_clr, dot_start;
    wire err_set, err_from_mem;
    wire [3:0] ctrl_state;

    // ------------------------------------------------------------------
    // PC / IR
    // ------------------------------------------------------------------
    reg [`TVA_PC_W-1:0] pc;
    reg [`TVA_ILEN-1:0] ir;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)      pc <= {`TVA_PC_W{1'b0}};   // contract §6: reset 후 PC=0
        else if (pc_clr) pc <= {`TVA_PC_W{1'b0}};
        else if (pc_inc) pc <= pc + 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)     ir <= {`TVA_ILEN{1'b0}};
        else if (ir_en) ir <= imem_rdata;
    end

    // imem 이 동기 read 라 DECODE 사이클에만 imem_rdata 가 유효하고,
    // 그 뒤 EXEC state 들은 IR 을 본다. 메모리가 출력을 유지해 준다는
    // 가정에 기대지 않기 위해 명시적으로 mux 한다 (ir_en == DECODE).
    wire [`TVA_ILEN-1:0] dec_instr = ir_en ? imem_rdata : ir;

    assign imem_en   = imem_en_w;
    assign imem_addr = pc;

    // ------------------------------------------------------------------
    // Decode
    // ------------------------------------------------------------------
    wire [3:0]            dec_opcode;
    wire [2:0]            dec_rd, dec_rs1, dec_rs2;
    wire [`TVA_IMM_W-1:0] dec_imm;
    wire                  is_nop, is_vld, is_acc_clr, is_vdot, is_acc_st, is_halt;
    wire                  dec_err;
    wire [`TVA_ERR_W-1:0] dec_err_code;

    tva_decode #(
        .NVREG (NVREG),
        .NACC  (NACC)
    ) u_decode (
        .instr      (dec_instr),
        .opcode     (dec_opcode),
        .rd         (dec_rd),
        .rs1        (dec_rs1),
        .rs2        (dec_rs2),
        .imm        (dec_imm),
        .is_nop     (is_nop),
        .is_vld     (is_vld),
        .is_acc_clr (is_acc_clr),
        .is_vdot    (is_vdot),
        .is_acc_st  (is_acc_st),
        .is_halt    (is_halt),
        .err_valid  (dec_err),
        .err_code   (dec_err_code)
    );

    // ------------------------------------------------------------------
    // Control
    // ------------------------------------------------------------------
    wire dot_done;

    tva_ctrl u_ctrl (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .is_nop       (is_nop),
        .is_vld       (is_vld),
        .is_acc_clr   (is_acc_clr),
        .is_vdot      (is_vdot),
        .is_acc_st    (is_acc_st),
        .is_halt      (is_halt),
        .dec_err      (dec_err),
        .dot_done     (dot_done),
        .mem_gnt      (dmem_gnt),
        .mem_err      (dmem_err),
        .mem_rvalid   (dmem_rvalid),
        .imem_en      (imem_en_w),
        .ir_en        (ir_en),
        .pc_inc       (pc_inc),
        .pc_clr       (pc_clr),
        .mem_req      (mem_req),
        .mem_we       (mem_we),
        .vreg_we      (vreg_we),
        .acc_clr      (acc_clr),
        .dot_start    (dot_start),
        .err_set      (err_set),
        .err_from_mem (err_from_mem),
        .busy         (busy),
        .done         (done),
        .error        (error),
        .state        (ctrl_state)
    );

    // ------------------------------------------------------------------
    // 레지스터 파일
    // ------------------------------------------------------------------
    wire [ELEMS*8-1:0] vs1_data, vs2_data;

    tva_vregfile #(
        .NREG  (NVREG),
        .ELEMS (ELEMS)
    ) u_vregfile (
        .clk    (clk),
        .we     (vreg_we),
        .waddr  (dec_rd),
        .wdata  (dmem_rdata),
        .raddr1 (dec_rs1),
        .rdata1 (vs1_data),
        .raddr2 (dec_rs2),
        .rdata2 (vs2_data)
    );

    wire               acc_add_en;
    wire signed [31:0] acc_add_data;
    wire signed [31:0] acc_rdata;

    tva_accfile #(
        .NACC (NACC),
        .W    (32)
    ) u_accfile (
        .clk    (clk),
        .rst_n  (rst_n),
        .clr    (acc_clr),
        .add_en (acc_add_en),
        .waddr  (dec_rd),
        .addend (acc_add_data),
        .raddr  (dec_rd),
        .rdata  (acc_rdata)
    );

    // ------------------------------------------------------------------
    // VDOT
    // ------------------------------------------------------------------
    tva_vdot #(
        .ELEMS (ELEMS),
        .LANES (LANES)
    ) u_vdot (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (dot_start),
        .va           (vs1_data),
        .vb           (vs2_data),
        .busy         (),
        .acc_add_en   (acc_add_en),
        .acc_add_data (acc_add_data),
        .done         (dot_done)
    );

    // ------------------------------------------------------------------
    // 데이터 메모리 요청
    //
    // VLD    : 256bit 한 줄 read. 주소는 32byte 정렬 (디코더가 검사)
    // ACC_ST : 같은 줄 안의 4byte partial write. 어느 4byte 인지는
    //          imm[4:2] 가 정하고 byte enable 로 표현한다. wdata 는
    //          32bit acc 를 줄 전체에 복제해 두면 be 가 알아서 고른다.
    // ------------------------------------------------------------------
    wire [4:0] be_shift = {dec_imm[4:2], 2'b00};

    assign dmem_req   = mem_req;
    assign dmem_we    = mem_we;
    assign dmem_addr  = dec_imm;
    assign dmem_be    = mem_we ? ({{(ELEMS-4){1'b0}}, 4'hF} << be_shift)
                               : {ELEMS{1'b0}};
    assign dmem_wdata = {(ELEMS*8/32){acc_rdata}};

    // ------------------------------------------------------------------
    // 에러 래치 (hw-sw-contract §8)
    // ------------------------------------------------------------------
    reg [`TVA_ERR_W-1:0] err_code_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)          err_code_r <= `TVA_ERR_NONE;
        else if (err_set)    err_code_r <= err_from_mem ? `TVA_ERR_MEM_RANGE
                                                        : dec_err_code;
    end

    assign err_code = err_code_r;

    // ------------------------------------------------------------------
    // Trace (hw-sw-contract §9)
    // simulator 와 파형 없이 대조하기 위한 최소 출력.
    // iverilog: +define+TVA_TRACE
    // ------------------------------------------------------------------
    // synthesis translate_off
`ifdef TVA_TRACE
    always @(posedge clk) begin
        if (rst_n && ir_en)
            $display("[TVA] %0t pc=%0d instr=%08h op=%h rd=%0d rs1=%0d rs2=%0d imm=%05h",
                     $time, pc, dec_instr, dec_opcode, dec_rd, dec_rs1, dec_rs2, dec_imm);
        if (rst_n && vreg_we)
            $display("[TVA]        v%0d <= %064h", dec_rd, dmem_rdata);
        if (rst_n && acc_add_en)
            $display("[TVA]        acc%0d += %0d", dec_rd, acc_add_data);
        if (rst_n && mem_req && mem_we && dmem_gnt)
            $display("[TVA]        mem[%05h] <= %0d (be=%08h)", dec_imm, acc_rdata, dmem_be);
    end
`endif
    // synthesis translate_on

endmodule
