# ADR-002: INT8 입력과 INT32 Accumulator 사용

- Status: Proposed
- Owners: Software + Hardware

## Context

입력과 accumulation width를 통일해야 simulator, compiler, RTL이 동일한 결과를 낸다.

## Decision

- input: signed INT8
- multiplication result: signed INT16 이상
- accumulator/output: signed INT32

## Open Question

overflow 시 wraparound와 saturation 중 무엇을 사용할 것인가?

## Required Experiment

- worst-case vector length에서 accumulator 범위 계산
- wraparound/saturation RTL 비용 비교
- compiler/runtime error 또는 warning 필요성
