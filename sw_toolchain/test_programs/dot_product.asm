# dot_product.asm
# INT8 dot product test program for Tiny-Vector-AI.
# Loads two vectors, computes their dot product, stores the result.
#
# Status: placeholder — addresses/registers to be finalized with the ISA.

VLD  v1, 0x00      # load vector A from data memory
VLD  v2, 0x10      # load vector B from data memory
VDOT v3, v1, v2    # v3 = dot(A, B) with 32-bit accumulation
VST  v3, 0x20      # store result
HALT
