// Synchronous single-port instruction memory, 1-cycle read latency
// (addr presented one cycle, dout valid the next -- matches BRAM timing).
module imem #(
    parameter WORDS     = 512,
    parameter INIT_FILE = ""
)(
    input             clk,
    input      [15:0] addr,
    output reg [31:0] dout
);
    reg [31:0] mem [0:WORDS-1];

    initial if (INIT_FILE != "") $readmemh(INIT_FILE, mem);

    always @(posedge clk)
        dout <= mem[addr];
endmodule
