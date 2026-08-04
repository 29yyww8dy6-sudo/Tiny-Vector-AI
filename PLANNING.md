# Tiny-Vector-AI — 마일스톤 & 학습 계획

개인/팀 진행 관리용 문서. 저장소에는 커밋하지 않음 (.gitignore 처리).

## 진행 원칙

1. **발명하지 말고 베껴서 단순화.** RISC-V 32비트 인코딩(opcode/rd/rs1/rs2 필드 배치)을 그대로 가져와서 명령어 6개만 남긴다.
2. **ISA 논의 타임박스 2주.** v0.1 스펙(인코딩 표 + 의사코드)을 `docs/isa_spec.md`에 확정하고 얼린다. 부족한 건 v0.2로 미룬다.
3. **결정마다 이유를 한 줄씩 기록.** 예: "VDOT 누산을 왜 32비트로?" → "INT8×INT8 최대 16384 × 벡터길이 8 = 17비트 필요, 마진 포함 32비트". 이 기록이 면접 답변집이 된다.

## 마일스톤 (DoD = 검증 가능한 한 문장)

- **M0. ISA v0.1 확정 (2주)**
  DoD: `isa_spec.md`에 6개 명령어 인코딩 표 + 의사코드 완성, 둘 다 서명(커밋).

- **M1. 툴체인 관통 (Jeon, +2주)**
  DoD: `dot_product.asm` → `assembler.py` → `.hex` 생성, 골든 모델이 같은 `.asm`을 실행해 기대값 출력. RTL 없이 SW만으로 먼저 관통.

- **M2. RTL 최소 관통 (친구, +4주)**
  DoD: VLD→VADD→VST→HALT 4개 명령만으로 iverilog 시뮬이 돌고, 결과 메모리 덤프가 골든 모델과 일치. VDOT·VMUL은 뒤로 미룸 — 제일 쉬운 명령으로 fetch/decode/regfile/메모리 경로를 먼저 뚫는다.

- **M3. 전 명령어 + 자동 비교 (공동, +3주)**
  DoD: 6개 명령어 전부 구현, `make test` 한 방에 [.asm 여러 개 → RTL 실행 → 골든 모델 실행 → diff 자동 비교]가 돌아서 PASS/FAIL 출력.

- **M4. Vivado 합성 (친구, +3주)**
  DoD: Zynq-7010 타겟 합성 통과, Fmax/LUT/DSP/BRAM 수치를 `performance_notes.md`에 기록. 보드 없이도 합성 리포트는 나오니 배포보다 먼저.

- **M5. 보드 배포 (공동, +4주)**
  DoD: EBAZ4205에서 PS가 AXI로 벡터를 쓰고, 가속기가 dot product를 계산하고, PS가 결과를 읽어 화면에 출력. 친구가 PL, Jeon이 PS 호스트 코드.

- **M6+. 심화 (병렬)**
  - 친구: 파이프라이닝/GEMM, coverage 측정
  - Jeon: 사이클 성능 모델 + DSE 실험
  - DoD 예시: 성능 모델 예측 사이클과 RTL 실측이 오차 5% 이내.

전체 타임라인 여유 있게 6~7개월. 학기 병행이면 M5까지를 방학에 맞추는 걸 추천.

### 운영 메모

- M2가 최대 고비. 이 시점에 HDL Bits(온라인 Verilog 연습) 병행 추천.
- 매주 30분 "스펙 싱크" 정기 미팅. 인터페이스(메모리 맵, 명령어 의미) 어긋난 채 각자 진행하는 게 최악의 시간 낭비.
- 막히면 마일스톤을 쪼개되 순서는 바꾸지 않는다. M2가 늦어져도 M4를 먼저 당기지 않는다 — 시뮬에서 안 도는 걸 합성하는 건 의미 없음.

## 학습 자료 (M0 기간 우선순위)

### 필수

1. **The RISC-V Instruction Set Manual, Vol. I (Unprivileged)** — Chapter 2 RV32I 기본 인코딩(R/I/S-type)만. opcode/rd/rs1/rs2/funct 필드 위치, 레지스터 필드 위치를 모든 포맷에서 고정하는 이유(디코더 단순화)를 이해하고 그대로 차용.
2. **RISC-V Vector Extension (RVV) Spec v1.0** — `vadd.vv`, `vle/vse`(load/store) 오퍼랜드 구조, SEW(element width) 개념만. "RVV의 어떤 부분을 왜 버렸는가"(예: vsetvli 없이 고정 벡터 길이)를 한 줄로 기록.
3. **Patterson & Hennessy, 컴퓨터 조직과 설계 (COD)** — Chapter 2(명령어: 컴퓨터 언어)만 정독. 인코딩 설계 철학 이해.

### 강력 추천 (설계 감각용)

4. 기존 미니 ISA 구현 사례:
   - `darklife/darkriscv` — RV32 서브셋 단순 Verilog 구현, decode 코드 실물 감각.
   - tiny-gpu (adam-maj) — 교육용 미니 GPU, "축소판 가속기 ISA + 문서화" 벤치마크.
5. Google TPU 소개 글 / MIT 6.5940 강의자료 — VDOT 같은 누산 명령 시맨틱(누산기 초기화 시점, 오버플로 처리) 참고.

### 스펙 문서 작성 양식

6. RISC-V 스펙의 명령어 페이지 형식을 템플릿으로: 명령어당 [어셈블리 문법 / 인코딩 비트필드 그림 / 동작 의사코드 / 예외 조건] 4항목. `isa_spec.md`를 이 틀로 작성.

### 지금은 보지 않을 것

- Hennessy & Patterson *Computer Architecture: A Quantitative Approach* — M6 성능 모델 단계에서.
- RISC-V Privileged Spec, 인터럽트/예외 자료 — 이 ISA엔 HALT만 있으면 됨.
- ARM/x86 레퍼런스 — 인코딩 복잡해서 참고 대상 부적합.

### 실행 순서

COD 2장 각자 읽기 → RV32I 인코딩 표를 같이 보며 "6개 명령을 이 틀에 어떻게 넣을까" 화이트보드 세션 1~2회 → darkriscv decode 코드로 현실성 체크 → `isa_spec.md` v0.1 작성.
