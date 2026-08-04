# Experiment 001: Handwritten Assembly Vertical Slice

## Question

Dot Product를 수행하는 최소 ISA와 실행 경로는 무엇인가?

## Prediction

VLOAD, VMAC, accumulator clear/store, HALT만으로 첫 end-to-end 실행이 가능할 것이다.

## Setup

- Workload: INT8 Dot
- Vector length:
- Lane count:
- Input:
- Expected output:

## Steps

1. memory map 작성
2. handwritten assembly 작성
3. assembler 실행
4. functional simulator 실행
5. NumPy 결과 비교
6. instruction trace 저장

## Result

TBD

## Learning

- instruction semantics
- memory address
- accumulator lifecycle
- vertical slice의 실제 최소 범위
