# References — Tiny-Vector-AI

M0 목표는 **"6개 명령어짜리 미니 벡터 ISA"** 확정이다. 두꺼운 자료를 다 읽지
말고, 각 자료에서 **볼 부분만 정확히** 본다.

> PDF 등 대용량 바이너리는 `.gitignore`로 커밋에서 제외한다.
> (`references/specs/`는 로컬에만 존재, 이 인덱스와 `notes/`의 `.md`만 추적됨)

## 폴더 구성

```text
references/
├── README.md              # 이 인덱스 (우선순위 + 무엇을 볼지)
├── specs/                 # 다운로드한 스펙 PDF (git 미추적)
│   ├── riscv-spec-unprivileged.pdf   # RISC-V Unprivileged ISA Manual
│   └── riscv-v-spec-1.0.pdf          # RISC-V Vector Extension v1.0
└── notes/                 # 읽으면서 남기는 노트 (git 추적)
    └── _template.md
```

---

## 필수 (M0 기간에 실제로 펼쳐놓고 볼 것)

### 1. RISC-V Instruction Set Manual, Vol. I (Unprivileged)
- 파일: [`specs/riscv-spec-unprivileged.pdf`](specs/riscv-spec-unprivileged.pdf) · 원본: https://github.com/riscv/riscv-isa-manual/releases
- **볼 부분: Chapter 2의 RV32I 기본 인코딩 (R/I/S-type 포맷)뿐.**
- 핵심: opcode/rd/rs1/rs2/funct 필드를 어디에 몇 비트씩 두는지, 왜 레지스터
  필드 위치를 모든 포맷에서 고정하는지(→ 디코더 단순화)를 이해하고 그대로 차용.
- 이것만 해도 인코딩 설계의 90%가 끝난다.

### 2. RISC-V Vector Extension (RVV) Spec v1.0
- 파일: [`specs/riscv-v-spec-1.0.pdf`](specs/riscv-v-spec-1.0.pdf) · 원본: https://github.com/riscvarchive/riscv-v-spec/releases/tag/v1.0
- **전부 읽으면 늪.** 볼 것만: `vadd.vv`, `vle/vse`(load/store)의 오퍼랜드 구조,
  그리고 SEW(element width) 개념 정도.
- 산출물: **"우리는 RVV의 어떤 부분을 왜 버렸는가"**(예: `vsetvli` 없이 고정 벡터 길이)를
  `docs/isa_spec.md`에 한 줄 기록 → 그게 설계 결정 기록이 된다.

### 3. Patterson & Hennessy — 컴퓨터 조직과 설계 (COD)
- 책 (README 참고자료에 있음). **저작권 자료라 다운로드 안 함 — 각자 소장본/도서관 이용.**
- **볼 부분: Chapter 2 (명령어: 컴퓨터 언어)만 정독.**
- 인코딩 표를 "이해하고" 베낄 수 있게 해주는 설계 철학 설명.

---

## 강력 추천 (설계 감각용)

### 4. 기존 미니 ISA 구현 사례
- **darklife/darkriscv** — https://github.com/darklife/darkriscv
  RV32 서브셋을 단순 Verilog로 구현. decode가 실제 코드로 어떻게 생기는지 감이 온다.
- **tiny-gpu (adam-maj)** — https://github.com/adam-maj/tiny-gpu
  교육용 미니 GPU. "축소판 가속기 ISA + 문서화" 스타일의 좋은 벤치마크 —
  우리가 지향할 README/스펙 문서 수준의 레퍼런스.

### 5. Systolic Array / TPU 자료 + MIT 6.5940
- Google TPU / systolic array 소개 글, MIT 6.5940 (TinyML) 강의자료.
- 용도: **VDOT 같은 누산 명령의 시맨틱**(누산기 초기화는 언제? 오버플로 처리는?)을
  정할 때 실제 가속기들의 선택을 참고.
- MIT 6.5940: https://hanlab.mit.edu/courses/2023-fall-65940

---

## 스펙 문서 작성 양식 참고

RISC-V 스펙의 **명령어 페이지 형식**을 `docs/isa_spec.md` 템플릿으로 사용:
명령어당 4항목 →
1. 어셈블리 문법
2. 인코딩 비트필드 그림
3. 동작 의사코드
4. 예외 조건

이 틀로 쓰면 그 자체가 포트폴리오 문서가 된다. (`notes/_template.md`에 골격 있음)

---

## 보지 말 것 (지금은)

- **Hennessy & Patterson — Computer Architecture: A Quantitative Approach**
  좋은 책이지만 M0엔 오버킬. **M6 성능 모델 단계에서 다시 온다.**
- **RISC-V Privileged Spec, 인터럽트/예외 자료** — 우리 ISA엔 `HALT`만 있으면 됨.
- **ARM/x86 레퍼런스** — 인코딩이 복잡해 참고 대상으로 부적합.

---

## 실행 순서 (2주 타임박스)

1. 둘이 **COD 2장**을 각자 읽는다.
2. **RV32I 인코딩 표**를 같이 보며 "우리 6개 명령을 이 틀에 어떻게 넣을까"
   화이트보드 세션 1~2회.
3. **darkriscv decode 코드**를 보며 현실성 체크.
4. **`docs/isa_spec.md` v0.1** 작성.

우리 6개 명령어: `VLD`, `VST`, `VADD`, `VMUL`, `VDOT`, `HALT`
(상세는 [`../docs/isa_spec.md`](../docs/isa_spec.md) 참조)
