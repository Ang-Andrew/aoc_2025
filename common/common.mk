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

.PHONY: clean impl

clean:
	rm -rf $(BUILD_DIR) $(OUTPUT_DIR) *.vcd sim_build sim_bin __pycache__
	rm -f *.json *.config *.bit *.report report.json *.log

# Common Implementation Variables (Override in project Makefile)
# PROJ, IMPL_SOURCES, LPF_FILE, TOP_MODULE

OUTPUT_DIR ?= output
TOP_MODULE ?= top
DEVICE ?= --25k
PACKAGE ?= CABGA381
FREQ ?= 250

# Implementation Targets
impl: $(OUTPUT_DIR)/$(PROJ).bit

$(OUTPUT_DIR)/$(PROJ).json: $(IMPL_SOURCES)
	mkdir -p $(OUTPUT_DIR)
	$(DOCKER_CMD) yosys -p "read_verilog -sv $(IMPL_SOURCES); synth_ecp5 -top $(TOP_MODULE) -json $@" 2>&1 | tee $(OUTPUT_DIR)/synthesis.log

$(OUTPUT_DIR)/$(PROJ)_out.config: $(OUTPUT_DIR)/$(PROJ).json $(LPF_FILE)
	@if [ -n "$(LPF_FILE)" ]; then \
		$(DOCKER_CMD) nextpnr-ecp5 $(DEVICE) --package $(PACKAGE) --json $< --lpf $(LPF_FILE) --textcfg $@ --freq $(FREQ) --report $(OUTPUT_DIR)/report.json $(NEXTPNR_FLAGS) 2>&1 | tee $(OUTPUT_DIR)/impl.log; \
	else \
		$(DOCKER_CMD) nextpnr-ecp5 $(DEVICE) --package $(PACKAGE) --json $< --textcfg $@ --freq $(FREQ) --report $(OUTPUT_DIR)/report.json --lpf-allow-unconstrained $(NEXTPNR_FLAGS) 2>&1 | tee $(OUTPUT_DIR)/impl.log; \
	fi

$(OUTPUT_DIR)/$(PROJ).bit: $(OUTPUT_DIR)/$(PROJ)_out.config
	$(DOCKER_CMD) ecppack $< $@ 2>&1 | tee $(OUTPUT_DIR)/pack.log
