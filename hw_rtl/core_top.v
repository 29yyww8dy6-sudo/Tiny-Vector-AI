// core_top.v
// Top-level integration of the Tiny-Vector-AI accelerator.
// Connects fetch/decode, vector register file, SIMD MAC array, and memory.
//
// Status: skeleton — ports and internal wiring to be defined.

`default_nettype none

module core_top (
    input  wire clk,
    input  wire rst_n,
    output wire halted
);

    // TODO: instantiate fetch_decode, vector_regfile, simd_mac_array, memory_ctrl.

    assign halted = 1'b0;

endmodule

`default_nettype wire
