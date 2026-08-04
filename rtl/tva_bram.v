//======================================================================
// tva_bram.v -- 동기 read 단일포트 RAM (byte enable write)
//
// FPGA BRAM 추론 스타일. read latency 1 cycle.
// read-during-write bypass 없음 -- core 는 같은 사이클에 같은 주소를
// 읽고 쓰지 않는다 (FSM 이 read state 와 write state 를 분리한다).
//
// 초기화는 INIT_FILE($readmemh) 로만 한다. Vivado 도 이 형태를 BRAM
// 초기값으로 합성한다. 호스트(ARM)에서의 적재는 AXI 래퍼 몫이며
// Tier 1.5 이후 과제다.
//======================================================================
`timescale 1ns/1ps

module tva_bram #(
    parameter DW        = 256,          // data width (bit)
    parameter DEPTH     = 256,          // word 개수
    parameter INIT_FILE = "",
    // 아래는 파생 파라미터 -- 인스턴스에서 override 금지
    parameter AW        = (DEPTH <= 1) ? 1 : $clog2(DEPTH)
)(
    input  wire            clk,
    input  wire            en,
    input  wire            we,
    input  wire [DW/8-1:0] be,
    input  wire [AW-1:0]   addr,
    input  wire [DW-1:0]   wdata,
    output reg  [DW-1:0]   rdata
);

    reg [DW-1:0] mem [0:DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1) mem[i] = {DW{1'b0}};
        if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
        rdata = {DW{1'b0}};
    end

    integer b;
    always @(posedge clk) begin
        if (en) begin
            if (we) begin
                for (b = 0; b < DW/8; b = b + 1)
                    if (be[b]) mem[addr][b*8 +: 8] <= wdata[b*8 +: 8];
            end else begin
                rdata <= mem[addr];
            end
        end
    end

endmodule
