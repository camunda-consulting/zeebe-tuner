# Makefile for managing current/run symlink to first testrun
.PHONY: clean help
.DEFAULT_GOAL := current/run

# Find the next testrun directory (lexicographically sorted)
NEXT_TESTRUN := $(shell find testruns -mindepth 1 -maxdepth 1 -type d | sort | head -n1)
NEXT_TESTRUN_NAME := $(notdir $(NEXT_TESTRUN))

# Ensure current directory exists
current:
	@mkdir -p current

# Create or recreate the symlink 
# Make automatically detects broken symlinks and treats them as non-existent
# This rule will trigger if:
# - The symlink doesn't exist
# - The symlink is broken (target doesn't exist)
current/run: current
ifneq ("$(NEXT_TESTRUN)", "")
	@echo "Creating symlink current/run -> $(NEXT_TESTRUN)"
	@rm -f current/run
	@ln -s "../$(NEXT_TESTRUN)" current/run
else
	@echo "No testrun directories found in testruns/"
	@rm -f current/run
	exit 1
endif

# Clean up the symlink and directory
clean:
	@rm -f current/run
	-@rmdir current
	@echo "Removed current/run symlink and directory"

# Help target
help:
	@echo "Available targets:"
	@echo "  current/run      - Create/update symlink to next testrun (default)"
	@echo "  clean            - Remove the current/run symlink and directory"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Current next testrun: $(NEXT_TESTRUN)"
