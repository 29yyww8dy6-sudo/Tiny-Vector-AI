# Hardware–Software Contract

이 문서는 compiler, simulator, RTL 사이의 최상위 기준이다. 구현이 서로 다르면 이 문서와 승인된 ADR을 기준으로 판단한다.

## 1. Version

- Contract version: `0.1-draft`
- ISA version: `0.1-draft`
- Breaking change는 ADR과 양 팀 승인 필요

## 2. Numerical Semantics

### Input

- signed INT8 two's complement
- 유효 범위: `-128..127`

### Multiply

- INT8 × INT8
- intermediate product width: 최소 signed INT16

### Accumulator

- 기본: signed INT32
- overflow 정책: TODO
  - [ ] wraparound
  - [ ] saturation
  - [ ] overflow flag

### Output

- 기본 Dot 결과: signed INT32

## 3. Tensor Layout

초기 기본:

- 1D vector: contiguous
- 2D optional matrix: row-major
- byte addressable memory
- alignment requirement: TODO

## 4. Memory Map

초기 초안:

| Region | 의미 | 주소 |
|---|---|---|
| Program | instruction memory | TBD |
| Input A | first operand | TBD |
| Input B | second operand | TBD |
| Output | result | TBD |

주소 배치 책임:

- compile-time static allocation을 기본으로 한다.
- compiler가 address metadata를 생성한다.
- runtime이 실제 memory image를 준비한다.

## 5. Execution Protocol

```text
reset
→ program/data load
→ start
→ running
→ done 또는 error
→ output read
```

필수 상태:

- IDLE
- RUNNING
- DONE
- ERROR

## 6. Reset Semantics

- reset 후 PC = 0
- architectural registers 초기값: TODO
- accumulator 초기값: 0
- pending write 취소 여부: TODO
- reset 중 memory output: don't-care 또는 규정 필요

## 7. Stall / Backpressure

- memory stall이 발생하면 instruction 재실행 금지
- valid는 transaction 완료까지 유지
- writeback은 정확히 한 번만 발생
- pipeline valid bit의 reset/stall 동작을 verification에서 확인

## 8. Error Semantics

지원할 error:

- illegal opcode
- invalid register
- misaligned address
- out-of-range memory
- unsupported shape
- executable version mismatch

각 error가 simulator와 RTL에서 동일하게 표현되는지 정의한다.

## 9. Trace Contract

debug를 위해 backend는 가능하면 다음을 제공한다.

```text
cycle
pc
opcode
source operands
destination
memory address
writeback value
status
```

## 10. Contract 변경 체크리스트

- [ ] 변경 이유가 ADR에 기록됨
- [ ] assembler 수정
- [ ] simulator 수정
- [ ] compiler 수정
- [ ] RTL 수정
- [ ] directed test 수정
- [ ] randomized test 수정
- [ ] version 갱신
