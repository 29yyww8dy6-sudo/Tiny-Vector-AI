# Run from the repo root: make -C verification sim
RTL = ../rtl/imem.v ../rtl/dmem.v ../rtl/vregfile.v ../rtl/accfile.v ../rtl/tiny_npu_core.v
BUILD = ../build

.PHONY: sim sim_align clean

sim: $(BUILD)
	cd .. && iverilog -g2005-sv -o build/tb_tiny_npu.vvp rtl/imem.v rtl/dmem.v rtl/vregfile.v rtl/accfile.v rtl/tiny_npu_core.v verification/tb_tiny_npu.v
	cd .. && vvp build/tb_tiny_npu.vvp

sim_align: $(BUILD)
	cd .. && iverilog -g2005-sv -o build/tb_align_violation.vvp rtl/imem.v rtl/dmem.v rtl/vregfile.v rtl/accfile.v rtl/tiny_npu_core.v verification/tb_align_violation.v
	cd .. && vvp build/tb_align_violation.vvp

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -f $(BUILD)/*.vvp $(BUILD)/*.vcd
