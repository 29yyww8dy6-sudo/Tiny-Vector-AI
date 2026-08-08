// All lane variants execute the same Tier 0 program and must be bit-exact.
`timescale 1ns/1ps

module tb_lane_sweep;
    localparam ADDR_A   = 19'h00000;
    localparam ADDR_B   = 19'h10000;
    localparam ADDR_OUT = 19'h30000;
    localparam K = 64;

    reg clk = 0;
    reg rst;
    wire done1, done4, done8, done16;
    integer i, cycles, errors;
    integer cycle1, cycle4, cycle8, cycle16;
    reg signed [7:0] a_byte, b_byte;
    reg signed [31:0] expected;
    reg [31:0] got1, got4, got8, got16;
    reg [31:0] seed = 32'h1A2B3C4D;

    tiny_npu_core #(.LANES(1),  .IMEM_WORDS(9), .IMEM_INIT("verification/prog/dot64.hex")) dut1  (.clk(clk), .rst(rst), .done(done1));
    tiny_npu_core #(.LANES(4),  .IMEM_WORDS(9), .IMEM_INIT("verification/prog/dot64.hex")) dut4  (.clk(clk), .rst(rst), .done(done4));
    tiny_npu_core #(.LANES(8),  .IMEM_WORDS(9), .IMEM_INIT("verification/prog/dot64.hex")) dut8  (.clk(clk), .rst(rst), .done(done8));
    tiny_npu_core #(.LANES(16), .IMEM_WORDS(9), .IMEM_INIT("verification/prog/dot64.hex")) dut16 (.clk(clk), .rst(rst), .done(done16));

    always #5 clk = ~clk;

    initial begin
        expected = 0;
        for (i = 0; i < K; i = i + 1) begin
            a_byte = $random(seed);
            b_byte = $random(seed);
            expected = expected + a_byte * b_byte;
            dut1.dmem_i.mem[ADDR_A+i] = a_byte;   dut4.dmem_i.mem[ADDR_A+i] = a_byte;
            dut8.dmem_i.mem[ADDR_A+i] = a_byte;   dut16.dmem_i.mem[ADDR_A+i] = a_byte;
            dut1.dmem_i.mem[ADDR_B+i] = b_byte;   dut4.dmem_i.mem[ADDR_B+i] = b_byte;
            dut8.dmem_i.mem[ADDR_B+i] = b_byte;   dut16.dmem_i.mem[ADDR_B+i] = b_byte;
        end
        rst = 1;
        @(posedge clk); @(posedge clk);
        rst = 0;
        cycles = 0; cycle1 = 0; cycle4 = 0; cycle8 = 0; cycle16 = 0;
        while (!(done1 && done4 && done8 && done16) && cycles < 2000) begin
            @(posedge clk); cycles = cycles + 1;
            if (done1  && cycle1  == 0) cycle1  = cycles;
            if (done4  && cycle4  == 0) cycle4  = cycles;
            if (done8  && cycle8  == 0) cycle8  = cycles;
            if (done16 && cycle16 == 0) cycle16 = cycles;
        end
        got1  = {dut1.dmem_i.mem[ADDR_OUT+3],  dut1.dmem_i.mem[ADDR_OUT+2],  dut1.dmem_i.mem[ADDR_OUT+1],  dut1.dmem_i.mem[ADDR_OUT]};
        got4  = {dut4.dmem_i.mem[ADDR_OUT+3],  dut4.dmem_i.mem[ADDR_OUT+2],  dut4.dmem_i.mem[ADDR_OUT+1],  dut4.dmem_i.mem[ADDR_OUT]};
        got8  = {dut8.dmem_i.mem[ADDR_OUT+3],  dut8.dmem_i.mem[ADDR_OUT+2],  dut8.dmem_i.mem[ADDR_OUT+1],  dut8.dmem_i.mem[ADDR_OUT]};
        got16 = {dut16.dmem_i.mem[ADDR_OUT+3], dut16.dmem_i.mem[ADDR_OUT+2], dut16.dmem_i.mem[ADDR_OUT+1], dut16.dmem_i.mem[ADDR_OUT]};
        errors = (cycle1 == 0 || cycle4 == 0 || cycle8 == 0 || cycle16 == 0);
        if ($signed(got1) !== expected || $signed(got4) !== expected || $signed(got8) !== expected || $signed(got16) !== expected)
            errors = errors + 1;
        if (!(cycle1 > cycle4 && cycle4 > cycle8 && cycle8 > cycle16))
            errors = errors + 1;
        $display("[LANES] expected=%0d cycles: 1=%0d 4=%0d 8=%0d 16=%0d", expected, cycle1, cycle4, cycle8, cycle16);
        if (errors != 0) $fatal(1, "lane sweep failed (%0d errors)", errors);
        $display("LANE SWEEP PASSED");
        $finish;
    end
endmodule
