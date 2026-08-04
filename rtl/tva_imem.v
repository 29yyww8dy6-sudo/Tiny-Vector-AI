//======================================================================
// tva_imem.v -- 명령어 메모리
//
// 32bit x DEPTH, 동기 read. write 포트 없음 -- 프로그램 적재는
// INIT_FILE 또는 시뮬레이션 계층 접근(u_ram.mem)으로 한다.
// 자기수정 코드는 ISA 에 없으므로 core 에서 쓸 일이 없다.
//
// PC 는 16bit(65536 명령어)까지 인코딩되지만 구현 DEPTH 는 그보다
// 작다. 벡터 레지스터와 같은 "인코딩 상한 != 구현" 관계다.
//======================================================================
`timescale 1ns/1ps
`include "tva_defs.vh"

module tva_imem #(
    parameter DEPTH     = 1024,
    parameter INIT_FILE = "",
    // 아래는 파생 파라미터 -- 인스턴스에서 override 금지
    parameter AW        = (DEPTH <= 1) ? 1 : $clog2(DEPTH)
)(
    input  wire                 clk,
    input  wire                 en,
    input  wire [`TVA_PC_W-1:0] addr,
    output wire [`TVA_ILEN-1:0] rdata
);

    tva_bram #(
        .DW        (`TVA_ILEN),
        .DEPTH     (DEPTH),
        .INIT_FILE (INIT_FILE)
    ) u_ram (
        .clk   (clk),
        .en    (en),
        .we    (1'b0),
        .be    (4'h0),
        .addr  (addr[AW-1:0]),
        .wdata ({`TVA_ILEN{1'b0}}),
        .rdata (rdata)
    );

    // synthesis translate_off
    always @(posedge clk)
        if (en && (addr >= DEPTH))
            $fatal(1, "tva_imem: fetch pc=%0d beyond DEPTH=%0d", addr, DEPTH);
    // synthesis translate_on

endmodule
