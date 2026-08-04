# System Overview

## 1. 목표 시스템

```text
Python Graph API
      ↓
Tiny Graph IR
      ↓
Lowering Pass
      ↓
Assembly Text
      ↓
Assembler
      ↓
Executable / Machine Code
      ↓
Minimal Runtime
      ├── Functional ISA Simulator
      └── RTL Backend
               ↓
         Output Buffer
               ↓
      NumPy Golden Model 비교
```

## 2. 초기 대표 workload

### Dot Product

```text
y = Σ a[i] * b[i]
```

초기 조건:

- `a`, `b`: signed INT8
- `y`: signed INT32 accumulator
- vector length: static, lane 수의 배수 우선
- overflow/saturation 정책은 contract에서 명시

### Optional Matrix–Vector

```text
y[m] = Σ A[m, k] * x[k]
```

## 3. Software Stack

### Graph API

- Tensor
- Dot
- Optional MatVec
- static shape
- dtype

### Compiler

- validation
- canonicalization
- lowering
- address assignment
- assembly emission

### Runtime

- executable load
- input buffer 준비
- backend 실행
- output 수집
- profile 정보 반환

## 4. Hardware Stack

초기 block:

```text
Instruction Memory
       ↓
Fetch / Decode
       ↓
Control FSM
       ↓
Vector Register File
       ↓
INT8 SIMD MAC
       ↓
INT32 Accumulator
       ↓
Writeback / Memory
```

## 5. Interface Boundaries

| 경계 | 전달 정보 |
|---|---|
| Graph → Compiler | op, shape, dtype, constants |
| Compiler → Assembler | instruction, register, address |
| Assembler → Runtime | executable bytes + metadata |
| Runtime → Backend | memory image, program, start |
| Backend → Runtime | output, status, cycle/trace |
| Golden Model → Verification | expected tensor/result |

## 6. 현재 단순화

- 하나의 program을 순차 실행
- static memory allocation
- single clock domain
- simple ready/valid 또는 fixed-latency memory
- cache 없음
- interrupt 없음
- dynamic scheduling 없음

## 7. 최종 다이어그램 갱신 규칙

구조가 바뀌면 다음 문서를 함께 수정한다.

- `system-overview.md`
- `hw-sw-contract.md`
- `isa-spec.md`
- `microarchitecture.md`
- 관련 ADR
