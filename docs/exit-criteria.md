# Phase Exit Criteria

## Phase 0 — Contract

- [ ] workload 확정
- [ ] dtype와 accumulator semantics
- [ ] 최소 ISA 초안
- [ ] memory/layout 초안
- [ ] 역할 분담
- [ ] scope 확정

## Phase 1 — Handwritten Vertical Slice

- [ ] handwritten assembly 존재
- [ ] expected output 수작업/NumPy 확인
- [ ] instruction 흐름 설명 가능
- [ ] memory map 명시

## Phase 2 — Assembler / Simulator

- [ ] assembler error 처리
- [ ] 모든 필수 instruction directed test
- [ ] simulator trace
- [ ] golden model과 일치
- [ ] random operand regression

## Phase 3 — Compiler

- [ ] graph validation
- [ ] Dot lowering
- [ ] generated assembly
- [ ] handwritten 결과와 일치
- [ ] unsupported case 처리

## Phase 4 — Runtime

- [ ] compile/run/profile demo
- [ ] executable metadata
- [ ] input/output buffer
- [ ] backend error 처리

## Phase 5 — Microarchitecture

- [ ] block diagram
- [ ] pipeline/cycle 설명
- [ ] reset/stall semantics
- [ ] 주요 parameter
- [ ] 대안 하나 이상

## Phase 6 — RTL

- [ ] lint 또는 기본 정적 검사
- [ ] synthesizable
- [ ] 필수 instruction 실행
- [ ] reset/stall test

## Phase 7 — Verification

- [ ] simulator/RTL differential test
- [ ] random regression
- [ ] assertion
- [ ] 주요 bug regression
- [ ] seed 재현

## Phase 8 — Synthesis

- [ ] timing constraint
- [ ] resource/area
- [ ] critical path
- [ ] parameter variant 비교
- [ ] 결과 해석

## Project Exit

- [ ] end-to-end demo
- [ ] 최소 2개 co-design experiment
- [ ] ADR 3개 이상
- [ ] bug 기록 2개 이상
- [ ] 실패/폐기 설계 기록
- [ ] final report
- [ ] 개인별 interview notes
