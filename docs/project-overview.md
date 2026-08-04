## 1. 프로젝트 한눈에 보기

### 1.1 한 문장 정의

정적 shape의 INT8 Linear 연산을 Tiny Graph에서 custom ISA로 컴파일하고, Python functional simulator와 synthesizable RTL NPU에서 동일한 결과로 실행·검증하며, compiler와 microarchitecture의 설계 선택이 cycle, utilization, timing, resource에 미치는 영향을 비교한다.

### 1.2 최종 사용자 시나리오

사용자는 학습이 완료된 작은 INT8 숫자 분류 모델과 8×8 흑백 숫자 이미지를 입력한다.

Tiny NPU software stack은 모델의 `Linear(64 → 10)` 연산을 Tiny IR로 표현하고, custom ISA program으로 lowering한 뒤 executable을 생성한다.

Runtime은 executable, quantized weight, bias, input을 functional simulator 또는 RTL backend에 전달한다.

Backend는 10개의 INT32 logit을 계산하고, host는 argmax를 수행해 0부터 9 사이의 예측 결과를 출력한다.

실행 후 reference 결과, backend 결과, correctness, instruction 수, cycle, utilization을 함께 출력한다.

### 1.3 End-to-end 실행 흐름

```text
8×8 숫자 이미지
→ Flatten [64]
→ INT8 입력 변환
→ Linear Graph [64 → 10]
→ Tiny IR
→ MatVec / Dot Lowering
→ Assembly
→ Assembler
→ Executable
→ Minimal Runtime
→ Functional Simulator 또는 RTL
→ INT32 Logit [10]
→ Python Reference 비교
→ Host Argmax
→ 예측 숫자
```

프로젝트의 첫 vertical slice에서는 단일 INT8 Dot Product만 실행한다.

최종 필수 workload는 `Linear(64 → 10)`이며, 선택 확장으로 `Linear(64 → 32) → ReLU → Requantize → Linear(32 → 10)` 구조를 지원한다.

### 1.4 프로젝트의 핵심 질문

#### Software

* Linear 연산을 custom ISA로 어떻게 lowering할 것인가?
* lane 수와 tensor shape에 따라 instruction sequence가 어떻게 달라지는가?
* compiler, assembler, runtime, backend의 책임은 어디에서 나뉘는가?
* handwritten assembly와 compiler-generated assembly의 차이는 무엇인가?
* 여러 lowering 후보 중 더 나은 방식을 어떻게 선택할 것인가?

#### Hardware

* SIMD lane 수가 cycle, utilization, area, maximum frequency에 어떤 영향을 주는가?
* pipeline을 추가하면 latency와 throughput은 어떻게 달라지는가?
* memory interface가 MAC datapath를 충분히 공급할 수 있는가?
* fused instruction의 성능 이득이 decoder와 datapath 복잡도 증가를 정당화하는가?
* simulator의 예상 cycle과 RTL cycle이 다른 이유는 무엇인가?

#### Verification

* signed INT8 multiplication과 INT32 accumulation이 모든 경계값에서 정확한가?
* reset, stall, illegal instruction 상황이 contract대로 처리되는가?
* functional simulator와 RTL의 결과 및 architectural state가 일치하는가?
* randomized differential test가 pipeline과 numerical bug를 발견할 수 있는가?

#### Co-design

* software의 instruction 감소와 hardware의 area/timing 증가 사이에서 어떤 선택이 적절한가?
* 특정 lane 수와 ISA가 선택된 workload에서만 좋은 것은 아닌가?
* compiler가 hardware configuration에 따라 다른 lowering을 자동 선택할 수 있는가?

### 1.5 최종 데모

```bash
tiny-npu compile digit_classifier.json \
  --target tiny-npu-v1 \
  --output digit.bin

tiny-npu run digit.bin \
  --input digit-7.bin \
  --backend rtl \
  --verify
```

예상 출력:

```text
Model:              Linear(64 → 10)
Input dtype:        INT8
Weight dtype:       INT8
Accumulator:        INT32
Backend:            RTL
Prediction:         7

Reference output:   [...]
Backend output:     [...]
Correctness:        PASS

Instruction count:  ...
RTL cycles:         ...
Lane utilization:   ...
```

최종 발표에서는 동일 executable 또는 동일 semantics의 program을 functional simulator와 RTL에서 각각 실행하고, 두 결과를 Python golden model과 비교한다.

또한 최소 두 개의 HW/SW co-design 실험 결과를 함께 제시한다.

### 1.6 성공 기준

#### 필수 기능

* [ ] INT8 Dot Product vertical slice가 동작한다.
* [ ] `Linear(64 → 10)` graph를 표현할 수 있다.
* [ ] compiler가 custom ISA assembly를 생성한다.
* [ ] assembler가 executable을 생성한다.
* [ ] minimal runtime이 executable과 input을 backend에 전달한다.
* [ ] functional simulator에서 모델 연산이 실행된다.
* [ ] synthesizable RTL에서 동일 연산이 실행된다.
* [ ] Python golden model, simulator, RTL 결과가 일치한다.
* [ ] 실제 학습된 숫자 분류 weight를 사용해 예측 결과를 출력한다.

#### Verification

* [ ] instruction별 directed test가 존재한다.
* [ ] signed value와 경계값 test가 존재한다.
* [ ] randomized differential test가 존재한다.
* [ ] reset과 stall 동작을 검사한다.
* [ ] 발견된 주요 bug에 regression test를 추가한다.

#### Hardware 결과

* [ ] synthesis가 통과한다.
* [ ] area 또는 FPGA resource 결과가 있다.
* [ ] timing 결과와 critical path 분석이 있다.
* [ ] cycle과 lane utilization을 측정할 수 있다.

#### Co-design 결과

* [ ] lane 수 비교 또는 pipeline 비교를 수행한다.
* [ ] 일반 명령 조합과 fused instruction을 비교한다.
* [ ] 각 실험에 사전 예측과 실제 결과가 기록되어 있다.
* [ ] 성능 개선으로 발생한 hardware/software 비용을 설명한다.
* [ ] 최종 설계 선택을 ADR로 기록한다.

#### 문서와 재현성

* [ ] 한 명령 또는 명확한 절차로 최종 데모를 재현할 수 있다.
* [ ] HW/SW contract가 실제 구현과 일치한다.
* [ ] 각 팀원의 코드·설계·실험 ownership이 기록되어 있다.
* [ ] 실패한 실험과 폐기한 설계가 기록되어 있다.
* [ ] 프로젝트의 한계와 다음 연구 질문이 정리되어 있다.
