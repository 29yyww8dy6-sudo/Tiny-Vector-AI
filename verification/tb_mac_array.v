// tb_mac_array.v
// Unit testbench for the INT8 SIMD MAC array.
//
// Status: skeleton.

`timescale 1ns / 1ps
`default_nettype none

module tb_mac_array;

    reg clk = 0;
    reg rst_n = 0;

    always #5 clk = ~clk;

    simd_mac_array dut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    initial begin
        $dumpfile("verification/waveforms/tb_mac_array.vcd");
        $dumpvars(0, tb_mac_array);

        rst_n = 0;
        #20 rst_n = 1;

        // TODO: drive INT8 operands and check 32-bit accumulation.

        #100;
        $display("tb_mac_array: skeleton run complete");
        $finish;
    end

endmodule

`default_nettype wire
