# Project Scope

## 1. 반드시 구현할 범위

### 공통

- [ ] 대표 workload와 numerical semantics 정의
- [ ] HW/SW contract
- [ ] end-to-end demo
- [ ] 자동 correctness 검사
- [ ] 최소 2개의 co-design 실험
- [ ] 최종 보고서

### Software

- [ ] Tiny Graph IR
- [ ] Dot lowering
- [ ] Optional MatVec lowering 또는 두 번째 op
- [ ] assembler
- [ ] functional ISA simulator
- [ ] NumPy golden model
- [ ] minimal runtime API
- [ ] generated assembly trace

### Hardware

- [ ] microarchitecture specification
- [ ] synthesizable RTL
- [ ] vector/SIMD MAC datapath
- [ ] instruction decoder와 control
- [ ] register file
- [ ] simple memory interface
- [ ] directed test
- [ ] randomized differential test
- [ ] assertion 또는 protocol check
- [ ] synthesis report
- [ ] timing/resource 분석

## 2. 가능하면 구현할 범위

- [ ] Matrix–Vector workload
- [ ] fused DOT instruction
- [ ] lane parameterization
- [ ] cycle-aware simulator
- [ ] functional coverage
- [ ] FPGA prototype
- [ ] MMIO/UART host interface
- [ ] 간단한 lowering cost model
- [ ] hardware-aware dispatcher
- [ ] layout A/B 비교

## 3. 초기 범위에서 제외

- Dynamic shape
- General-purpose compiler
- Full MLIR/LLVM backend
- Cache hierarchy
- Multicore NPU
- Out-of-order execution
- Production device driver
- PCIe controller
- Full AXI system
- Large systolic array
- Production UVM environment 전체
- 실제 neural network 전체 실행

## 4. Scope 확장 조건

아래가 모두 만족된 후에만 기능을 추가한다.

- [ ] 현재 vertical slice가 end-to-end로 동작한다.
- [ ] regression test가 통과한다.
- [ ] 문서와 contract가 현재 구현과 일치한다.
- [ ] 추가 기능이 어떤 학습 질문을 검증하는지 적혀 있다.
- [ ] 기존 phase 완료가 늦어지지 않는다.

## 5. Scope 축소 조건

다음 중 하나라도 발생하면 선택 기능을 제거한다.

- compiler와 RTL integration이 2주 이상 막힌다.
- correctness regression이 반복된다.
- FPGA/SoC 주변부가 핵심 datapath 학습을 방해한다.
- 새 기능의 성공 기준을 정의할 수 없다.
- synthesis 가능한 core가 아직 없다.
