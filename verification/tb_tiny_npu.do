# ModelSim/Questa waveform run for the Tier 0 K=64 dot-product testbench.
#
# Run from the PROJECT ROOT (not verification/), because $readmemh in
# rtl/imem.v uses the path "verification/prog/dot64.hex" relative to the
# simulator's working directory:
#
#   vsim -do verification/tb_tiny_npu.do
#
# or from inside the ModelSim GUI console (cwd = project root):
#   do verification/tb_tiny_npu.do

vlib work

vlog -work work \
    rtl/imem.v \
    rtl/dmem.v \
    rtl/vregfile.v \
    rtl/accfile.v \
    rtl/tiny_npu_core.v \
    verification/tb_tiny_npu.v

# +acc keeps full visibility into internal DUT signals (state, pc, vreg,
# acc, lane_i, ...) for the wave window -- without it, optimization can
# hide anything not directly referenced by name outside the DUT.
vsim -voptargs=+acc work.tb_tiny_npu

add wave -divider "control"
add wave -radix unsigned /tb_tiny_npu/dut/state
add wave -radix unsigned /tb_tiny_npu/dut/pc
add wave -radix hex      /tb_tiny_npu/dut/instr
add wave                 /tb_tiny_npu/done

add wave -divider "vdot datapath (lane=1)"
add wave -radix unsigned /tb_tiny_npu/dut/lane_i
add wave -radix decimal  /tb_tiny_npu/dut/a_elem
add wave -radix decimal  /tb_tiny_npu/dut/b_elem
add wave -radix decimal  /tb_tiny_npu/dut/mac_term
add wave -radix decimal  /tb_tiny_npu/dut/accfile_i/accs

add wave -divider "memory handshake"
add wave /tb_tiny_npu/dut/dmem_ld_en
add wave -radix hex /tb_tiny_npu/dut/dmem_ld_addr
add wave /tb_tiny_npu/dut/dmem_st_en
add wave -radix hex /tb_tiny_npu/dut/dmem_st_addr
add wave -radix hex /tb_tiny_npu/dut/dmem_st_data

add wave -divider "testbench"
add wave -radix decimal /tb_tiny_npu/expected
add wave -radix decimal /tb_tiny_npu/got

configure wave -namecolwidth 220
configure wave -valuecolwidth 120

run -all
wave zoom full
