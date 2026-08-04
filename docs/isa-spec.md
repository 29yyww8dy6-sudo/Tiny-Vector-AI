# Tiny NPU ISA Specification

## 1. 설계 목표

- Dot 또는 MatVec를 표현할 수 있을 것
- assembler와 RTL decoder가 단순할 것
- compiler lowering 실험이 가능할 것
- instruction 확장 전후 trade-off를 비교할 수 있을 것

## 2. 초기 Architecture State

- Program Counter
- Scalar/Vector Register File: TBD
- Accumulator Register: TBD
- Flat Memory
- Status Register

## 3. Instruction Format

> 아래는 초안이다. bit width는 ADR로 확정한다.

```text
[ opcode | dst | src0 | src1 | immediate/address ]
```

확정할 항목:

- instruction width
- opcode width
- register index width
- immediate width
- signed immediate 여부
- alignment

## 4. 초기 명령어 후보

| 명령 | 의미 | 필수 여부 |
|---|---|---|
| `VLOAD` | memory → vector register | 필수 |
| `VSTORE` | vector register → memory | 선택 |
| `VMAC` | vector multiply accumulate | 필수 |
| `CLRACC` | accumulator clear | 필수 |
| `STOREACC` | accumulator → memory | 필수 |
| `HALT` | execution 종료 | 필수 |
| `DOT` | fused load/MAC 또는 fused vector dot | 실험 후보 |

## 5. 명령별 명세 템플릿

### `VMAC`

**Semantics**

```text
ACC = ACC + dot(VR[src0], VR[src1])
```

**Inputs**

- `src0`, `src1`: vector register index

**Outputs**

- accumulator

**Latency**

- functional simulator: atomic
- performance model/RTL: microarchitecture에 따라 정의

**Errors**

- invalid register

**Verification**

- zero
- positive/negative
- max/min
- overflow boundary
- random vector

## 6. Assembly Syntax

예시:

```asm
CLRACC
VLOAD v0, [0x100]
VLOAD v1, [0x200]
VMAC   v0, v1
STOREACC [0x300]
HALT
```

## 7. Fused Instruction 실험

비교 대상:

```text
VLOAD + VLOAD + VMAC 반복
vs
DOT memory_a, memory_b, length
```

측정:

- instruction count
- code size
- decoder/datapath complexity
- cycle
- memory behavior
- compiler lowering 복잡도
- synthesis timing/resource

## 8. ISA 변경 규칙

모든 instruction 추가/삭제는 다음을 기록한다.

- 해결하려는 workload 병목
- 대안
- software 영향
- hardware 영향
- verification 영향
- 결과
