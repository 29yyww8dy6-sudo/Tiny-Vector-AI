# Interview Notes

## 1. 30초 소개

> 작은 INT8 workload를 graph IR에서 custom ISA로 lowering하고, Python functional simulator와 synthesizable RTL에서 동일하게 실행·검증한 HW/SW co-design 프로젝트입니다. compiler와 microarchitecture를 함께 변경하면서 lane 수, fused instruction, pipeline 등의 성능·timing·resource trade-off를 비교했습니다.

## 2. Software 직무 설명

강조:

- IR와 lowering
- ISA-aware code generation
- runtime/backend abstraction
- generated vs handwritten assembly
- cost model/variant 선택
- RTL과의 contract debugging

답할 질문:

- 왜 IR을 만들었는가?
- address와 layout은 어디에서 결정했는가?
- ISA 변경이 compiler에 어떤 영향을 줬는가?
- simulator는 어떤 oracle 역할을 했는가?

## 3. RTL Design 직무 설명

강조:

- workload → microarchitecture
- datapath/control/pipeline
- synthesis 가능한 RTL
- lane/pipeline trade-off
- critical path와 resource

답할 질문:

- 왜 해당 lane 수를 선택했는가?
- pipeline stage를 어디에 넣었는가?
- memory가 datapath를 계속 공급할 수 있는가?
- timing 결과로 무엇을 바꿨는가?

## 4. Design Verification 직무 설명

강조:

- verification plan
- Python golden model
- randomized differential test
- assertions
- stall/reset/overflow
- bug 재발 방지

답할 질문:

- directed test만으로 부족한 이유는?
- 가장 어려웠던 RTL bug는?
- coverage hole을 어떻게 찾았는가?
- seed를 어떻게 재현했는가?

## 5. Architecture 직무 설명

강조:

- design-space exploration
- performance model
- PPA-performance
- compiler/RTL 공동설계
- fused instruction과 layout

답할 질문:

- PE/lane을 늘렸는데 왜 선형 speedup이 안 났는가?
- peak와 achieved throughput 차이는?
- ISA 확장이 전체 stack에 어떤 비용을 만들었는가?

## 6. STAR 기록 템플릿

### Situation
어떤 문제와 제약이 있었는가?

### Task
내가 소유한 결정은 무엇이었는가?

### Action
어떤 가설, 실험, 디버깅을 했는가?

### Result
정확성, cycle, timing, resource가 어떻게 달라졌는가?

### Reflection
다시 한다면 무엇을 바꿀 것인가?
