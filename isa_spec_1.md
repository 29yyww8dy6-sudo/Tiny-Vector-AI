# Tiny-Vector-AI ISA v1

INT8 벡터 가속기용 도메인 특화 명령어 셋. RVV에서 영감을 받았으나 호환을 목표하지 않는다.

- 타깃: EBAZ4205 (Zynq-7010, XC7Z010)
- 워크로드: INT8 GEMV / GEMM
- 상태: v1 draft

---

## 1. 아키텍처 상태

| 이름 | 인코딩 상한 | Tier 0 구현 | 폭 | 비고 |
|---|---|---|---|---|
| `v0`–`v7` | 8 | **2** | 256 bit | INT8 32개. 3-bit 필드로 지목 |
| `acc0`–`acc7` | 8 | **1** | INT32 | 누산기 |
| `s0`–`s3` | 4 | **0** | 32 bit | 스칼라. **Tier 2에서 추가** |
| `pc` | 1 | 1 | 16 bit | 명령어 65536개까지 |

### 구현 범위

> 위 개수는 **인코딩 상한**이며, 구현은 그보다 적을 수 있다. 구현 범위를 벗어난 레지스터 접근은 어셈블러와 RTL 양쪽에서 오류로 처리한다.

Tier 0 프로그램은 `v0`, `v1`, `acc0`만 사용하므로 그만큼만 합성한다. 안 쓰는 레지스터는 LUT를 소모하고, write-enable 디코딩 로직을 늘리며, 파형 디버깅을 어렵게 한다.

RTL은 개수를 파라미터로 받는다:

```verilog
module vregfile #(
    parameter NREG  = 2,      // Tier 0: 2 → Tier 1: 8
    parameter ELEMS = 32
)(...);
    reg [ELEMS*8-1:0] regs [0:NREG-1];
```

범위 밖 접근은 시뮬레이션에서 즉시 잡는다:

```verilog
// synthesis translate_off
always @(posedge clk)
    if (we && waddr >= NREG)
        $fatal(1, "vreg %0d out of range (NREG=%0d)", waddr, NREG);
// synthesis translate_on
```

어셈블러에도 같은 검사를 둔다. 인코딩은 8개를 지목할 수 있으나 구현이 2개라는 불일치는 명시적으로 잡혀야 한다.

**VLEN = 256 bit 고정.** 원소 개수가 아니라 비트 폭으로 정의한다. 나중에 INT16을 지원해도 스펙이 바뀌지 않는다 (INT8이면 32개, INT16이면 16개).

### lane 은닉 조항

> lane 수는 마이크로아키텍처 파라미터이며 ISA에 노출되지 않는다. VLEN이 동일한 한, 같은 바이너리가 모든 lane 구성에서 동일한 결과를 산출한다. `VDOT`은 lane 수에 관계없이 VLEN 전체를 처리하며, 소요 사이클만 달라진다.

이 조항이 Tier 2 lane sweep 실험의 유효성을 보장한다. lane을 바꿀 때 바이너리가 바뀌면 하드웨어 효과와 컴파일 효과가 분리되지 않는다.

---

## 2. 명령어

### v1 구현 (5개)

| opcode | 명령어 | 동작 |
|---|---|---|
| `0x1` | `VLD vd, imm` | `v[vd] ← mem[imm : imm+32]` |
| `0x3` | `ACC_CLR ad` | `acc[ad] ← 0` |
| `0x4` | `VDOT ad, vs1, vs2` | `acc[ad] += Σ(v[vs1]ᵢ × v[vs2]ᵢ)`, i=0..31 |
| `0x5` | `ACC_ST ad, imm` | `mem[imm : imm+4] ← acc[ad]` |
| `0x6` | `HALT` | `done ← 1`, PC 정지 |

`VDOT`은 곱셈 + 리덕션 + 누적을 한 명령으로 융합한다. Spatz는 `vmul` + `vredsum`으로 분리하지만, 본 설계는 INT8 행렬곱만 대상으로 하므로 항상 이 순서로 쓰인다.

`vs1`, `vs2`는 변경되지 않는다. 따라서 입력 벡터 하나를 로드해 여러 가중치와 반복 내적할 수 있다.

### 예약 (미구현)

| opcode | 명령어 | 도입 시점 | 사유 |
|---|---|---|---|
| `0x0` | `NOP` | — | 빈 메모리(0)가 안전하게 해석되도록 예약 |
| `0x2` | `VST vd, imm` | Tier 1.5 | requantize된 INT8 중간 결과 저장 |
| `0x7` | `VRELU vd, vs` | Tier 1.5 | 2층 모델의 비선형성 |
| `0x8` | `VREQUANT vd, ad, imm` | Tier 1.5 | INT32 → INT8, `(acc × M) >> S` |
| `0x9` | `ADDI sd, ss, imm` | Tier 2 | 루프 주소 계산 |
| `0xA` | `BNE ss1, ss2, imm` | Tier 2 | 루프 제어 |
| `0xB` | `VDOT_FUSED` | Tier 2 | fusion 실험용 |
| `0xC`–`0xF` | — | — | 미할당 |

어셈블러는 미구현 명령어를 만나면 명시적으로 에러를 낸다.

---

## 3. 인코딩

32비트 고정 길이.

```
 31    28 27  25 24  22 21  19 18                    0
┌────────┬──────┬──────┬──────┬──────────────────────┐
│ opcode │  rd  │ rs1  │ rs2  │         imm          │
│  4bit  │ 3bit │ 3bit │ 3bit │        19bit         │
└────────┴──────┴──────┴──────┴──────────────────────┘
```

| 명령어 | rd | rs1 | rs2 | imm |
|---|---|---|---|---|
| `VLD` | v | — | — | 주소 |
| `ACC_CLR` | acc | — | — | — |
| `VDOT` | acc | v | v | — |
| `ACC_ST` | acc | — | — | 주소 |
| `HALT` | — | — | — | — |

필드가 남는 것은 의도적이다. 형식을 통일하면 디코더가 단순해지고, 명령어 추가 시 자리가 있다.

**opcode 4비트인 이유**: 3비트(8개)로 조이면 Tier 1.5·2에서 11개가 되어 인코딩을 다시 짜야 한다. 그러면 이전 측정값과 비교가 불가능해진다.

---

## 4. 양자화 계약

```
방식      symmetric per-tensor, zero-point = 0
곱셈      INT8 × INT8 → INT16
누산      INT32
포화      [-128, 127] 클램프
반올림    round-half-away-from-zero
엔디안    little-endian
```

**반올림 방식을 명시하는 것이 이 절의 핵심이다.** numpy 기본값은 half-to-even이므로, golden model에서 명시적으로 half-away를 구현하지 않으면 RTL과 ±1씩 어긋난다.

오버플로 여유 확인: `64 × 127² = 1,032,256` ≪ `2³¹`. K=64에서 INT32 누산은 안전하다.

Requantize (Tier 1.5): `clamp((acc × M) >> S, -128, 127)`. `M`(INT32), `S`(0–31)는 오프라인 계산 상수.

---

## 5. 메모리

```
0x00000 – 0x0FFFF   입력 활성화
0x10000 – 0x2FFFF   가중치
0x30000 – 0x3FFFF   출력
```

- `VLD` / `VST` 주소는 **32바이트 정렬 필수**. 위반 시 동작 미정의
- 뱅킹 구조는 ISA에 노출하지 않는다. 하드웨어가 정렬 요구사항 뒤에 숨긴다
- v1은 단일 포트. Tier 2에서 lane 8 초과 시 뱅킹 도입

정렬 제약을 v1부터 거는 이유는 나중에 뱅킹을 넣을 때 ISA를 고치지 않기 위해서다.

---

## 6. 프로그램 예시

길이 64 INT8 내적 (Tier 0):

```asm
ACC_CLR acc0
VLD     v0, 0x00000     ; A 앞 32개
VLD     v1, 0x10000     ; B 앞 32개
VDOT    acc0, v0, v1
VLD     v0, 0x00020     ; A 뒤 32개
VLD     v1, 0x10020     ; B 뒤 32개
VDOT    acc0, v0, v1     ; 누적
ACC_ST  acc0, 0x30000
HALT
```

K=64 > VLEN(32개)이므로 두 번에 나눠 누적한다. `VDOT`이 `+=`인 이유가 여기 있다.

---

## 7. Non-goals

명시적으로 구현하지 않는 것들:

- **분기·스칼라 연산** (v1) — 프로그램을 완전 언롤한다. Tier 2에서 명령어 메모리가 부족해질 때 도입
- **시스톨릭 배열** — lane 간 데이터 전달 없음. 따라서 skew logic도 불필요
- **Conv 레이어** — im2col vs 직접 dataflow는 별도 설계 결정이며 스코프 밖
- **Softmax / LayerNorm** — 나눗셈·지수 연산 필요. 수치 근사 구현은 별도 프로젝트
- **부동소수점** — FPGA 리소스 및 비트 단위 검증 가능성 문제
- **DDR 접근** — BRAM만 사용. 호스트(ARM)가 데이터를 적재
- **범용성** — 단일 도메인 특화가 설계 의도

---

## 8. 검토 중인 결정

| 항목 | 선택지 | 현재 안 |
|---|---|---|
| VLEN | 128 vs 256 bit | 256 (lane 1 시작이면 128도 고려) |
| 누산기 | 별도 레지스터 vs 벡터 레지스터 재해석 | 별도 |
| `VDOT` | 고정 길이 vs len 인자 | 고정 |
| `ACC_CLR` | 별도 명령 vs `VDOT_SET`/`VDOT_ACC` 분리 | 별도 (사이클보다 디코더 단순성 우선) |

각 결정은 ADR로 기록한다.

---

## 9. 단일 진실 원천

명령어 정의는 `isa.yaml` 하나에서 관리하고, 다음을 생성한다:

- 어셈블러 인코더
- Verilog 디코더 (case문)
- 시뮬레이터 디코더
- 본 문서의 명령어 표

```yaml
vlen_bits: 256

registers:
  vreg: {encoded: 8, impl: 2}     # Tier 0
  acc:  {encoded: 8, impl: 1}
  sreg: {encoded: 4, impl: 0}

instructions:
  - {opcode: 0x1, name: VLD,     fields: [rd, imm],      impl: true}
  - {opcode: 0x2, name: VST,     fields: [rd, imm],      impl: false, tier: 1.5}
  - {opcode: 0x3, name: ACC_CLR, fields: [rd],           impl: true}
  - {opcode: 0x4, name: VDOT,    fields: [rd, rs1, rs2], impl: true}
  - {opcode: 0x5, name: ACC_ST,  fields: [rd, imm],      impl: true}
  - {opcode: 0x6, name: HALT,    fields: [],             impl: true}
```

세 곳을 손으로 동기화하면 반드시 어긋나며, 그 버그는 파형에서 찾게 된다.
