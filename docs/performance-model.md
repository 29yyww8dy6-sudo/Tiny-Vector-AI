# Performance Model

## 1. 목적

functional correctness와 별도로, architecture 선택이 cycle·memory·utilization에 주는 영향을 예측한다.

## 2. 기본 지표

- instruction count
- MAC operation count
- memory bytes read/written
- estimated cycle
- lane utilization
- peak MAC/cycle
- achieved MAC/cycle
- stall cycle
- code size

## 3. 초기 Cycle Model

초안:

```text
total_cycles
= fetch/decode
+ load_cycles
+ compute_cycles
+ writeback_cycles
+ stall_cycles
```

실제 pipeline과 memory interface에 맞춰 갱신한다.

## 4. Lane Utilization

```text
utilization
= useful_lane_ops / available_lane_ops
```

관찰:

- vector length가 lane 수의 배수가 아닐 때
- 작은 workload
- memory 공급 부족
- pipeline bubble

## 5. Memory Model

초기:

- fixed latency 또는 configurable latency
- bandwidth limit
- one outstanding request

실험:

- latency 변화
- bandwidth 변화
- load/compute overlap
- data reuse

## 6. Peak와 실제 성능

```text
peak = lane_count × MAC_per_lane_per_cycle × frequency
```

실제 성능이 낮은 이유 후보:

- memory stall
- control overhead
- tail underutilization
- pipeline fill/drain
- instruction overhead

## 7. Model Validation

비교:

| 지표 | Model | RTL sim | Synthesis/FPGA | 차이 |
|---|---:|---:|---:|---:|
| Cycle |  |  |  |  |
| Utilization |  |  |  |  |
| Frequency |  | N/A |  |  |
| Throughput |  |  |  |  |

## 8. 학습 질문

- lane을 늘렸는데 실제 throughput이 비례하지 않는 이유는?
- pipeline depth가 cycle과 frequency에 각각 어떤 영향을 주는가?
- memory bandwidth가 어느 지점부터 bottleneck이 되는가?
- cost model이 compiler variant 선택에 사용될 수 있는가?
