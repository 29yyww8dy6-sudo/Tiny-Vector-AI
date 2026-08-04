//======================================================================
// tva_vregfile.v -- 벡터 레지스터 파일
//
// isa_spec_1.md §1: 인코딩 상한은 8개지만 구현은 그보다 적을 수 있다.
// Tier 0 은 v0/v1 만 쓰므로 NREG=2 로 합성한다. 안 쓰는 레지스터는
// LUT 와 write-enable 디코딩만 늘리고 파형을 어지럽힌다.
//
// read 는 조합(레지스터 mux), write 는 동기.
// reset 없음: 첫 VLD 전에 읽으면 시뮬레이션에서 x 가 전파된다.
// 이건 의도다 -- read-before-write 를 x 로 잡는 편이 0 으로 덮어
// 조용히 통과하는 것보다 낫다. (hw-sw-contract §6 의 열린 항목)
//======================================================================
`timescale 1ns/1ps

module tva_vregfile #(
    parameter NREG  = 2,
    parameter ELEMS = 32,               // VLEN=256bit / INT8
    // 아래는 파생 파라미터 -- 인스턴스에서 override 금지
    parameter AW    = (NREG <= 1) ? 1 : $clog2(NREG)
)(
    input  wire                clk,

    input  wire                we,
    input  wire [2:0]          waddr,
    input  wire [ELEMS*8-1:0]  wdata,

    input  wire [2:0]          raddr1,
    output wire [ELEMS*8-1:0]  rdata1,
    input  wire [2:0]          raddr2,
    output wire [ELEMS*8-1:0]  rdata2
);

    reg [ELEMS*8-1:0] regs [0:NREG-1];

    always @(posedge clk)
        if (we) regs[waddr[AW-1:0]] <= wdata;

    // 범위 밖 인덱스는 디코더가 이미 BAD_REG 로 잡는다. 여기서는
    // 주소를 잘라 합성 도구가 존재하지 않는 엔트리를 만들지 않게 한다.
    assign rdata1 = regs[raddr1[AW-1:0]];
    assign rdata2 = regs[raddr2[AW-1:0]];

    // synthesis translate_off
    always @(posedge clk)
        if (we && waddr >= NREG)
            $fatal(1, "tva_vregfile: vreg %0d out of range (NREG=%0d)", waddr, NREG);
    // synthesis translate_on

endmodule
