# Collaboration Guide

## 1. Ownership

### Software Owner

- graph IR
- lowering
- assembler
- functional simulator
- runtime
- NumPy golden model
- compiler-side benchmark

### Hardware Owner

- microarchitecture specification
- synthesizable RTL
- verification plan
- assertions/regression
- synthesis/timing/resource
- cycle/performance model

### Joint Ownership

- workload
- ISA
- numerical semantics
- memory model
- HW/SW contract
- integration
- co-design experiments
- final demo/report

## 2. Interface 변경 규칙

Contract 또는 ISA 변경은 다음 절차를 따른다.

1. issue 작성
2. ADR 초안
3. software/hardware 영향 작성
4. design review
5. 양쪽 승인
6. test 먼저 또는 동시에 수정
7. version 갱신

## 3. Pull Request 기준

PR에 포함:

- 변경 목적
- 영향 문서
- test
- before/after
- contract 영향
- 관련 issue/ADR/experiment

## 4. Weekly Design Review

논의 순서:

1. 지난 예측과 실제 결과
2. interface 문제
3. 새 bug
4. architecture/compiler 결정
5. 다음 integration slice
6. scope 위험

## 5. Integration Day

최소 주 1회:

```text
같은 workload
→ 최신 compiler
→ 최신 executable
→ simulator
→ RTL
→ golden comparison
```

integration을 프로젝트 마지막으로 미루지 않는다.

## 6. 면접용 기여 분리

각자는 다음을 독립적으로 설명할 수 있어야 한다.

- 내가 소유한 결정
- 내가 작성한 핵심 코드/문서
- 내가 해결한 bug
- 내가 수행한 실험
- 상대 영역과 조율한 interface
- 공동 결과에서 내 판단이 미친 영향
