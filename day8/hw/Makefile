# Makefile for Day 8 HW

PROJ = day8
TOP_MODULE = solution
IMPL_SOURCES = src/solution.v
OUTPUT_DIR = output

include ../../common/common.mk

SRC_DIR = src
SIM_DIR = sim
BUILD_DIR = build

SRCS = $(wildcard $(SRC_DIR)/*.v)
TB_SRC = $(SIM_DIR)/tb.v

# Output binary
TARGET = $(BUILD_DIR)/sim.out

.PHONY: all clean run sim

all: $(TARGET)

$(TARGET): $(SRCS) $(TB_SRC)
	@mkdir -p $(BUILD_DIR)
	$(DOCKER_CMD) iverilog -o $@ -I $(SRC_DIR) $^

run: $(TARGET)
	$(DOCKER_CMD) vvp $(TARGET)

# Cocotb Test
test:
	$(DOCKER_CMD) make -f run_cocotb.mk

sim: run
