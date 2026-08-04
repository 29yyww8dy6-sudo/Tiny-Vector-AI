// Self-checking testbench for the Tier 0 K=64 INT8 dot-product program
// (isa_spec_1.md #6). Loads A/B directly into dmem via hierarchical
// reference (host-load over AXI is Tier 2/M5 scope, not needed yet),
// computes the expected result with a behavioral signed sum, and compares
// it against what the RTL wrote to the output region after HALT.
//
// Two cases:
//   mode 0 - pseudo-random INT8 pairs
//   mode 1 - worst case (-128 * -128) x64, exercising the overflow-margin
//            claim in isa_spec_1.md #4 (64 * 127^2 << 2^31)
`timescale 1ns/1ps

module tb_tiny_npu;
    localparam ADDR_A   = 19'h00000;
    localparam ADDR_B   = 19'h10000;
    localparam ADDR_OUT = 19'h30000;
    localparam K        = 64;

    reg clk = 0;
    reg rst;
    wire done;

    tiny_npu_core #(
        .NVREG(2), .ELEMS(32), .NACC(1),
        .IMEM_WORDS(9), .DMEM_BYTES(262144),
        .IMEM_INIT("verification/prog/dot64.hex")
    ) dut (
        .clk(clk), .rst(rst), .done(done)
    );

    always #5 clk = ~clk;

    integer i;
    integer errors = 0;
    integer timeout;
    reg [31:0] seed = 32'hC0FFEE;
    reg signed [7:0]  a_byte, b_byte;
    reg signed [31:0] expected;
    reg [31:0] got;

    task load_case(input integer mode);
        begin
            expected = 32'sd0;
            for (i = 0; i < K; i = i + 1) begin
                if (mode == 0) begin
                    a_byte = $random(seed);
                    b_byte = $random(seed);
                end else begin
                    a_byte = -8'sd128;
                    b_byte = -8'sd128;
                end
                dut.dmem_i.mem[ADDR_A + i] = a_byte;
                dut.dmem_i.mem[ADDR_B + i] = b_byte;
                expected = expected + a_byte * b_byte;
            end
            // poison the output region so a silent no-op can't look like a pass
            for (i = 0; i < 4; i = i + 1)
                dut.dmem_i.mem[ADDR_OUT + i] = 8'hDE;
        end
    endtask

    task run_case(input integer mode);
        begin
            load_case(mode);

            rst = 1;
            @(posedge clk); @(posedge clk);
            rst = 0;

            timeout = 0;
            while (!done && timeout < 2000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (!done) begin
                $display("[FAIL] mode=%0d timed out waiting for HALT", mode);
                errors = errors + 1;
            end else begin
                got = {dut.dmem_i.mem[ADDR_OUT+3], dut.dmem_i.mem[ADDR_OUT+2],
                       dut.dmem_i.mem[ADDR_OUT+1], dut.dmem_i.mem[ADDR_OUT+0]};
                if ($signed(got) === expected) begin
                    $display("[PASS] mode=%0d expected=%0d got=%0d", mode, expected, $signed(got));
                end else begin
                    $display("[FAIL] mode=%0d expected=%0d got=%0d", mode, expected, $signed(got));
                    errors = errors + 1;
                end
            end
        end
    endtask

    initial begin
        $dumpfile("build/tb_tiny_npu.vcd");
        $dumpvars(0, tb_tiny_npu);

        run_case(0); // pseudo-random
        run_case(1); // overflow-margin worst case

        if (errors == 0) $display("ALL TESTS PASSED");
        else              $display("%0d TEST(S) FAILED", errors);

        $finish;
    end
endmodule
