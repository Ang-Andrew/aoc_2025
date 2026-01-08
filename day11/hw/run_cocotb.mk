# day11 Cocotb Configuration

# Verilog Sources (Wildcard)
VERILOG_SOURCES = $(wildcard $(PWD)/src/*.v)

# DUT Top Level
TOPLEVEL = solution

# Python Test Module
MODULE = test_day11

# Paths
export PYTHONPATH := $(PWD)/verif:$(PYTHONPATH)

include ../../common/cocotb_common.mk
