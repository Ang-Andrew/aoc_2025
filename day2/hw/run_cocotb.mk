# day2 Cocotb Configuration

# Verilog Sources (Wildcard)
VERILOG_SOURCES = $(wildcard $(PWD)/src/*.v)

# DUT Top Level
TOPLEVEL = top

# Python Test Module
MODULE = test_day2

# Paths
export PYTHONPATH := $(PWD)/verif:$(PYTHONPATH)

include ../../common/cocotb_common.mk
