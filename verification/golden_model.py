#!/usr/bin/env python3
"""Tiny-Vector-AI golden reference model.

Executes an assembly program in software to produce reference outputs that the
RTL simulation is checked against.

Usage:
    python3 verification/golden_model.py --program sw_toolchain/test_programs/dot_product.asm

Status: skeleton.
"""

import argparse
import sys


def run_program(program_path: str) -> None:
    """Load and execute a .asm program with the reference semantics."""
    # TODO: parse the program (or its .hex) and emulate the ISA per
    #       docs/isa_spec.md, then emit reference results.
    raise NotImplementedError(f"golden model not implemented for {program_path}")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Tiny-Vector-AI golden model")
    parser.add_argument("--program", required=True, help="input .asm program")
    args = parser.parse_args(argv)
    run_program(args.program)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
