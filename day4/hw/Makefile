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
