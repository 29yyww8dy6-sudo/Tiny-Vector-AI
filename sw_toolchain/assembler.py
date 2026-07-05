#!/usr/bin/env python3
"""Tiny-Vector-AI assembler.

Converts vector assembly (.asm) into 32-bit machine code (.hex).

Usage:
    python3 sw_toolchain/assembler.py <input.asm> -o build/program.hex

Status: skeleton — encoding not yet implemented. See docs/isa_spec.md.
"""

import argparse
import sys


def assemble(source_path: str) -> list[int]:
    """Parse an .asm file and return a list of 32-bit instruction words."""
    words: list[int] = []
    with open(source_path, "r", encoding="utf-8") as f:
        for lineno, raw in enumerate(f, start=1):
            line = raw.split("#", 1)[0].strip()
            if not line:
                continue
            # TODO: tokenize and encode the instruction per docs/isa_spec.md.
            raise NotImplementedError(
                f"{source_path}:{lineno}: encoding not implemented yet"
            )
    return words


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Tiny-Vector-AI assembler")
    parser.add_argument("input", help="input .asm file")
    parser.add_argument("-o", "--output", required=True, help="output .hex file")
    args = parser.parse_args(argv)

    words = assemble(args.input)
    with open(args.output, "w", encoding="utf-8") as f:
        for w in words:
            f.write(f"{w:08x}\n")
    print(f"wrote {len(words)} words to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
