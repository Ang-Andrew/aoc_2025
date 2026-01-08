PROJ = day3
include ../../common/common.mk
IMPL_SOURCES = src/top.v src/tree_solver.v src/rom_feeder.v
LPF_FILE = data/day3.lpf

.PHONY: sim

# Generate Hex
data/input.hex: scripts/gen_hex.py ../input/input.txt
	python3 scripts/gen_hex.py ../input/input.txt data/input.hex

sim: src/tree_solver.v src/tb_solver.v data/input.hex
	$(DOCKER_CMD) iverilog -o sim_bin src/tree_solver.v src/tb_solver.v
	$(DOCKER_CMD) vvp sim_bin

# Cocotb Test
test:
	$(DOCKER_CMD) make -f run_cocotb.mk
