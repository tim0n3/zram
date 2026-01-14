SHELL := /bin/bash

SH_FILES := $(shell find . -type d \( -name .git -o -name .github \) -prune -o -type f -name '*.sh' -print)

.PHONY: help lint fmt

help:
	@printf "Targets:\n"
	@printf "  lint  Run ShellCheck, shfmt -d, and bash -n\n"
	@printf "  fmt   Format shell scripts with shfmt\n"

lint:
	./scripts/lint.sh

fmt:
	shfmt -w -ln bash -i 4 -bn -ci -s $(SH_FILES)
