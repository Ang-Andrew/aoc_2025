# Makefile for Day 5 HW

SRC_DIR = src
SIM_DIR = sim
BUILD_DIR = build

SRCS = $(wildcard $(SRC_DIR)/*.v)
TB_SRC = $(SIM_DIR)/tb.v

# Output binary
TARGET = $(BUILD_DIR)/sim.out

.PHONY: all clean run

all: $(TARGET)

$(TARGET): $(SRCS) $(TB_SRC)
	@mkdir -p $(BUILD_DIR)
	$(DOCKER_CMD) iverilog -o $@ -I $(SRC_DIR) $^

run: $(TARGET)
	$(DOCKER_CMD) vvp $(TARGET)

clean:
	rm -rf $(BUILD_DIR)

# Cocotb Test
test:
	$(DOCKER_CMD) make -f run_cocotb.mk

# Docker helpers (added by generate_tests.py)
DOCKER_IMAGE ?= ecp5-toolchain
WORKSPACE_ROOT ?= $(shell cd ../.. && pwd)
REL_PATH ?= $(shell python3 -c "import os; print(os.path.relpath('$(CURDIR)', '$(WORKSPACE_ROOT)'))")
DOCKER_CMD ?= docker run --rm -v $(WORKSPACE_ROOT):/workspace -w /workspace/$(REL_PATH) $(DOCKER_IMAGE)

# Runs Icarus Verilog Simulation
sim: run
