# Day 1 Cocotb Configuration

# Verilog Sources
VERILOG_SOURCES = $(PWD)/src/day1_solver.v

# DUT Top Level
TOPLEVEL = day1_solver

# Python Test Module (filename without .py)
MODULE = test_day1

# Add verif/ to PYTHONPATH so cocotb can find the test module
export PYTHONPATH := $(PWD)/verif:$(PYTHONPATH)
export FULL_INPUT_PATH := $(PWD)/data/input

include ../../common/cocotb_common.mk
