#!/usr/bin/env python3
"""Tiny-Vector-AI INT8 quantizer.

Utilities to quantize floating-point vectors/matrices to INT8 for the
accelerator's data memory.

Status: skeleton.
"""


def quantize_int8(values, scale: float):
    """Quantize an iterable of floats to INT8 using a symmetric scale.

    TODO: implement clamping to [-128, 127] and rounding policy.
    """
    raise NotImplementedError


if __name__ == "__main__":
    print("quantizer: skeleton — not yet implemented")
