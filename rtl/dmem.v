// Tier 0 data memory: one synchronous single port, byte addressed, shared by
// VLD's 32B-wide load and ACC_ST's 4B-wide store (never concurrent per
// isa_spec_1.md #5 -- v1 is single-port and hides banking behind alignment).
// 1-cycle latency: en/addr held one cycle, result registered the next.
module dmem #(
    parameter BYTES = 262144  // 0x40000, matches the v1 memory map
)(
    input                 clk,
    input                 ld_en,
    input      [18:0]     ld_addr,
    output reg [255:0]    ld_data,

    input                 st_en,
    input      [18:0]     st_addr,
    input      [31:0]     st_data
);
    reg [7:0] mem [0:BYTES-1];

    integer i;
    always @(posedge clk) begin
        if (ld_en)
            for (i = 0; i < 32; i = i + 1)
                ld_data[i*8 +: 8] <= mem[ld_addr + i];
        if (st_en)
            for (i = 0; i < 4; i = i + 1)
                mem[st_addr + i] <= st_data[i*8 +: 8];
    end
endmodule
