# Tiny NPU Project Documentation

이 저장소의 문서 묶음은 Tiny NPU 프로젝트를 단순 구현 과제가 아니라 다음 세 가지로 운영하기 위한 가이드다.

1. **학습 프로젝트** — 모델 연산이 compiler, runtime, ISA, RTL을 거쳐 실행되는 전체 경로를 이해한다.
2. **HW/SW Co-design 프로젝트** — software와 hardware의 선택을 따로 보지 않고 함께 실험한다.
3. **면접 증거 저장소** — 각 팀원이 어떤 판단을 소유했고 무엇을 검증했는지 재현 가능한 형태로 남긴다.

## 프로젝트 한 문장

> 작은 INT8 tensor workload를 graph IR에서 custom ISA로 lowering하고, functional simulator와 synthesizable RTL backend에서 동일하게 실행·검증하며, compiler와 microarchitecture의 설계 선택을 함께 비교한다.

## 권장 최종 실행 흐름

```text
Tensor / Graph
    ↓
Tiny IR
    ↓
Compiler Lowering
    ↓
Assembly
    ↓
Assembler / Executable
    ↓
Runtime
    ├─ Functional ISA Simulator
    └─ RTL / FPGA Backend
            ↓
       Golden Model 비교
```

## 문서 지도

| 문서 | 역할 |
|---|---|
| [Project Overview](docs/project-overview.md) | 프로젝트의 목표, 최종 사용자 시나리오, 실행 흐름, 핵심 질문, 최종 데모와 성공 기준 |
| [Project Guide](docs/project-guide.md) | 전체 진행 순서와 문서 사용법 |
| [Scope](docs/scope.md) | 필수·선택·제외 범위 |
| [Learning Map](docs/learning-map.md) | 프로젝트에서 공부할 지식과 완료 기준 |
| [System Overview](docs/system-overview.md) | 전체 구조와 데이터 흐름 |
| [HW/SW Contract](docs/hw-sw-contract.md) | software와 hardware 사이의 기준 문서 |
| [ISA Specification](docs/isa-spec.md) | 명령어와 numerical semantics |
| [Compiler Design](docs/compiler-design.md) | IR, lowering, code generation |
| [Runtime Design](docs/runtime-design.md) | executable, buffer, run/profile API |
| [Microarchitecture](docs/microarchitecture.md) | datapath, control, pipeline |
| [Verification Plan](docs/verification-plan.md) | directed/random/coverage/RTL 검증 |
| [Performance Model](docs/performance-model.md) | cycle·memory·utilization 모델 |
| [Synthesis Report](docs/synthesis-report.md) | timing/resource/PPA 결과 템플릿 |
| [Collaboration](docs/collaboration.md) | 역할, 리뷰, integration 방식 |
| [Exit Criteria](docs/exit-criteria.md) | phase별 종료 조건 |
| [Interview Notes](docs/interview-notes.md) | 직무별 면접 설명 추출 |
| [Final Report](docs/final-report.md) | 프로젝트 종료 보고서 |

## 기록 폴더

```text
docs/
├── adr/          # 설계 의사결정
├── experiments/  # 예측-실험-결과 기록
├── bugs/         # 버그와 재발 방지 테스트
└── reviews/      # 주간 설계 리뷰
```

## 운영 원칙

- 기능을 추가하기 전에 **질문과 성공 기준**을 먼저 적는다.
- 성능 실험 전에 **예측**을 남긴다.
- compiler와 RTL 결과가 다르면 `hw-sw-contract.md`를 기준으로 판단한다.
- 중요한 설계 변경은 ADR 없이 진행하지 않는다.
- 실패한 실험과 폐기한 설계도 남긴다.
- 각 phase는 `exit-criteria.md`를 통과해야 종료한다.
