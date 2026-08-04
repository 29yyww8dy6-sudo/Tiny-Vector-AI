//======================================================================
// tva_accfile.v -- INT32 누산기 파일
//
// 지원 연산: clr (ACC_CLR), add (VDOT 부분합 누적), read (ACC_ST).
// clr 이 add 보다 우선한다 -- 두 신호가 같은 사이클에 뜨는 경우는
// FSM 상 없지만, 우선순위를 명시해 x 없는 회로로 만든다.
//
// 오버플로: wraparound. isa_spec_1.md §4 의 [-128,127] 클램프는
// requantize 전용이고, K=64 에서 64*127^2 = 1,032,256 << 2^31 이라
// 누산 자체는 넘치지 않는다. hw-sw-contract §2 의 TODO 를 이 값으로
// 닫되 ADR 로 기록이 필요하다.
//======================================================================
`timescale 1ns/1ps

module tva_accfile #(
    parameter NACC = 1,
    parameter W    = 32,
    // 아래는 파생 파라미터 -- 인스턴스에서 override 금지
    parameter AW   = (NACC <= 1) ? 1 : $clog2(NACC)
)(
    input  wire                clk,
    input  wire                rst_n,

    input  wire                clr,
    input  wire                add_en,
    input  wire [2:0]          waddr,
    input  wire signed [W-1:0] addend,

    input  wire [2:0]          raddr,
    output wire signed [W-1:0] rdata
);

    reg signed [W-1:0] acc [0:NACC-1];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // hw-sw-contract §6: reset 후 누산기는 0
            for (i = 0; i < NACC; i = i + 1)
                acc[i] <= {W{1'b0}};
        end else if (clr) begin
            acc[waddr[AW-1:0]] <= {W{1'b0}};
        end else if (add_en) begin
            acc[waddr[AW-1:0]] <= acc[waddr[AW-1:0]] + addend;
        end
    end

    assign rdata = acc[raddr[AW-1:0]];

    // synthesis translate_off
    always @(posedge clk)
        if ((clr || add_en) && waddr >= NACC)
            $fatal(1, "tva_accfile: acc %0d out of range (NACC=%0d)", waddr, NACC);
    // synthesis translate_on

endmodule
