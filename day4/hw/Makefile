PROJ = ao4_day4
TOP_MODULE = solver
LPF_FILE = constraints.lpf
IMPL_SOURCES = src/solver.v
OUTPUT_DIR = output
NEXTPNR_FLAGS = --lpf-allow-unconstrained --placed-svg $(OUTPUT_DIR)/$(PROJ)_placed.svg --routed-svg $(OUTPUT_DIR)/$(PROJ)_routed.svg

include ../../common/common.mk

.PHONY: all clean test sim images

all: impl images

images: $(OUTPUT_DIR)/$(PROJ)_out.config
	@echo "Generated placement image: $(OUTPUT_DIR)/$(PROJ)_placed.svg"
	@echo "Generated routing image: $(OUTPUT_DIR)/$(PROJ)_routed.svg"

clean:
	rm -f *.json *.config *.bit *.svg *.svf

# Cocotb Test
test:
	$(DOCKER_CMD) make -f run_cocotb.mk

# Icarus Verilog Simulation
sim:
	$(DOCKER_CMD) sh -c "iverilog -o sim.vvp -s tb_solver -g2012 src/line_buffer_draft.v src/solver.v src/tb_solver.v && vvp sim.vvp"

# Docker helpers (added by generate_tests.py)
DOCKER_IMAGE ?= ecp5-toolchain
WORKSPACE_ROOT ?= $(shell cd ../.. && pwd)
REL_PATH ?= $(shell python3 -c "import os; print(os.path.relpath('$(CURDIR)', '$(WORKSPACE_ROOT)'))")
DOCKER_CMD ?= docker run --rm -v $(WORKSPACE_ROOT):/workspace -w /workspace/$(REL_PATH) $(DOCKER_IMAGE)
