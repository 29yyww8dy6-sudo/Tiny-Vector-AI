// Tier 0 accumulator file. clr implements ACC_CLR; !clr accumulates wdata
// (a signed delta) into accs[addr], which is exactly VDOT's "+=" semantics
// applied one lane-product per cycle by tiny_npu_core.
module accfile #(
    parameter NACC = 1
)(
    input             clk,
    input             we,
    input             clr,
    input      [2:0]  addr,
    input      [31:0] wdata,
    output     [31:0] rdata
);
    reg [31:0] accs [0:NACC-1];

    assign rdata = accs[addr];

    always @(posedge clk)
        if (we) begin
            if (clr) accs[addr] <= 32'd0;
            else     accs[addr] <= accs[addr] + wdata;
        end

// synthesis translate_off
    always @(posedge clk)
        if (we && addr >= NACC)
            $fatal(1, "acc %0d out of range (NACC=%0d)", addr, NACC);
// synthesis translate_on
endmodule
