//======================================================================
// tva_top.v -- core + imem + dmem
//
// 합성 대상 최상위. 바깥에 보이는 것은 실행 제어(start/busy/done/error)
// 뿐이고, 메모리 적재는 아직 INIT_FILE 로만 한다.
// 호스트(ARM)에서 BRAM 을 채우려면 AXI 래퍼가 필요하며 Tier 1.5 이후
// 과제다 -- isa_spec_1.md §7 "DDR 접근 없음, 호스트가 데이터를 적재".
//
// 파라미터 요약:
//   NVREG/NACC  구현 레지스터 수 (인코딩 상한은 8/8)
//   LANES       마이크로아키텍처 전용. 바꿔도 바이너리는 그대로다
//======================================================================
`timescale 1ns/1ps
`include "tva_defs.vh"

module tva_top #(
    parameter NVREG      = 2,
    parameter NACC       = 1,
    parameter ELEMS      = 32,          // VLEN 256bit / INT8
    parameter LANES      = 8,
    parameter IMEM_DEPTH = 1024,
    parameter ACT_LINES  = 256,
    parameter WGT_LINES  = 512,
    parameter OUT_LINES  = 64,
    parameter IMEM_INIT  = ""
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,
    output wire                  busy,
    output wire                  done,
    output wire                  error,
    output wire [`TVA_ERR_W-1:0] err_code
);

    localparam DW = ELEMS * 8;

    // ---- core <-> imem ----
    wire                  imem_en;
    wire [`TVA_PC_W-1:0]  imem_addr;
    wire [`TVA_ILEN-1:0]  imem_rdata;

    // ---- core <-> dmem ----
    wire                  dmem_req, dmem_we;
    wire [`TVA_IMM_W-1:0] dmem_addr;
    wire [ELEMS-1:0]      dmem_be;
    wire [DW-1:0]         dmem_wdata;
    wire                  dmem_gnt, dmem_err, dmem_rvalid;
    wire [DW-1:0]         dmem_rdata;

    tva_core #(
        .NVREG (NVREG),
        .NACC  (NACC),
        .ELEMS (ELEMS),
        .LANES (LANES)
    ) u_core (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .busy        (busy),
        .done        (done),
        .error       (error),
        .err_code    (err_code),
        .imem_en     (imem_en),
        .imem_addr   (imem_addr),
        .imem_rdata  (imem_rdata),
        .dmem_req    (dmem_req),
        .dmem_we     (dmem_we),
        .dmem_addr   (dmem_addr),
        .dmem_be     (dmem_be),
        .dmem_wdata  (dmem_wdata),
        .dmem_gnt    (dmem_gnt),
        .dmem_err    (dmem_err),
        .dmem_rvalid (dmem_rvalid),
        .dmem_rdata  (dmem_rdata)
    );

    tva_imem #(
        .DEPTH     (IMEM_DEPTH),
        .INIT_FILE (IMEM_INIT)
    ) u_imem (
        .clk   (clk),
        .en    (imem_en),
        .addr  (imem_addr),
        .rdata (imem_rdata)
    );

    tva_dmem #(
        .DW        (DW),
        .ACT_LINES (ACT_LINES),
        .WGT_LINES (WGT_LINES),
        .OUT_LINES (OUT_LINES)
    ) u_dmem (
        .clk    (clk),
        .rst_n  (rst_n),
        .req    (dmem_req),
        .we     (dmem_we),
        .addr   (dmem_addr),
        .be     (dmem_be),
        .wdata  (dmem_wdata),
        .gnt    (dmem_gnt),
        .err    (dmem_err),
        .rvalid (dmem_rvalid),
        .rdata  (dmem_rdata)
    );

endmodule
