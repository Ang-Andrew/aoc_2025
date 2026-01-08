# day7 Cocotb Configuration

# Verilog Sources (Wildcard)
VERILOG_SOURCES = $(wildcard $(PWD)/src/*.v)

# DUT Top Level
TOPLEVEL = solution

# Python Test Module
MODULE = test_day7

# Paths
export PYTHONPATH := $(PWD)/verif:$(PYTHONPATH)

# Icarus Include Path
COMPILE_ARGS += -I$(PWD)/src

include ../../common/cocotb_common.mk
