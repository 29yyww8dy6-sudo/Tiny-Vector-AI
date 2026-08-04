# Microarchitecture Specification

## 1. 목표

Tiny ISA를 synthesizable datapath와 control로 구현하고, 구조 선택의 성능·timing·resource trade-off를 측정한다.

## 2. 초기 Block Diagram

```text
Instruction Memory
       ↓
Program Counter
       ↓
Decoder
       ↓
Control FSM
   ┌───┴───────────┐
   ↓               ↓
Vector Register   Memory Interface
   ↓               ↑
INT8 SIMD Multiplier
   ↓
Adder Tree / Reduction
   ↓
INT32 Accumulator
   ↓
Writeback / Status
```

## 3. 주요 Parameter

| Parameter | 초기값 | 상태 |
|---|---:|---|
| Lane count | 8 | provisional |
| Input width | 8 | fixed |
| Accumulator width | 32 | provisional |
| Register count | TBD | open |
| Pipeline depth | TBD | experiment |
| Memory data width | TBD | open |

## 4. Datapath

정의할 것:

- multiplier 수
- reduction tree
- sign extension
- accumulator update
- saturation/wraparound
- writeback mux

## 5. Control

정의할 것:

- fetch/decode state
- load wait state
- execute state
- writeback
- halt/error
- stall handling

## 6. Pipeline

비교 후보:

- non-pipelined
- MAC/reduction pipelined
- load/compute overlap

측정:

- critical path
- maximum frequency
- latency
- throughput
- control complexity
- bug risk

## 7. Memory Interface

초기 선택:

- simple request/response
- ready/valid 또는 fixed latency
- one outstanding request

추후 optional:

- burst
- dual port
- prefetch
- double buffering

## 8. Hazard / Stall

확인할 것:

- memory response wait
- accumulator dependency
- valid bit propagation
- reset during pending operation
- double writeback 방지

## 9. Design-space Experiments

- lane 4/8/16
- pipeline depth
- accumulator width
- register file size
- fused DOT
- memory bandwidth

## 10. 완료 기준

- [ ] block diagram과 pipeline diagram
- [ ] cycle-by-cycle instruction behavior
- [ ] synthesizable RTL
- [ ] stall/reset semantics
- [ ] synthesis 결과
- [ ] 최소 1개 구조 대안 비교
