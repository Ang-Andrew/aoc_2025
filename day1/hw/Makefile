PROJ = day1
CONSTR = ../ecp5evn.lpf

# Directories
SRC_DIR = src
VERIF_DIR = verif
DATA_DIR = data
SCRIPTS_DIR = scripts
BUILD_DIR = sim_build

# Inputs
INPUT_FILE = $(DATA_DIR)/input
INPUT_HEX = $(DATA_DIR)/input.hex

# Sources
VERILOG_SOURCES = $(SRC_DIR)/day1_solver.v
TEST_SOURCES_SIMPLE = $(VERIF_DIR)/tb_day1.v
TEST_SOURCES_FULL = $(VERIF_DIR)/tb_day1_full.v $(SRC_DIR)/input_rom.v

# Targets
all: sim

# Generate Hex from Input (ensures Docker consistency)
hex: $(INPUT_HEX)

$(INPUT_HEX): $(INPUT_FILE)
	$(DOCKER_CMD) python3 $(SCRIPTS_DIR)/gen_hex.py

# Simulation (Simple Trace)
sim: $(VERILOG_SOURCES) $(TEST_SOURCES_SIMPLE)
	mkdir -p $(BUILD_DIR)
	$(DOCKER_CMD) iverilog -o $(BUILD_DIR)/sim_simple $(VERILOG_SOURCES) $(TEST_SOURCES_SIMPLE)
	$(DOCKER_CMD) vvp $(BUILD_DIR)/sim_simple

# Simulation (Full Puzzle Input)
full: hex $(VERILOG_SOURCES) $(TEST_SOURCES_FULL)
	mkdir -p $(BUILD_DIR)
	$(DOCKER_CMD) iverilog -o $(BUILD_DIR)/sim_full $(VERILOG_SOURCES) $(TEST_SOURCES_FULL)
	$(DOCKER_CMD) vvp $(BUILD_DIR)/sim_full

# Cocotb Test (Docker)
test:
	$(DOCKER_CMD) make -f run_cocotb.mk

# Cocotb Test (Local)
test-local:
	export PATH=$(shell cd ../../ && pwd)/venv/bin:$(PATH); make -f run_cocotb.mk



# Implementation
PROJ = day1
LPF_FILE = data/day1.lpf
IMPL_SOURCES = $(SRC_DIR)/top.v $(SRC_DIR)/day1_solver.v $(SRC_DIR)/input_rom.v
OUTPUT_DIR = output

.PHONY: all sim full test test-local hex clean impl
include ../../common/common.mk
