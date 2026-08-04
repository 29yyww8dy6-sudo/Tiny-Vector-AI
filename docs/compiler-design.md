# Compiler Design

## 1. 목표

작은 graph를 검증하고 custom ISA program으로 lowering한다.

```text
Graph
→ Validate
→ Canonicalize
→ Assign Layout/Address
→ Lower
→ Emit Assembly
```

## 2. Tiny IR

### Tensor

필수 속성:

- name
- shape
- dtype
- layout
- storage class
- optional constant data

### Operation

초기:

- Dot
- Optional MatVec
- Optional ReLU 또는 Store

### Graph

- inputs
- outputs
- op sequence
- static shape only

## 3. Validation

확인할 것:

- shape compatibility
- dtype support
- static size
- memory capacity
- supported op
- accumulator range 경고

## 4. Address Assignment

초기 전략:

- static linear allocation
- input → temporary → output 순서
- alignment 반영
- address map을 executable metadata에 기록

## 5. Dot Lowering

예시:

```text
for each vector chunk:
    VLOAD a_chunk
    VLOAD b_chunk
    VMAC
STOREACC
```

확인할 요소:

- vector length와 lane 수
- tail 처리
- address increment
- accumulator clear
- instruction count

## 6. Lowering A/B 후보

### A: 일반 명령 조합

- 단순 ISA
- instruction 수 증가
- hardware 단순

### B: fused DOT

- instruction 수 감소
- decoder/control/datapath 복잡도 증가 가능
- compiler 단순화 가능

두 후보는 experiment 문서로 비교한다.

## 7. Compiler Dump

debug를 위해 다음을 출력한다.

- input graph
- validated IR
- memory map
- lowered instruction list
- final assembly
- estimated instruction/memory count

## 8. Test

- single chunk
- multiple chunks
- negative value
- max/min
- unsupported shape
- tail shape
- generated vs handwritten assembly

## 9. 학습 질문

- IR에 target-specific lane 수를 넣어야 하는가?
- layout은 compiler가 결정해야 하는가?
- runtime에 남겨야 할 결정은 무엇인가?
- hardware가 바뀌면 lowering을 어떻게 선택해야 하는가?
- cost model은 어떤 지표를 사용해야 하는가?
