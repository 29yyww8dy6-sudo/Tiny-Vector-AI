# Tiny-Vector-AI

Tiny-Vector-AI is a minimal RVV-inspired INT8 vector accelerator and toolchain project.

The goal of this project is to demonstrate hardware/software co-design by building the full path from a custom vector instruction set to a Verilog RTL datapath. Instead of treating the accelerator as a black box, this project exposes how human-readable assembly instructions are translated into machine code, decoded by hardware, and executed by a SIMD MAC array for quantized AI inference workloads.

The initial target workload is INT8 dot product and small GEMM, which are core operations in many quantized neural network inference pipelines.

## Description

This project focuses on three connected layers:

- A custom vector ISA inspired by the philosophy of the RISC-V Vector Extension
- A lightweight Python assembler that converts vector assembly into 32-bit machine code
- A synthesizable Verilog accelerator containing fetch/decode logic, vector registers, BRAM-backed memory, and an INT8 SIMD MAC datapath

The long-term deployment target is the EBAZ4205 Zynq-7010 board, where the ARM processing system can control the programmable logic accelerator through AXI.

## Architecture

```text
Assembly Program (.asm)
        |
        v
Python Assembler
        |
        v
Machine Code (.hex)
        |
        v
Instruction Memory / BRAM
        |
        v
Fetch & Decode
        |
        v
Vector Register File
        |
        v
SIMD INT8 MAC Array
        |
        v
Result Memory
```

## Features

- Custom 32-bit vector instruction format
- Python-based assembler for `.asm` to `.hex` translation
- Verilog fetch and decode unit
- Vector register file for SIMD execution
- INT8 multiply-accumulate datapath with 32-bit accumulation
- BRAM-based instruction and data scratchpad memory
- Self-checking RTL testbench flow
- Python golden model for correctness comparison
- Planned FPGA deployment on the EBAZ4205 Zynq-7010 board

## Instruction Set Architecture

The first version of the ISA is intentionally small. The goal is to make the complete software-to-hardware execution path easy to verify before expanding the instruction set.

| Instruction | Description |
| --- | --- |
| `VLD vd, addr` | Load a vector from data memory into a vector register |
| `VST vs, addr` | Store a vector register into data memory |
| `VADD vd, vs1, vs2` | Add two vector registers element by element |
| `VMUL vd, vs1, vs2` | Multiply two INT8 vector registers element by element |
| `VDOT vd, vs1, vs2` | Compute an INT8 dot product with 32-bit accumulation |
| `HALT` | Stop program execution |

The exact instruction encoding will be documented in `docs/isa_spec.md`.

## Repository Structure

```text
tiny-vector-ai/
|
|-- README.md
|-- docs/
|   |-- isa_spec.md
|   |-- architecture.md
|   `-- performance_notes.md
|
|-- sw_toolchain/
|   |-- assembler.py
|   |-- quantizer.py
|   `-- test_programs/
|       |-- dot_product.asm
|       `-- gemm_small.asm
|
|-- hw_rtl/
|   |-- core_top.v
|   |-- fetch_decode.v
|   |-- vector_regfile.v
|   |-- simd_mac_array.v
|   `-- memory_ctrl.v
|
|-- verification/
|   |-- tb_core_top.v
|   |-- tb_mac_array.v
|   |-- golden_model.py
|   `-- waveforms/
|
`-- deploy/
    |-- constraints/
    `-- host_app/
```

## Instructions

The following commands describe the intended development flow. Exact commands may change as the implementation evolves.

### 1. Assemble a test program

```bash
python3 sw_toolchain/assembler.py \
  sw_toolchain/test_programs/dot_product.asm \
  -o build/program.hex
```

### 2. Run RTL simulation

```bash
iverilog -o build/tb_core \
  verification/tb_core_top.v \
  hw_rtl/*.v

vvp build/tb_core
```

### 3. Run the Python golden model

```bash
python3 verification/golden_model.py \
  --program sw_toolchain/test_programs/dot_product.asm
```

### 4. FPGA synthesis

The planned FPGA target is the EBAZ4205 board with a Xilinx Zynq-7010 device.

The initial FPGA milestone is to synthesize the core, inspect LUT/FF/BRAM/DSP utilization, and verify timing. AXI integration with the ARM processing system will be added after the standalone RTL core is verified.

## Verification

Correctness will be checked using both RTL simulation and a Python reference model.

The intended verification flow is:

1. Generate `.hex` machine code using the assembler.
2. Load the instruction image into the RTL instruction memory.
3. Initialize input vectors or matrix tiles in data memory.
4. Execute the program cycle by cycle in simulation.
5. Compare the RTL output against the Python golden model.
6. Inspect waveforms for instruction decode, register access, MAC accumulation, and memory writes.

## Current Status

- [ ] ISA specification draft
- [ ] Python assembler
- [ ] INT8 dot-product test program
- [ ] Vector register file
- [ ] SIMD MAC array
- [ ] Fetch/decode unit
- [ ] Core-level RTL simulation
- [ ] Python golden model
- [ ] Vivado synthesis for Zynq-7010
- [ ] EBAZ4205 board deployment
- [ ] AXI-based PS-PL integration

## Roadmap

1. Define the first 32-bit instruction encoding.
2. Implement the Python assembler.
3. Build the vector register file and INT8 SIMD MAC array.
4. Run an INT8 dot product program in RTL simulation.
5. Extend the datapath to small tiled GEMM.
6. Add a Python golden model and self-checking testbenches.
7. Synthesize the design for the Zynq-7010 target.
8. Integrate the accelerator with the ARM processing system through AXI.
9. Run a small quantized inference demo on the EBAZ4205 board.

## Resources

- David A. Patterson and John L. Hennessy, *Computer Organization and Design: The Hardware/Software Interface*
- David A. Patterson and John L. Hennessy, *Computer Architecture: A Quantitative Approach*
- RISC-V International, *The RISC-V Vector Extension Specification*
- RISC-V International, *The RISC-V Instruction Set Manual*
- AMD Xilinx, *Zynq-7000 SoC Technical Reference Manual*
- AMD Xilinx, *7 Series DSP48E1 Slice User Guide*
- AMD Xilinx, *Vivado Design Suite User Guide*
- AMD Xilinx, *AXI Reference Guide*

## License

This project is intended to be released under the MIT License.
