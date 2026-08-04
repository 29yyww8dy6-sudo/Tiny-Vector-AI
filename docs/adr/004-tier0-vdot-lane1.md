# ADR-004: Tier 0 VDOT을 lane=1 직렬로 구현

- Status: Accepted
- Owners: Hardware (친구)
- Related: [ADR-003](003-lane-count.md), [isa_spec_1.md](../../isa_spec_1.md)

## Context

PLANNING.md의 M2는 "제일 쉬운 명령으로 fetch/decode/regfile/메모리 경로를 먼저 뚫는다"는 원칙 아래 VLD→VADD→VST→HALT로 시작하고 VDOT·VMUL을 뒤로 미루는 계획이었다. 그런데 isa_spec_1.md v1에서 Tier 0 구현 명령(5개)이 VADD/VST 없이 VLD, ACC_CLR, **VDOT**, ACC_ST, HALT로 확정되면서, VDOT(곱셈+리덕션+누산 융합)이 우회 없이 M2의 첫 관문이 되었다.

lane count는 ADR-003에서 아직 미확정(Proposed, 4/8/16 후보)이고, docs/microarchitecture.md도 lane count를 "provisional"로 표시하고 있다. RTL 착수 전에 최소 Tier 0 bring-up에서 쓸 lane 수를 정해야 했다.

## Decision

Tier 0 VDOT은 **lane=1 직렬**로 구현한다. `acc[ad]`에 매 사이클 원소 1쌍(INT8×INT8)의 곱을 그대로 `+=` 하는 32-cycle 루프이며, 별도의 adder tree/reduction 하드웨어가 필요 없다. VLEN=256bit는 그대로 유지되므로 바이너리와 결과는 이후 lane 4/8/16 구현과 동일하다 (isa_spec_1.md "lane 은닉 조항").

이로써 M2의 원래 취지("가장 단순한 컨트롤 경로로 fetch/decode/regfile/메모리를 먼저 검증")를 VDOT을 우회하지 않고도 지킨다.

## Alternatives

### Option A: lane=1 직렬 (선택)

장점: 컨트롤 로직이 acc 레지스터 자체를 누산기로 재사용하는 단순 FSM 하나뿐. 곱셈기 1개, adder tree 없음. M2 리스크가 fetch/decode/FSM 정합성에만 집중됨.

단점: K=64 dot product에 VDOT 2회 × 32 cycle = 64 cycle 소요. 성능 측정 대상이 아님(ADR-003의 lane sweep에서 다룸).

### Option B: 초기부터 lane=8 병렬

장점: ADR-003의 provisional 값과 바로 일치, 재작업 없음.

단점: 곱셈기 8개 + adder tree를 M2 시점에 바로 검증해야 해서 fetch/decode 버그와 reduction 버그가 섞여 디버깅 난이도가 올라감. PLANNING.md M2의 "가장 쉬운 것부터" 원칙과 충돌.

## Decision Drivers

- learning value / schedule: M2는 hardware 처음 다루는 단계 — 컨트롤 경로 검증과 datapath 검증을 분리
- correctness: lane=1은 reduction tree 버그 가능성 자체를 제거

## Consequences

- 얻는 것: 최소 datapath로 M2 DoD(iverilog 시뮬 + 골든 값 일치)를 조기 통과. `rtl/tiny_npu_core.v`, `rtl/vregfile.v`, `rtl/accfile.v`, `rtl/imem.v`, `rtl/dmem.v` 및 `verification/tb_tiny_npu.v`(K=64 dot product, pseudo-random + overflow-margin worst-case)로 검증 완료.
- 잃는 것: 사이클 성능은 lane=8 대비 8배 느림 — Tier 0 bring-up 단계에서는 허용.

## Follow-up

- ADR-003의 4/8/16 lane sweep 실험 시, `tiny_npu_core`의 S_VDOT 상태를 lane 개수만큼 병렬화하고 acc 누산 경로에 adder tree를 추가. lane=1 골든 결과와 bit-exact 비교로 회귀 검증.
- synthesis 결과(Fmax/LUT/DSP)는 lane=1 기준으로 먼저 기록 후 lane 확장 시 비교.
