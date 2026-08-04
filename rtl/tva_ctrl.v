//======================================================================
// tva_ctrl.v -- control FSM (non-pipelined 기준선)
//
// microarchitecture.md §6 의 pipeline 실험은 이 파일만 교체하면 되도록
// datapath 와 분리해 둔다. 여기서 나가는 신호는 전부 조합이며,
// 상태 레지스터는 이 모듈에만 있다.
//
//   IDLE  → FETCH → DECODE ─┬→ (NOP/ACC_CLR)     → FETCH    2 cycle
//                           ├→ LD_REQ → LD_WAIT  → FETCH    4 cycle
//                           ├→ DOT (NPASS cycle) → FETCH    NPASS+2
//                           ├→ ST_REQ            → FETCH    3 cycle
//                           ├→ HALT              → DONE
//                           └→ 에러              → ERROR
//
// imem 이 동기 read 이므로 FETCH 는 "주소를 내놓는 사이클"이고
// DECODE 에서야 명령어가 유효하다. 그래서 명령어당 최소 2 사이클이다.
//
// hw-sw-contract §7: memory stall 이 나도 명령어를 재실행하지 않는다.
// req 는 gnt 가 올 때까지 유지되고, writeback 은 정확히 한 번 일어난다.
//======================================================================
`timescale 1ns/1ps
`include "tva_defs.vh"

module tva_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    // ---- 디코더 ----
    input  wire is_nop,
    input  wire is_vld,
    input  wire is_acc_clr,
    input  wire is_vdot,
    input  wire is_acc_st,
    input  wire is_halt,
    input  wire dec_err,

    // ---- datapath / memory 상태 ----
    input  wire dot_done,
    input  wire mem_gnt,
    input  wire mem_err,
    input  wire mem_rvalid,

    // ---- 제어 출력 ----
    output reg  imem_en,
    output reg  ir_en,          // DECODE 사이클 표시 겸 IR 래치
    output reg  pc_inc,
    output reg  pc_clr,
    output reg  mem_req,
    output reg  mem_we,
    output reg  vreg_we,
    output reg  acc_clr,
    output reg  dot_start,
    output reg  err_set,
    output reg  err_from_mem,   // 0: 디코더 에러, 1: 메모리 범위 에러

    // ---- 상태 (hw-sw-contract §5) ----
    output wire busy,
    output wire done,
    output wire error,
    output wire [3:0] state
);

    localparam S_IDLE    = 4'd0,
               S_FETCH   = 4'd1,
               S_DECODE  = 4'd2,
               S_LD_REQ  = 4'd3,
               S_LD_WAIT = 4'd4,
               S_DOT     = 4'd5,
               S_ST_REQ  = 4'd6,
               S_DONE    = 4'd7,
               S_ERR     = 4'd8;

    reg [3:0] st, ns;

    always @(posedge clk or negedge rst_n)
        if (!rst_n) st <= S_IDLE;
        else        st <= ns;

    always @(*) begin
        ns           = st;
        imem_en      = 1'b0;
        ir_en        = 1'b0;
        pc_inc       = 1'b0;
        pc_clr       = 1'b0;
        mem_req      = 1'b0;
        mem_we       = 1'b0;
        vreg_we      = 1'b0;
        acc_clr      = 1'b0;
        dot_start    = 1'b0;
        err_set      = 1'b0;
        err_from_mem = 1'b0;

        case (st)
            S_IDLE: begin
                if (start) begin
                    pc_clr = 1'b1;
                    ns     = S_FETCH;
                end
            end

            // 주소만 내놓는다. 명령어는 다음 사이클에 유효해진다.
            S_FETCH: begin
                imem_en = 1'b1;
                ns      = S_DECODE;
            end

            S_DECODE: begin
                ir_en = 1'b1;
                if (dec_err) begin
                    err_set = 1'b1;
                    ns      = S_ERR;
                end else if (is_halt) begin
                    ns = S_DONE;
                end else if (is_vld) begin
                    ns = S_LD_REQ;
                end else if (is_vdot) begin
                    dot_start = 1'b1;
                    ns        = S_DOT;
                end else if (is_acc_st) begin
                    ns = S_ST_REQ;
                end else begin
                    // NOP / ACC_CLR: 메모리도 연산도 없으므로 여기서 끝난다
                    acc_clr = is_acc_clr;
                    pc_inc  = 1'b1;
                    ns      = S_FETCH;
                end
            end

            S_LD_REQ: begin
                mem_req = 1'b1;
                if (mem_err) begin
                    err_set      = 1'b1;
                    err_from_mem = 1'b1;
                    ns           = S_ERR;
                end else if (mem_gnt) begin
                    ns = S_LD_WAIT;
                end
            end

            S_LD_WAIT: begin
                if (mem_rvalid) begin
                    vreg_we = 1'b1;
                    pc_inc  = 1'b1;
                    ns      = S_FETCH;
                end
            end

            S_DOT: begin
                // 누산은 tva_vdot 이 매 사이클 직접 때린다.
                if (dot_done) begin
                    pc_inc = 1'b1;
                    ns     = S_FETCH;
                end
            end

            S_ST_REQ: begin
                mem_req = 1'b1;
                mem_we  = 1'b1;
                if (mem_err) begin
                    err_set      = 1'b1;
                    err_from_mem = 1'b1;
                    ns           = S_ERR;
                end else if (mem_gnt) begin
                    pc_inc = 1'b1;
                    ns     = S_FETCH;
                end
            end

            // HALT 후 PC 는 멈춘 채로 유지된다. start 재어서션으로만
            // 다시 돈다 (runtime 이 같은 프로그램을 반복 실행할 때).
            S_DONE: begin
                if (start) begin
                    pc_clr = 1'b1;
                    ns     = S_FETCH;
                end
            end

            // 에러는 reset 으로만 빠져나온다. 원인을 파형에 남기기 위해
            // PC 와 err_code 를 그대로 얼린다.
            S_ERR: begin
                ns = S_ERR;
            end

            default: ns = S_ERR;
        endcase
    end

    assign state = st;
    assign done  = (st == S_DONE);
    assign error = (st == S_ERR);
    assign busy  = (st != S_IDLE) && (st != S_DONE) && (st != S_ERR);

endmodule
