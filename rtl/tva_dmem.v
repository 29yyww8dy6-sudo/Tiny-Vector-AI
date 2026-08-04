//======================================================================
// tva_dmem.v -- 데이터 메모리 (region 디코드 + BRAM 3개)
//
// isa_spec_1.md §5 의 주소 맵을 아는 유일한 모듈이다. core 는 19bit
// 평면 주소만 내보내고, 뱅킹/분할은 여기 숨는다 -- "뱅킹 구조는 ISA 에
// 노출하지 않는다" 조항의 구현 위치.
//
//   0x00000-0x0FFFF  입력 활성화   region 0
//   0x10000-0x2FFFF  가중치        region 1,2
//   0x30000-0x3FFFF  출력          region 3
//
// 주소 디코드는 스펙 그대로 하되 실제 깊이는 파라미터로 줄인다.
// 스펙의 맵 전체(256KB)를 그대로 깔면 XC7Z010 의 BRAM 총량(약 270KB)을
// 거의 다 먹는다. 맵 안이지만 구현 깊이를 넘는 접근은 MEM_RANGE 로
// 잡아, 시뮬레이터에서만 돌던 프로그램이 FPGA 에서 조용히 틀리는 일을
// 막는다.
//
// 폭은 VLEN(256bit) 고정. ACC_ST 의 4byte 쓰기는 byte enable 로 한다.
// read latency 1 cycle, 항상 gnt (BRAM 은 backpressure 가 없다).
//======================================================================
`timescale 1ns/1ps
`include "tva_defs.vh"

module tva_dmem #(
    parameter DW        = 256,      // = VLEN
    parameter ACT_LINES = 256,      // 8KB   (스펙 맵 상한 2048줄 = 64KB)
    parameter WGT_LINES = 512,      // 16KB  (상한 4096줄 = 128KB)
    parameter OUT_LINES = 64        // 2KB   (상한 2048줄 = 64KB)
)(
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  req,
    input  wire                  we,
    input  wire [`TVA_IMM_W-1:0] addr,      // byte 주소
    input  wire [DW/8-1:0]       be,
    input  wire [DW-1:0]         wdata,

    output wire                  gnt,
    output wire                  err,       // 맵 밖 / 구현 깊이 초과
    output wire                  rvalid,
    output wire [DW-1:0]         rdata
);

    localparam ACT_AW = (ACT_LINES <= 1) ? 1 : $clog2(ACT_LINES);
    localparam WGT_AW = (WGT_LINES <= 1) ? 1 : $clog2(WGT_LINES);
    localparam OUT_AW = (OUT_LINES <= 1) ? 1 : $clog2(OUT_LINES);

    // ---- region 디코드 -------------------------------------------------
    wire [2:0]  region  = addr[`TVA_F_REGION];
    wire [10:0] line_lo = addr[15:5];       // 줄 = 32byte

    wire sel_act = (region == `TVA_REGION_ACT);
    wire sel_wgt = (region == `TVA_REGION_WGT_LO) || (region == `TVA_REGION_WGT_HI);
    wire sel_out = (region == `TVA_REGION_OUT);

    // 가중치만 두 region 에 걸쳐 있어 12bit 줄 번호를 쓴다.
    // region 1(0x1xxxx) → 줄 0-2047, region 2(0x2xxxx) → 줄 2048-4095.
    wire [11:0] act_line = {1'b0,      line_lo};
    wire [11:0] wgt_line = {region[1], line_lo};
    wire [11:0] out_line = {1'b0,      line_lo};

    wire in_range = (sel_act && (act_line < ACT_LINES))
                  || (sel_wgt && (wgt_line < WGT_LINES))
                  || (sel_out && (out_line < OUT_LINES));

    assign err = req && !in_range;
    assign gnt = req && in_range;

    wire en_act = req && sel_act && in_range;
    wire en_wgt = req && sel_wgt && in_range;
    wire en_out = req && sel_out && in_range;

    // ---- 저장소 --------------------------------------------------------
    wire [DW-1:0] act_rdata, wgt_rdata, out_rdata;

    tva_bram #(.DW(DW), .DEPTH(ACT_LINES)) u_act (
        .clk(clk), .en(en_act), .we(we), .be(be),
        .addr(act_line[ACT_AW-1:0]), .wdata(wdata), .rdata(act_rdata)
    );

    tva_bram #(.DW(DW), .DEPTH(WGT_LINES)) u_wgt (
        .clk(clk), .en(en_wgt), .we(we), .be(be),
        .addr(wgt_line[WGT_AW-1:0]), .wdata(wdata), .rdata(wgt_rdata)
    );

    tva_bram #(.DW(DW), .DEPTH(OUT_LINES)) u_out (
        .clk(clk), .en(en_out), .we(we), .be(be),
        .addr(out_line[OUT_AW-1:0]), .wdata(wdata), .rdata(out_rdata)
    );

    // ---- read 응답 -----------------------------------------------------
    // BRAM 출력과 같은 사이클에 맞추기 위해 선택 신호도 한 단 늦춘다.
    reg       rvalid_r;
    reg [1:0] sel_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rvalid_r <= 1'b0;
            sel_q    <= 2'd0;
        end else begin
            rvalid_r <= req && !we && in_range;
            sel_q    <= sel_act ? 2'd0 : sel_wgt ? 2'd1 : 2'd2;
        end
    end

    assign rvalid = rvalid_r;
    assign rdata  = (sel_q == 2'd0) ? act_rdata :
                    (sel_q == 2'd1) ? wgt_rdata :
                                      out_rdata;

endmodule
