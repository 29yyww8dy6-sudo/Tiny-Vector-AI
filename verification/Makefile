# verification/Makefile -- Tier 0 RTL 시뮬레이션
#
#   make sim              LANES=8 (ADR-003 기본값)
#   make sim LANES=4
#   make sweep            lane 은닉 조항 검증: 4/8/16/32 결과 비교
#   make wave             VCD 덤프
#   make clean
#
# 필요: iverilog  (brew install icarus-verilog)

ROOT  := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))/..
BUILD := $(ROOT)/build
TB    := verification/tb/tb_tva_top.v
VVP   := $(BUILD)/tb_tva_top.vvp
LOG   := $(BUILD)/sim.log

LANES ?= 8

IVFLAGS := -g2005-sv -Wall -f rtl/tva_files.f -Ptb_tva_top.LANES=$(LANES)

.PHONY: sim wave sweep clean

sim:
	@mkdir -p $(BUILD)
	cd $(ROOT) && iverilog $(IVFLAGS) -o $(VVP) $(TB)
	cd $(ROOT) && vvp $(VVP) | tee $(LOG)
	@grep -q "=== PASS ===" $(LOG) || { echo "simulation did not pass"; exit 1; }

wave:
	@mkdir -p $(BUILD)
	cd $(ROOT) && iverilog $(IVFLAGS) -DDUMP_VCD -o $(VVP) $(TB)
	cd $(ROOT) && vvp $(VVP)
	@echo "-> verification/waveforms/tb_tva_top.vcd"

# 같은 바이너리가 lane 구성과 무관하게 같은 결과를 내는지 (§1).
# 달라져야 하는 것은 cycles 뿐이다.
sweep:
	@for l in 4 8 16 32; do \
	  $(MAKE) --no-print-directory sim LANES=$$l 2>/dev/null \
	    | grep -E "mem\[0x30000\]|FAIL" || echo "LANES=$$l build failed"; \
	done

clean:
	rm -rf $(BUILD)
