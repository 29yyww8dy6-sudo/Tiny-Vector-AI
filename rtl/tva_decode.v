//======================================================================
// tva_decode.v -- 조합 디코더 + 정적 에러 검출
//
// 명령어 하나를 보고 알 수 있는 모든 에러를 여기서 잡는다.
// (메모리 범위 에러만 tva_dmem 이 판단한다 -- 주소 맵을 아는 쪽이
//  거기이기 때문.)
//
// 우선순위: ILLEGAL_OP > BAD_REG > MISALIGN.
// 미구현 opcode 는 레지스터 필드의 의미 자체가 없으므로 먼저 잡는다.
//======================================================================
`timescale 1ns/1ps
`include "tva_defs.vh"

module tva_decode #(
    parameter NVREG = 2,        // 구현된 벡터 레지스터 수 (인코딩 상한 8)
    parameter NACC  = 1         // 구현된 누산기 수     (인코딩 상한 8)
)(
    input  wire [`TVA_ILEN-1:0]  instr,

    output wire [3:0]            opcode,
    output wire [2:0]            rd,
    output wire [2:0]            rs1,
    output wire [2:0]            rs2,
    output wire [`TVA_IMM_W-1:0] imm,

    // 실행 단위로 가는 one-hot. Tier 1.5/2 명령어는 여기에 없다.
    output wire                  is_nop,
    output wire                  is_vld,
    output wire                  is_acc_clr,
    output wire                  is_vdot,
    output wire                  is_acc_st,
    output wire                  is_halt,

    output wire                  err_valid,
    output wire [`TVA_ERR_W-1:0] err_code
);

    assign opcode = instr[`TVA_F_OPCODE];
    assign rd     = instr[`TVA_F_RD];
    assign rs1    = instr[`TVA_F_RS1];
    assign rs2    = instr[`TVA_F_RS2];
    assign imm    = instr[`TVA_F_IMM];

    // NOP 은 "실행"된다: PC+1 후 다음 명령어로 간다. isa_spec_1.md §2 가
    // 0x0 을 예약한 이유가 "0으로 초기화된 메모리를 안전하게 해석"이므로
    // trap 이 아니라 무동작이 그 의도에 맞다. (ADR 후보 -- 폭주한 PC 를
    // 즉시 잡고 싶다면 ERROR 로 바꾸는 선택도 방어 가능하다.)
    assign is_nop     = (opcode == `TVA_OP_NOP);
    assign is_vld     = (opcode == `TVA_OP_VLD);
    assign is_acc_clr = (opcode == `TVA_OP_ACC_CLR);
    assign is_vdot    = (opcode == `TVA_OP_VDOT);
    assign is_acc_st  = (opcode == `TVA_OP_ACC_ST);
    assign is_halt    = (opcode == `TVA_OP_HALT);

    wire implemented = is_nop | is_vld | is_acc_clr | is_vdot | is_acc_st | is_halt;

    // ---- 레지스터 구현 범위 (§1) ------------------------------------
    // 인코딩은 8개를 지목할 수 있으나 구현이 그보다 적다는 불일치는
    // 조용히 넘기지 않는다.
    wire bad_vreg = (is_vld  && (rd  >= NVREG))
                  | (is_vdot && ((rs1 >= NVREG) || (rs2 >= NVREG)));

    wire bad_acc  = ((is_acc_clr | is_vdot | is_acc_st) && (rd >= NACC));

    // ---- 정렬 (§5) ---------------------------------------------------
    // VLD 는 32byte(= VLEN) 정렬. ACC_ST 는 스펙에 명시가 없어 4byte
    // 정렬로 확정한다 -- 미정의로 두면 simulator 와 갈린다.
    wire misalign = (is_vld    && (imm[4:0] != 5'd0))
                  | (is_acc_st && (imm[1:0] != 2'd0));

    assign err_valid = ~implemented | bad_vreg | bad_acc | misalign;

    assign err_code  = ~implemented          ? `TVA_ERR_ILLEGAL_OP :
                       (bad_vreg | bad_acc)  ? `TVA_ERR_BAD_REG    :
                       misalign              ? `TVA_ERR_MISALIGN   :
                                               `TVA_ERR_NONE;

endmodule
