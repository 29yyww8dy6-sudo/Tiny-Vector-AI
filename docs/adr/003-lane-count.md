# ADR-003: 초기 8-lane SIMD를 시작점으로 사용

- Status: Proposed
- Owners: Hardware + Software

## Context

lane 수는 compiler chunking, instruction count, RTL area, critical path, memory bandwidth에 동시에 영향을 준다.

## Alternatives

- 4 lane
- 8 lane
- 16 lane

## Initial Decision

첫 구현은 8 lane으로 시작하되 최종 선택으로 고정하지 않는다.

## Validation Plan

- 동일 Dot workload에서 4/8/16 lane 비교
- compiler instruction count
- cycle model
- lane utilization
- synthesis area/resource
- maximum frequency
- estimated throughput

## Final Decision

실험 후 갱신.
