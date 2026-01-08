PROJ=ao4_day4
TOP=solver
CONSTR=constraints.lpf
SRC=src/solver.v

# Default to 25k ECP5 (e.g. Colorlight i5, ULX3S)
DEVICE=25k
PACKAGE=CABGA381

# Tools
YOSYS=yosys
NEXTPNR=nextpnr-ecp5
ECPPACK=ecppack

.PHONY: all clean test sim test_verilog

all: $(PROJ).bit images

$(PROJ).json: $(SRC)
	$(YOSYS) -p "synth_ecp5 -top $(TOP) -json $@" $<

# Generates bitstream config AND images
$(PROJ).config: $(PROJ).json
	$(NEXTPNR) --$(DEVICE) --package $(PACKAGE) --json $< --lpf $(CONSTR) --textcfg $@ --placed-svg $(PROJ)_placed.svg --routed-svg $(PROJ)_routed.svg --lpf-allow-unconstrained

$(PROJ).bit: $(PROJ).config
	$(ECPPACK) $< $@

images: $(PROJ).config
	@echo "Generated placement image: $(PROJ)_placed.svg"
	@echo "Generated routing image: $(PROJ)_routed.svg"

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
