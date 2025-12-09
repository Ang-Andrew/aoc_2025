PROJ = day2
include ../../common/common.mk
IMPL_SOURCES = src/top.v src/solver.v src/generator.v
LPF_FILE = data/day2.lpf

.PHONY: sim

# Generate HEX
src/mem.hex: ../py/solution.py ../input/input.txt
	python3 ../py/solution.py ../input/input.txt --generate-hex src/mem.hex

sim: src/mem.hex
	iverilog -o day2_sim src/solver.v src/generator.v tb/tb.v
	vvp day2_sim
