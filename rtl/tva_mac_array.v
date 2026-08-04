//======================================================================
// tva_mac_array.v -- LANES개 INT8 곱셈기 + balanced adder tree
//
// 순수 조합 회로. lane 수는 이 모듈의 파라미터 하나로만 표현되며
// ISA 에는 노출되지 않는다 (isa_spec_1.md §1 lane 은닉 조항).
// ADR-003 의 lane sweep 과 microarchitecture §6 의 pipeline 실험은
// 둘 다 이 파일만 건드리면 된다.
//
// 폭: INT8 x INT8 = 16bit, LANES개 합에 log2(LANES) bit 여유.
//     TW = 16 + log2(LANES) 면 어떤 입력에도 넘치지 않는다.
//     LANES=32 에서도 21bit 이므로 32bit 출력은 sign extension 뿐이다.
//======================================================================
`timescale 1ns/1ps

module tva_mac_array #(
    parameter LANES  = 8,
    // 아래는 파생 파라미터 -- 인스턴스에서 override 금지
    parameter STAGES = (LANES <= 1) ? 0 : $clog2(LANES),
    parameter TW     = 16 + STAGES
)(
    input  wire [LANES*8-1:0] a,
    input  wire [LANES*8-1:0] b,
    output wire signed [31:0] sum
);

    // heap 배치: node[0] = root, leaf = node[LANES-1 .. 2*LANES-2]
    // 트리를 명시적으로 만드는 이유는 합성 도구의 재구성에 기대지 않고
    // critical path 단수를 파형/타이밍 리포트에서 바로 세기 위해서다.
    wire signed [TW-1:0] node [0:2*LANES-2];

    genvar i;
    generate
        for (i = 0; i < LANES; i = i + 1) begin : g_mul
            wire signed [7:0] ai = a[i*8 +: 8];
            wire signed [7:0] bi = b[i*8 +: 8];
            assign node[LANES-1+i] = ai * bi;   // signed*signed -> TW 로 sign extend
        end

        for (i = 0; i < LANES-1; i = i + 1) begin : g_add
            assign node[i] = node[2*i+1] + node[2*i+2];
        end
    endgenerate

    assign sum = node[0];

    // synthesis translate_off
    initial begin
        if (LANES < 1 || (LANES & (LANES-1)) != 0)
            $fatal(1, "tva_mac_array: LANES(%0d) must be a power of two", LANES);
    end
    // synthesis translate_on

endmodule
