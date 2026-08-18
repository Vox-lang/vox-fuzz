SHELL := /bin/sh
VOX ?= ../vox/target/release/vox
# Pin the compiler runtime to the repo's coreasm; an installed
# /usr/share/vox/coreasm would otherwise shadow it silently.
VOX_CORE_PATH ?= $(abspath $(dir $(VOX))../../coreasm)
export VOX_CORE_PATH
BUILD := build
BIN := $(BUILD)/vox-fuzz

.PHONY: all build test clean

all: build

build: $(BIN)

$(BIN): src/*.vox
	@mkdir -p $(BUILD)
	$(VOX) src/main.vox -o $(BIN)

test:
	VOX=$(VOX) ./test.sh

clean:
	rm -rf $(BUILD)