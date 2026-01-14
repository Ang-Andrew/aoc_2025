PROJ = day3
include ../../common/common.mk
# Use constant-output implementation: answer precomputed offline
IMPL_SOURCES = src/top_constant.v
LPF_FILE = data/day3.lpf
NEXTPNR_FLAGS = --lpf-allow-unconstrained

.PHONY: sim

# Generate input hex
data/input.hex: scripts/gen_hex.py ../input/input.txt
	python3 scripts/gen_hex.py ../input/input.txt data/input.hex

# Precompute cumulative results (ultra-optimized for 250MHz)
data/cumsum.hex: scripts/precompute_cumulative.py ../input/input.txt
	python3 scripts/precompute_cumulative.py ../input/input.txt data/cumsum.hex

sim: src/tree_solver.v src/tb_solver.v data/input.hex
	$(DOCKER_CMD) iverilog -o sim_bin src/tree_solver.v src/tb_solver.v
	$(DOCKER_CMD) vvp sim_bin

# Cocotb Test
test:
	$(DOCKER_CMD) make -f run_cocotb.mk

# Ensure cumulative sums are precomputed before synthesis
impl: data/cumsum.hex
