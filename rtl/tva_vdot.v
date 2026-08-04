//======================================================================
// tva_vdot.v -- VDOT chunk 시퀀서
//
// VLEN 전체(ELEMS개)를 LANES개씩 NPASS = ELEMS/LANES 번에 나눠 처리하고
// 매 사이클 부분합을 누산기에 더한다. 이것이 isa_spec_1.md §1 lane
// 은닉 조항의 구현체다:
//
//   - 같은 바이너리가 LANES 4/8/16/32 에서 같은 결과를 낸다
//   - 달라지는 것은 NPASS, 즉 소요 사이클뿐이다
//
// vs1/vs2 는 읽기만 한다 (§2). 따라서 입력 벡터 하나를 여러 가중치와
// 반복 내적할 수 있고, 시퀀싱 중에 레지스터가 바뀔 걱정도 없다.
//
// 타이밍:  start 어서션 다음 사이클부터 NPASS 사이클간 busy.
//          acc_add_en 은 busy 인 사이클마다 1.
//          done 은 마지막 add 와 같은 사이클에 뜬다.
//======================================================================
`timescale 1ns/1ps

module tva_vdot #(
    parameter ELEMS = 32,
    parameter LANES = 8,
    // 아래는 파생 파라미터 -- 인스턴스에서 override 금지
    parameter NPASS = ELEMS / LANES,
    parameter CW    = (NPASS <= 1) ? 1 : $clog2(NPASS)
)(
    input  wire                clk,
    input  wire                rst_n,

    input  wire                start,
    input  wire [ELEMS*8-1:0]  va,
    input  wire [ELEMS*8-1:0]  vb,

    output wire                busy,
    output wire                acc_add_en,
    output wire signed [31:0]  acc_add_data,
    output wire                done
);

    reg [CW-1:0] cnt;
    reg          busy_r;

    wire last = (cnt == NPASS-1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_r <= 1'b0;
            cnt    <= {CW{1'b0}};
        end else if (!busy_r) begin
            if (start) begin
                busy_r <= 1'b1;
                cnt    <= {CW{1'b0}};
            end
        end else begin
            cnt <= cnt + 1'b1;
            if (last) busy_r <= 1'b0;
        end
    end

    // 현재 chunk 의 비트 오프셋. 32bit 로 명시해 곱셈이 잘리지 않게 한다.
    wire [31:0] base = cnt * (LANES * 8);

    tva_mac_array #(
        .LANES (LANES)
    ) u_mac (
        .a   (va[base +: LANES*8]),
        .b   (vb[base +: LANES*8]),
        .sum (acc_add_data)
    );

    assign busy       = busy_r;
    assign acc_add_en = busy_r;
    assign done       = busy_r & last;

    // synthesis translate_off
    initial begin
        if (NPASS * LANES != ELEMS)
            $fatal(1, "tva_vdot: LANES(%0d) must divide ELEMS(%0d)", LANES, ELEMS);
    end
    // synthesis translate_on

endmodule
