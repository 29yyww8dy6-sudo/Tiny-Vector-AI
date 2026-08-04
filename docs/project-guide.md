# Tiny NPU Project Guide

## 0. 문서의 목적

이 문서는 프로젝트의 실행 순서와 학습 방식을 관리하는 중심 문서다. 세부 설계는 별도 문서에서 관리하고, 여기서는 현재 phase, 핵심 질문, 종료 조건을 추적한다.

## 1. 핵심 목표

### Software 담당자

- tensor graph가 custom ISA로 내려가는 과정을 이해한다.
- IR, lowering, assembler, runtime, simulator의 책임을 구분한다.
- hardware capability를 compiler가 사용할 수 있는 형태로 표현한다.
- 여러 lowering 후보를 비교하고 자동 선택의 기초를 만든다.

### Hardware 담당자

- workload 요구사항을 microarchitecture로 바꾼다.
- synthesizable RTL과 체계적인 verification 환경을 만든다.
- pipeline, lane 수, register file, memory bandwidth의 trade-off를 측정한다.
- synthesis와 timing 결과를 통해 구조 선택을 설명한다.

### 공동 목표

- ISA와 numerical semantics를 함께 정의한다.
- simulator와 RTL을 differential test한다.
- 최소 두 개의 HW/SW co-design 실험을 수행한다.
- 각자의 결정과 결과를 수치와 문서로 남긴다.

## 2. 추천 진행 순서

```text
Phase 0  Scope / Workload / Contract
Phase 1  Handwritten Assembly Vertical Slice
Phase 2  Assembler + Functional Simulator
Phase 3  Tiny Graph IR + Lowering
Phase 4  Minimal Runtime
Phase 5  Microarchitecture Specification
Phase 6  Synthesizable RTL
Phase 7  Differential Verification
Phase 8  Synthesis / Timing / Resource
Phase 9  Co-design Experiments
Phase 10 Final Demo / Report / Interview Notes
```

software와 hardware는 완전히 직렬로 진행하지 않는다.

```text
ISA 초안
├─ SW: assembler / simulator
└─ HW: microarchitecture sketch

functional contract 안정화
├─ SW: compiler / runtime
└─ HW: RTL / verification

integration
└─ same executable / same input / same expected output
```

## 3. Phase별 학습 루프

모든 phase에서 아래 순서를 반복한다.

```text
Question
→ Current Model
→ Prediction
→ Minimal Implementation
→ Measurement
→ Mismatch Analysis
→ Design Change
→ Evidence
```

## 4. 현재 기본 가정

아래 값은 시작점이며 실험을 통해 변경할 수 있다.

- Workload: INT8 Dot Product
- Optional workload: INT8 Matrix–Vector
- Input dtype: signed INT8
- Accumulator: signed INT32
- Shape: static
- SIMD lane: 8-lane provisional
- Memory: simple flat memory model
- Backend: Python functional simulator + synthesizable RTL
- RTL target: simulator/synthesis 우선, FPGA는 선택
- Dynamic shape, cache, multicore, PCIe는 초기 범위에서 제외

중요한 변경은 [ADR](adr/000-template.md)로 남긴다.

## 5. 핵심 공동 실험

최소 두 개를 완료한다.

1. SIMD lane 4/8/16 비교
2. 일반 MAC 반복 vs fused DOT instruction
3. pipeline depth 비교
4. accumulator width 비교
5. row-major vs tiled layout
6. lowering A/B 비교
7. memory bandwidth 제한 변화

## 6. 주간 운영

매주 다음을 갱신한다.

- 이번 주 질문
- 각자의 구현 결과
- contract 변경 여부
- 새로 발견한 bug
- 측정 결과
- 예측과 달랐던 부분
- 다음 주 integration 목표

템플릿: [Weekly Review](reviews/000-weekly-review-template.md)

## 7. 최종 데모

```text
1. 사용자가 작은 Dot/MatVec graph를 생성한다.
2. compiler가 assembly를 생성한다.
3. assembler가 executable을 만든다.
4. 같은 executable 또는 동일 semantics의 program을
   simulator와 RTL에 실행한다.
5. 두 backend 결과를 NumPy golden model과 비교한다.
6. instruction/cycle/resource 결과를 함께 출력한다.
```

## 8. 최종적으로 답할 수 있어야 할 질문

- 모델 op가 어떤 단계를 거쳐 instruction이 되는가?
- compiler와 runtime의 책임은 어디에서 나뉘는가?
- ISA 선택이 RTL area/timing과 compiler complexity를 어떻게 바꾸는가?
- lane 수를 늘리면 왜 항상 전체 workload가 빨라지지 않는가?
- simulator, performance model, RTL 결과의 차이는 무엇인가?
- 가장 어려웠던 HW/SW contract bug는 무엇이었는가?
- 어떤 설계를 폐기했고 왜 폐기했는가?
