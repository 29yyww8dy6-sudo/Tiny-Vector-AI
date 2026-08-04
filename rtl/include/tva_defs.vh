//======================================================================
// tva_defs.vh -- Tiny-Vector-AI ISA v1 정의
//
// isa_spec_1.md §2/§3/§5 의 기계어 표현. 최종적으로는 isa.yaml 에서
// 생성되어야 하는 파일이며(§9), 그전까지는 손으로 유지한다.
// 이 파일을 고치면 assembler / simulator 도 같은 커밋에서 고친다.
//
// 규칙: opcode 와 필드 위치는 이 파일에만 존재한다. 다른 RTL 파일에
//       4'h4 같은 리터럴이 나타나면 그건 버그다.
//======================================================================
`ifndef TVA_DEFS_VH
`define TVA_DEFS_VH

// ---- 명령어 형식 (§3) ------------------------------------------------
`define TVA_ILEN        32
`define TVA_PC_W        16      // §1: 명령어 65536개
`define TVA_IMM_W       19
`define TVA_REGIDX_W    3       // 인코딩 상한 8개 (구현 개수와 별개)

// 필드 슬라이스. 사용법: instr[`TVA_F_OPCODE]
//  31    28 27  25 24  22 21  19 18                    0
// | opcode |  rd  | rs1  | rs2  |         imm          |
`define TVA_F_OPCODE    31:28
`define TVA_F_RD        27:25
`define TVA_F_RS1       24:22
`define TVA_F_RS2       21:19
`define TVA_F_IMM       18:0

// ---- opcode (§2) -----------------------------------------------------
`define TVA_OP_NOP        4'h0   // 0으로 초기화된 메모리가 안전하게 해석되도록 예약
`define TVA_OP_VLD        4'h1
`define TVA_OP_VST        4'h2   // 미구현 (Tier 1.5)
`define TVA_OP_ACC_CLR    4'h3
`define TVA_OP_VDOT       4'h4
`define TVA_OP_ACC_ST     4'h5
`define TVA_OP_HALT       4'h6
`define TVA_OP_VRELU      4'h7   // 미구현 (Tier 1.5)
`define TVA_OP_VREQUANT   4'h8   // 미구현 (Tier 1.5)
`define TVA_OP_ADDI       4'h9   // 미구현 (Tier 2)
`define TVA_OP_BNE        4'hA   // 미구현 (Tier 2)
`define TVA_OP_VDOT_FUSED 4'hB   // 미구현 (Tier 2)
                                 // 4'hC - 4'hF 미할당

// ---- 메모리 맵 (§5) --------------------------------------------------
// byte 주소. region 은 addr[18:16] 하나로 갈린다.
//   0x00000-0x0FFFF  입력 활성화   region 0
//   0x10000-0x2FFFF  가중치        region 1,2
//   0x30000-0x3FFFF  출력          region 3
`define TVA_F_REGION      18:16
`define TVA_REGION_ACT    3'd0
`define TVA_REGION_WGT_LO 3'd1
`define TVA_REGION_WGT_HI 3'd2
`define TVA_REGION_OUT    3'd3

// ---- error code (hw-sw-contract §8) ----------------------------------
// simulator 와 반드시 같은 값을 쓴다. 값이 다르면 두 backend 의 에러
// 비교가 무의미해진다.
`define TVA_ERR_W          3
`define TVA_ERR_NONE       3'd0
`define TVA_ERR_ILLEGAL_OP 3'd1   // 미구현 / 미할당 opcode
`define TVA_ERR_BAD_REG    3'd2   // 인코딩은 되지만 구현 범위 밖인 레지스터
`define TVA_ERR_MISALIGN   3'd3   // VLD 32B / ACC_ST 4B 정렬 위반
`define TVA_ERR_MEM_RANGE  3'd4   // 메모리 맵 밖 또는 미구현 용량 초과 접근

`endif // TVA_DEFS_VH
