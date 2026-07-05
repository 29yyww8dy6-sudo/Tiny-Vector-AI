# gemm_small.asm
# Small tiled INT8 GEMM test program for Tiny-Vector-AI.
#
# Status: placeholder — tiling scheme and addresses to be finalized.

VLD  v1, 0x00      # load matrix A tile row
VLD  v2, 0x10      # load matrix B tile column
VDOT v3, v1, v2    # partial product accumulate
VST  v3, 0x20      # store result tile element
HALT
