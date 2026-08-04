# ADR-001: 첫 Vertical Slice의 Workload로 INT8 Dot Product 선택

- Status: Accepted
- Owners: Software + Hardware

## Context

전체 stack을 빠르게 연결하면서도 compiler, ISA, SIMD MAC, numerical verification을 모두 경험할 workload가 필요하다.

## Alternatives

- elementwise add
- dot product
- matrix–vector
- matrix multiplication

## Decision

첫 vertical slice는 signed INT8 Dot Product로 한다.

## Rationale

- add보다 accelerator 특성이 분명하다.
- MatMul보다 scope가 작다.
- SIMD lane과 accumulator를 실험할 수 있다.
- compiler lowering과 handwritten assembly 비교가 쉽다.
- NumPy golden model이 단순하다.

## Consequences

- memory hierarchy와 reuse 학습은 제한적이다.
- MatVec 또는 MatMul을 optional second workload로 추가할 수 있다.
