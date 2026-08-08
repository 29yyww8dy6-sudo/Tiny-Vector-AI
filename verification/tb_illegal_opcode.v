// Negative test: opcode 0xf is unimplemented and must terminate simulation.
`timescale 1ns/1ps

module tb_illegal_opcode;
    reg clk = 0;
    reg rst;
    wire done;

    tiny_npu_core #(
        .NVREG(2), .ELEMS(32), .NACC(1), .IMEM_WORDS(1)
    ) dut (.clk(clk), .rst(rst), .done(done));

    always #5 clk = ~clk;

    initial begin
        // Keep this negative program self-contained instead of adding a
        // generated .hex artifact to the repository.
        dut.imem_i.mem[0] = 32'hf0000000;
        rst = 1;
        @(posedge clk); @(posedge clk);
        rst = 0;
        repeat (200) @(posedge clk);
        $fatal(1, "REGRESSION: illegal opcode did not trigger an error");
    end
endmodule
