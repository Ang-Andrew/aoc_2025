# day2 Cocotb Configuration

# Ensure mem.hex is in sim_build
$(shell mkdir -p sim_build && cp -f src/mem.hex sim_build/ 2>/dev/null || true)

# Verilog Sources (Wildcard)
VERILOG_SOURCES = $(wildcard $(PWD)/src/*.v)

# DUT Top Level
TOPLEVEL = top

# Python Test Module
MODULE = test_day2

# Paths
export PYTHONPATH := $(PWD)/verif:$(PYTHONPATH)

include ../../common/cocotb_common.mk
