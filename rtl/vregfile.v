// Tier 0 vector register file. NREG is an implementation choice, independent
// of the 3-bit encoding field (which can address up to 8). Out-of-range
// writes are fatal in simulation -- see isa_spec_1.md #1 "구현 범위".
module vregfile #(
    parameter NREG  = 2,
    parameter ELEMS = 32
)(
    input                       clk,
    input                       we,
    input      [2:0]            waddr,
    input      [ELEMS*8-1:0]    wdata,
    input      [2:0]            raddr1,
    input      [2:0]            raddr2,
    output     [ELEMS*8-1:0]    rdata1,
    output     [ELEMS*8-1:0]    rdata2
);
    reg [ELEMS*8-1:0] regs [0:NREG-1];

    assign rdata1 = regs[raddr1];
    assign rdata2 = regs[raddr2];

    always @(posedge clk)
        if (we) regs[waddr] <= wdata;

// synthesis translate_off
    always @(posedge clk)
        if (we && waddr >= NREG)
            $fatal(1, "vreg %0d out of range (NREG=%0d)", waddr, NREG);
// synthesis translate_on
endmodule
