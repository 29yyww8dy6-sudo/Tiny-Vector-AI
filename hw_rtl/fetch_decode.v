// fetch_decode.v
// Instruction fetch and decode unit for Tiny-Vector-AI.
// Reads 32-bit instructions and produces control signals per docs/isa_spec.md.
//
// Status: skeleton.

`default_nettype none

module fetch_decode (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] instr,
    output wire [5:0]  opcode
);

    assign opcode = instr[31:26];

    // TODO: decode vd/vs1/vs2/imm fields and drive datapath control.

endmodule

`default_nettype wire
