# ADR-005: Tier와 Phase를 분리하고 Tier 0은 RTL-first로 진행

- Status: Accepted
- Date: 2026-08-04
- Owners: Hardware + Software
- Related: [ADR-004](004-tier0-vdot-lane1.md), [ISA spec v1](../../isa_spec_1.md), [Project Guide](../project-guide.md)

## Context

`isa_spec_1.md`는 구현 범위를 Tier 0, Tier 1.5, Tier 2로 나눈다. Tier 0은 VLD, ACC_CLR, VDOT, ACC_ST, HALT만으로 dot product를 실행하는 최소 ISA/RTL capability다.

한편 `project-guide.md`의 Phase는 assembler, simulator, compiler, RTL, differential verification, synthesis처럼 프로젝트가 남겨야 할 산출물과 검증 단계를 설명한다. 이 둘을 같은 순서로 해석하면, 작은 Tier 0 RTL을 먼저 만들어 보는 현재 작업 방식이 원래 Phase 순서를 어기는 것처럼 보인다.

현재는 하드웨어 구현을 학습하며 최소 datapath와 제어 경로를 빠르게 확인해야 한다. 동시에 RTL만 커진 뒤 software reference와의 정합성을 나중에 추적하면 ISA 의미와 수치 오류의 원인을 분리하기 어려워진다.

## Decision Drivers

- learning value: 작은 RTL을 통해 fetch/decode/FSM/메모리 경로를 먼저 이해한다.
- correctness: ISA 의미와 RTL 결과를 독립적인 reference로 비교할 수 있어야 한다.
- schedule: 초기에는 산출물 수를 줄이되, 확장 전에 검증 기반을 갖춘다.
- project value: 최종적으로는 HW/SW co-design과 재현 가능한 evidence를 남긴다.

## Alternatives

### Option A: Phase 순서대로 assembler/simulator를 완성한 뒤 RTL 착수

장점: reference model과 자동 비교 기반을 초기에 갖춘다.

단점: 하드웨어 학습과 bring-up이 늦어지고, 현재 Tier 0의 작은 제어 경로를 직접 확인하는 동력이 약해진다.

### Option B: Tier만 따라 RTL을 확장하고 simulator/phase 산출물은 나중에 추가

장점: 당장 Verilog 작성 속도는 가장 빠르다.

단점: instruction semantics, signed overflow, memory layout 버그가 누적되며, RTL이 커진 뒤에는 원인 분리가 어려워진다. 프로젝트가 RTL 구현 기록에 머물 가능성도 크다.

### Option C: Tier와 Phase를 분리하고 Tier 0은 RTL-first로 진행 (선택)

장점: 작은 RTL을 즉시 학습하면서도, 확장 전에 독립 simulator와 differential verification으로 correctness를 회수한다.

단점: Phase 순서를 단순한 직렬 체크리스트로 보지 않고, 각 산출물의 도입 시점을 관리해야 한다.

## Decision

**Tier는 ISA/RTL capability 확장 순서**, **Phase는 프로젝트 산출물과 evidence의 성숙도**로 구분한다. 둘은 1:1 대응하지 않는다.

Tier 0에서는 Verilog-first를 허용한다. 단, 다음 최소 contract를 유지한다.

- ISA spec의 instruction semantics와 memory map을 구현 기준으로 사용한다.
- handwritten `.hex` program과 testbench golden value로 최소 dot product를 검증한다.
- RTL 결과, instruction sequence, memory image를 재현 가능하게 저장한다.

Tier 1 이상으로 명령어 또는 datapath를 확장하기 전에는 Phase 1/2 산출물인 assembler와 functional simulator를 준비한다. 이후 동일 program과 input memory를 simulator와 RTL에 실행하고, instruction boundary의 architectural state와 최종 memory 결과를 bit-exact 비교한다. lane 수가 달라져도 cycle 수는 비교 대상에서 제외하고 ISA-visible 결과만 비교한다.

## Evidence

Tier 0의 `lane=1` VDOT 선택은 [ADR-004](004-tier0-vdot-lane1.md)에 기록한다. Tier 0 RTL은 VLEN=256bit, INT8 32개 원소의 dot product를 하나의 instruction sequence로 실행하며, 향후 lane 확장과 결과 호환을 전제로 한다.

## Consequences

- 얻는 것: 지금은 작은 Verilog 설계와 testbench에 집중할 수 있고, 이후 simulator를 붙여 end-to-end HW/SW project로 확장할 기준이 생긴다.
- 잃는 것: Tier 0만으로는 compiler/runtime/co-design의 가치를 증명하지 못한다. Tier 1 확장 전에 simulator와 자동 비교를 미루면 이 결정의 전제가 깨진다.

## Follow-up

- Tier 0 test program의 `.asm`/`.hex`와 input memory image를 버전 관리한다.
- Tier 1 착수 전 assembler와 functional ISA simulator의 최소 vertical slice를 추가한다.
- simulator/RTL differential test에서 `pc`, instruction, vector/accumulator write, memory write, halt/error를 instruction boundary 기준으로 비교한다.
- Phase 7에서 pseudo-random program/data와 lane 1 reference 결과를 회귀 테스트에 포함한다.
