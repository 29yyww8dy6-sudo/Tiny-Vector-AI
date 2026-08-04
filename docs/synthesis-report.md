# Synthesis and PPA Report

## 1. Environment

- RTL version/commit:
- Tool:
- Tool version:
- Target FPGA/library:
- Clock constraint:
- Synthesis options:

## 2. Configuration

| Parameter | Value |
|---|---:|
| Lane count |  |
| Pipeline depth |  |
| Accumulator width |  |
| Register count |  |
| Memory width |  |

## 3. Result Summary

| Metric | Result |
|---|---:|
| LUT / Cell Area |  |
| FF |  |
| DSP |  |
| BRAM / Memory |  |
| Worst Slack |  |
| Estimated Fmax |  |
| Critical Path |  |
| Estimated Power |  |

## 4. Critical Path Analysis

- Start point:
- End point:
- Logic:
- 예상했던 path인가?
- 구조 변경 후보:

## 5. Configuration Comparison

| Config | Lane | Pipeline | Area | Fmax | Cycle | Est. Throughput |
|---|---:|---:|---:|---:|---:|---:|
| A | 4 |  |  |  |  |  |
| B | 8 |  |  |  |  |  |
| C | 16 |  |  |  |  |  |

## 6. Interpretation

- 성능 향상을 위해 어떤 resource를 더 사용했는가?
- frequency가 올랐지만 cycle/control 비용이 증가했는가?
- lane 수 증가가 memory interface와 균형을 이루는가?
- 가장 균형 잡힌 configuration은 무엇인가?

## 7. Limitations

- simulation-only 요소
- memory model 단순화
- 실제 routing 미반영 여부
- power estimate 정확도
