PROJ = day2
include ../../common/common.mk
IMPL_SOURCES = src/top.v src/solver.v src/generator.v src/range_calc.v src/div64.v
LPF_FILE = data/day2.lpf
NEXTPNR_FLAGS = --timing-allow-fail

.PHONY: sim

# Generate HEX
src/mem.hex: ../py/solution.py ../input/input.txt
	python3 ../py/solution.py ../input/input.txt --generate-hex src/mem.hex

sim: src/mem.hex
	$(DOCKER_CMD) iverilog -o day2_sim src/solver.v src/generator.v src/range_calc.v src/div64.v tb/tb.v
	$(DOCKER_CMD) vvp day2_sim

# Cocotb Test
test:
	$(DOCKER_CMD) make -f run_cocotb.mk
