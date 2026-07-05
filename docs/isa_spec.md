# Tiny-Vector-AI ISA Specification

Status: **draft**

This document defines the 32-bit vector instruction encoding for Tiny-Vector-AI.

## Instruction Summary

| Instruction | Description |
| --- | --- |
| `VLD vd, addr`      | Load a vector from data memory into a vector register |
| `VST vs, addr`      | Store a vector register into data memory |
| `VADD vd, vs1, vs2` | Add two vector registers element by element |
| `VMUL vd, vs1, vs2` | Multiply two INT8 vector registers element by element |
| `VDOT vd, vs1, vs2` | Compute an INT8 dot product with 32-bit accumulation |
| `HALT`              | Stop program execution |

## 32-bit Encoding (draft)

```text
 31        26 25     21 20     16 15     11 10                0
+-----------+---------+---------+---------+-------------------+
|  opcode   |   vd    |   vs1   |   vs2   |   imm / addr      |
+-----------+---------+---------+---------+-------------------+
```

TODO: finalize opcode map, field widths, and immediate/address handling.

## Opcode Map (draft)

| Mnemonic | opcode[31:26] |
| --- | --- |
| VLD  | `000000` |
| VST  | `000001` |
| VADD | `000010` |
| VMUL | `000011` |
| VDOT | `000100` |
| HALT | `111111` |
