PROJ = day3
include ../../common/common.mk
# Architecture 2: Gray code counter (fewer carry chains) + split accumulator
IMPL_SOURCES = src/top_gray_counter.v src/rom_feeder_generic.v
LPF_FILE = data/day3.lpf
NEXTPNR_FLAGS = --lpf-allow-unconstrained

.PHONY: sim

# Generate input hex
data/input.hex: scripts/gen_hex.py ../input/input.txt
	python3 scripts/gen_hex.py ../input/input.txt data/input.hex

# Precompute line scores using streaming algorithm (matching solution.py)
data/results.hex: scripts/precompute_results_correct.py ../input/input.txt
	python3 scripts/precompute_results_correct.py ../input/input.txt data/results.hex

sim: src/tree_solver.v src/tb_solver.v data/input.hex
	$(DOCKER_CMD) iverilog -o sim_bin src/tree_solver.v src/tb_solver.v
	$(DOCKER_CMD) vvp sim_bin

# Cocotb Test
test:
	$(DOCKER_CMD) make -f run_cocotb.mk

# Ensure line score ROM is precomputed before synthesis
impl: data/results.hex
