PROJ = split_placement
CONSTR = split_placement.lpf

all: $(PROJ).bit

$(PROJ).json: $(PROJ).v
	$(DOCKER_CMD) yosys -p "synth_ecp5 -json $@" $<

$(PROJ).config: $(PROJ).json
	$(DOCKER_CMD) nextpnr-ecp5 --um5g-45k --package CABGA381 --json $< --lpf $(CONSTR) --pre-place constraints.py --textcfg $@ --report report.json

$(PROJ).bit: $(PROJ).config
	$(DOCKER_CMD) ecppack $< $@

include ../common/common.mk
