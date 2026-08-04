# Experiment 002: SIMD Lane 4/8/16 비교

## Question

lane 수를 늘리면 전체 Dot workload 성능이 선형으로 증가하는가?

## Prediction

instruction/cycle은 줄지만 area와 memory 요구가 증가하고, 작은 shape에서는 utilization이 떨어질 수 있다.

## Controlled Variable

lane count만 변경한다.

## Measure

### Software

- generated instruction count
- tail handling
- code size
- estimated memory request

### Hardware

- cycle
- utilization
- area/resource
- Fmax
- critical path

### Joint

- estimated end-to-end throughput
- 가장 균형 잡힌 configuration

## Result

TBD
