# Verification Plan

## 1. 목표

functional simulator와 RTL이 HW/SW contract를 동일하게 구현하는지 자동 검증한다.

## 2. Verification Architecture

```text
Random/Directed Program
          ↓
  Assembler / Executable
     ┌────┴─────┐
     ↓          ↓
Python Model   RTL DUT
     ↓          ↓
 Expected     Actual
     └────Compare────┘
```

## 3. Feature Matrix

| Feature | Directed | Random | Assertion | Coverage |
|---|---:|---:|---:|---:|
| Reset | O |  | O | O |
| Decode | O | O | O | O |
| VLOAD | O | O | O | O |
| VMAC | O | O | O | O |
| STOREACC | O | O | O | O |
| HALT | O | O | O | O |
| Memory stall | O | O | O | O |
| Overflow boundary | O | O |  | O |
| Illegal opcode | O | O | O | O |

## 4. Directed Tests

- zero vector
- all ones
- positive/negative mixed
- INT8 min/max
- single lane/chunk
- multiple chunks
- reset before start
- reset during execution
- memory stall
- illegal opcode
- invalid address

## 5. Randomized Tests

생성할 것:

- random operand
- random valid instruction sequence
- random stall
- random reset timing
- random supported vector length

재현을 위해 seed를 기록한다.

## 6. Assertions

후보:

- writeback은 instruction당 최대 한 번
- invalid state 금지
- done 이후 architectural state 변경 금지
- memory request valid 유지
- reset 후 PC와 accumulator 초기화
- illegal opcode는 error로 전환

## 7. Coverage

가능하면 다음을 추적한다.

- opcode coverage
- register index
- operand boundary
- positive/negative combination
- stall state transition
- reset state transition
- error path

## 8. Differential Test

비교 수준:

1. final output
2. architectural state
3. instruction trace
4. cycle trace는 performance model과 별도 비교

## 9. Fault Injection

의도적으로 넣어볼 bug:

- sign extension 제거
- accumulator bit width 축소
- stall 중 PC 증가
- writeback 중복
- reset 시 valid bit 미초기화

검증 환경이 이를 잡는지 기록한다.

## 10. Exit Criteria

- [ ] 필수 instruction directed test
- [ ] random regression
- [ ] deterministic seed 재현
- [ ] 주요 assertion
- [ ] simulator/RTL output 일치
- [ ] 발견 bug가 bug log와 regression test로 남음
