// Negative test: VLD v0, 0x00001 is not 32B-aligned. This must be caught by
// tiny_npu_core's own $fatal (isa_spec_1.md #5 alignment requirement). If
// that guard is ever removed or broken, the timeout below fires our own
// $fatal instead, so this test fails loudly either way rather than passing
// silently.
`timescale 1ns/1ps

module tb_align_violation;
    reg clk = 0;
    reg rst;
    wire done;

    tiny_npu_core #(
        .NVREG(2), .ELEMS(32), .NACC(1),
        .IMEM_WORDS(2), .DMEM_BYTES(262144),
        .IMEM_INIT("verification/prog/bad_align.hex")
    ) dut (
        .clk(clk), .rst(rst), .done(done)
    );

    always #5 clk = ~clk;

    integer timeout;

    initial begin
        rst = 1;
        @(posedge clk); @(posedge clk);
        rst = 0;

        timeout = 0;
        while (!done && timeout < 200) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (done)
            $fatal(1, "REGRESSION: misaligned VLD (imm=0x00001) was not caught -- alignment check is broken");
        else
            $fatal(1, "REGRESSION: neither the alignment $fatal nor HALT fired within timeout");
    end
endmodule
