# Experiment 003: 일반 명령 조합 vs Fused DOT

## Question

전용 DOT instruction이 전체 stack에서 가치가 있는가?

## Prediction

instruction 수와 control overhead는 줄지만 decoder/datapath 및 verification 복잡도가 증가한다.

## Compare

### General

```text
VLOAD
VLOAD
VMAC
...
```

### Fused

```text
DOT address_a, address_b, length
```

## Measure

- code size
- instruction count
- cycle
- compiler complexity
- RTL area
- timing
- test count
- error/edge case

## Result

TBD
