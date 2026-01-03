PROJ = day3
include ../../common/common.mk
IMPL_SOURCES = src/top.v src/solver.v src/rom_feeder.v
LPF_FILE = data/day3.lpf

.PHONY: sim

# Generate Hex if needed (dependency)
../input/input.hex: ../py/make_hex.py ../input/input.txt
	cd ../py && python3 make_hex.py

sim: src/solver.v src/tb_solver.v ../input/input.hex
	iverilog -o sim_bin src/solver.v src/tb_solver.v
	vvp sim_bin
