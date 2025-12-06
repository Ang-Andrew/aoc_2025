# Common Cocotb Makefile include

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Paths
# PWD is the directory where make is run (e.g., day1/)
# We assume sources are in src/ and verif/ mostly

include $(shell cocotb-config --makefiles)/Makefile.sim
