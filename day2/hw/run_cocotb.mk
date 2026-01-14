# day2 Cocotb Configuration

# Verilog Sources (V3 with test wrapper)
VERILOG_SOURCES = $(PWD)/src/top_tb.v $(PWD)/src/solver_v3.v

# DUT Top Level
TOPLEVEL = top_tb

# Python Test Module
MODULE = test_day2

# Paths
export PYTHONPATH := $(PWD)/verif:$(PYTHONPATH)

# Pre-build step: Copy ROM file where vvp can find it
$(shell mkdir -p sim_build && cp -f src/results.hex sim_build/results.hex)

include ../../common/cocotb_common.mk
