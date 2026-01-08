# day3 Cocotb Configuration

# Verilog Sources (Wildcard)
VERILOG_SOURCES = $(wildcard $(PWD)/src/*.v)

# DUT Top Level
TOPLEVEL = tree_solver

# Python Test Module
MODULE = test_day3

# Paths
export PYTHONPATH := $(PWD)/verif:$(PYTHONPATH)

include ../../common/cocotb_common.mk
