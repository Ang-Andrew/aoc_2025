# Makefile for Day 12 HW

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
	iverilog -o $@ -I $(SRC_DIR) $^

run: $(TARGET)
	vvp $(TARGET)

clean:
	rm -rf $(BUILD_DIR)

# Synthesis / Implementation
PROJ = solution
TOP_MODULE = solution
IMPL_SOURCES = $(SRC_DIR)/solution.v
LPF_FILE = $(SRC_DIR)/ulx3s_v20.lpf

include ../../common/common.mk

synth-impl:
	$(MAKE) impl
