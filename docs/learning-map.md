# Learning Map

## 1. 전체 학습 지도

| 계층 | 공부할 내용 | 프로젝트에서 확인할 증거 |
|---|---|---|
| Workload | Dot/MatVec, shape, dtype, overflow | golden model, workload spec |
| Compiler IR | Tensor, op, shape, dtype, layout | IR dump |
| Lowering | iteration, address, instruction sequence | generated assembly |
| Runtime | executable, buffer, dispatch, profile | runtime API demo |
| ISA | encoding, register, memory, semantics | ISA spec, assembler |
| Architecture | datapath, control, pipeline, memory | block/pipeline diagram |
| RTL | synthesizable module, reset/stall | lint/simulation/synthesis |
| Verification | oracle, random test, assertion, coverage | regression report |
| Performance | cycle, bandwidth, utilization | performance model |
| PPA | timing, area/resource, critical path | synthesis report |
| Co-design | SW/HW trade-off | experiment notes, ADR |

## 2. Software 담당자 완료 기준

다음을 설명할 수 있어야 한다.

- IR이 단순 Python 객체 목록과 다른 이유
- shape/dtype/layout 정보가 lowering에 필요한 이유
- Dot loop가 어떤 instruction sequence가 되는지
- handwritten assembly와 generated assembly의 차이
- runtime이 compiler와 다른 책임을 갖는 이유
- ISA가 변경될 때 software stack에서 바뀌는 위치
- functional simulator가 검증하는 것과 검증하지 못하는 것

## 3. Hardware 담당자 완료 기준

다음을 설명할 수 있어야 한다.

- workload가 datapath 요구사항으로 바뀌는 과정
- lane 수와 register/memory bandwidth의 관계
- pipeline이 frequency와 latency에 주는 영향
- stall과 valid signal을 잘못 처리했을 때 생기는 bug
- directed test와 randomized test의 역할 차이
- synthesis와 simulation이 서로 다른 정보를 주는 이유
- critical path와 area/resource 결과를 이용한 구조 선택

## 4. 공동 완료 기준

- ISA 결정의 software/hardware 장단점을 함께 설명한다.
- 동일 입력에서 simulator와 RTL 결과를 비교한다.
- 최소 하나의 성능 개선이 다른 지표를 악화시킨 사례를 설명한다.
- 예측과 실제가 달랐던 실험을 한 개 이상 남긴다.
- 폐기한 설계와 폐기 이유를 기록한다.

## 5. 학습 전후 기록 표

| 질문 | 시작 전 이해 | 현재 이해 | 남은 공백 |
|---|---|---|---|
| IR이 왜 필요한가? |  |  |  |
| ISA가 왜 필요한가? |  |  |  |
| pipeline이 왜 필요한가? |  |  |  |
| verification coverage가 왜 필요한가? |  |  |  |
| lane 수가 성능에 어떤 영향을 주는가? |  |  |  |
| memory bandwidth가 왜 병목이 되는가? |  |  |  |
