# Common Docker configuration
DOCKER_IMAGE = ecp5-toolchain
# Mount the workspace root (one level up from project dir) to /workspace
# Assuming structure: root/dayX/hw
WORKSPACE_ROOT = $(shell cd ../.. && pwd)
# The project relative path from workspace root
REL_PATH = $(shell python3 -c "import os; print(os.path.relpath('$(CURDIR)', '$(WORKSPACE_ROOT)'))")

# Run docker with the workspace mounted. 
# We set WORKDIR to /workspace/$(REL_PATH) so we are inside the project folder.
DOCKER_CMD = docker run --rm -v $(WORKSPACE_ROOT):/workspace -w /workspace/$(REL_PATH) $(DOCKER_IMAGE)

.PHONY: clean

clean:
	rm -rf $(BUILD_DIR) $(OUTPUT_DIR) *.vcd
	rm -f *.json *.config *.bit *.report report.json

# Common Implementation Variables (Override in project Makefile)
# PROJ, IMPL_SOURCES, LPF_FILE

OUTPUT_DIR ?= output

# Implementation Targets
impl: $(OUTPUT_DIR)/$(PROJ).bit

$(OUTPUT_DIR)/$(PROJ).json: $(IMPL_SOURCES)
	mkdir -p $(OUTPUT_DIR)
	$(DOCKER_CMD) yosys -p "synth_ecp5 -top top -json $@" $(IMPL_SOURCES) 2>&1 | tee $(OUTPUT_DIR)/synthesis.log

$(OUTPUT_DIR)/$(PROJ)_out.config: $(OUTPUT_DIR)/$(PROJ).json $(LPF_FILE)
	$(DOCKER_CMD) nextpnr-ecp5 --25k --package CABGA381 --speed 6 --json $(OUTPUT_DIR)/$(PROJ).json --lpf $(LPF_FILE) --textcfg $@ --freq 250 --report $(OUTPUT_DIR)/report.json 2>&1 | tee $(OUTPUT_DIR)/impl.log

$(OUTPUT_DIR)/$(PROJ).bit: $(OUTPUT_DIR)/$(PROJ)_out.config
	$(DOCKER_CMD) ecppack $< $@ 2>&1 | tee $(OUTPUT_DIR)/pack.log
