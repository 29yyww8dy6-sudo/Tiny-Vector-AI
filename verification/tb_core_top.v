// tb_core_top.v
// Self-checking testbench for the Tiny-Vector-AI core.
//
// Status: skeleton — drives clock/reset and waits for halt.

`timescale 1ns / 1ps
`default_nettype none

module tb_core_top;

    reg  clk = 0;
    reg  rst_n = 0;
    wire halted;

    always #5 clk = ~clk;   // 100 MHz

    core_top dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .halted (halted)
    );

    initial begin
        $dumpfile("verification/waveforms/tb_core_top.vcd");
        $dumpvars(0, tb_core_top);

        rst_n = 0;
        #20 rst_n = 1;

        // TODO: load program image, initialize data memory, check results
        //       against verification/golden_model.py.

        #200;
        $display("tb_core_top: skeleton run complete (halted=%b)", halted);
        $finish;
    end

endmodule

`default_nettype wire
