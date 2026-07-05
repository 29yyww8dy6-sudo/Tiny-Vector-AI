# Tiny-Vector-AI Architecture

Status: **draft**

## Datapath Overview

```text
Instruction Memory / BRAM
        |
        v
Fetch & Decode  (hw_rtl/fetch_decode.v)
        |
        v
Vector Register File  (hw_rtl/vector_regfile.v)
        |
        v
SIMD INT8 MAC Array  (hw_rtl/simd_mac_array.v)
        |
        v
Result Memory  (hw_rtl/memory_ctrl.v)
```

## Modules

- `core_top.v` — top-level integration of all units
- `fetch_decode.v` — instruction fetch and decode
- `vector_regfile.v` — SIMD vector register file
- `simd_mac_array.v` — INT8 multiply-accumulate array with 32-bit accumulation
- `memory_ctrl.v` — BRAM-backed instruction and data scratchpad

TODO: document register count, vector length, and memory map.
