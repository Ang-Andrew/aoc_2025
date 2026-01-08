DOCKER_IMAGE = ecp5-toolchain

# Find all subdirectories that contain a Makefile
PROJECTS := $(shell find day* -mindepth 2 -name Makefile -exec dirname {} \;)

.PHONY: build-image clean-all list $(PROJECTS)

# Default target: list available projects
list:
	@echo "Available projects:"
	@echo $(PROJECTS) | tr ' ' '\n' | sed 's/^/  - /'
	@echo ""
	@echo "Usage:"
	@echo "  make <project>        # Build default target in project"
	@echo "  make <project>/<rule> # Run specific rule in project (e.g. blinky/clean)"

# Build the docker image
build-image:
	docker build -t $(DOCKER_IMAGE) .

# Clean all projects
clean-all:
	@for proj in $(PROJECTS); do \
		echo "Cleaning $$proj..."; \
		$(MAKE) -C $$proj clean; \
	done

# 1. Exact match for project name (e.g. 'make blinky')
$(PROJECTS):
	$(MAKE) -C $@

# Test all projects
# Test all projects (supports -jN parallel execution)
PROJECT_TESTS := $(addsuffix .test, $(PROJECTS))

.PHONY: $(PROJECT_TESTS) test

$(PROJECT_TESTS):
	$(MAKE) -C $(basename $@) test

test: $(PROJECT_TESTS)
