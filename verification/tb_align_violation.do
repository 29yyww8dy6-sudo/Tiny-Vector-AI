# ModelSim/Questa waveform run for the misaligned-VLD negative test.
# Expect the RTL's own $fatal to fire (rtl/tiny_npu_core.v, the VLD
# alignment check) -- that IS the pass condition. Run from the project root:
#
#   vsim -do verification/tb_align_violation.do

vlib work

vlog -work work \
    rtl/imem.v \
    rtl/dmem.v \
    rtl/vregfile.v \
    rtl/accfile.v \
    rtl/tiny_npu_core.v \
    verification/tb_align_violation.v

vsim -voptargs=+acc work.tb_align_violation

add wave -divider "control"
add wave -radix unsigned /tb_align_violation/dut/state
add wave -radix unsigned /tb_align_violation/dut/pc
add wave -radix hex      /tb_align_violation/dut/instr
add wave -radix hex      /tb_align_violation/dut/imm
add wave                 /tb_align_violation/done

configure wave -namecolwidth 220
configure wave -valuecolwidth 120

run -all
wave zoom full
