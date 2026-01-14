PROJ = day2
include ../../common/common.mk
IMPL_SOURCES = src/top.v src/solver_v3.v
LPF_FILE = data/day2.lpf
NEXTPNR_FLAGS =

.PHONY: sim

# Generate HEX
src/mem.hex: ../py/solution.py ../input/input.txt
	python3 ../py/solution.py ../input/input.txt --generate-hex src/mem.hex

sim: src/results.hex
	$(DOCKER_CMD) iverilog -o day2_sim src/solver_v3.v tb/tb_v3.v
	$(DOCKER_CMD) vvp day2_sim

# Generate V3 ROM with pre-computed results (recommended)
src/results.hex: precompute_results.py ../input/input.txt
	python3 precompute_results.py ../input/input.txt src/results.hex

# Cocotb Test
test:
	$(DOCKER_CMD) make -f run_cocotb.mk
