SHELL := /usr/bin/env bash

SRC_DIR ?= blink
TOP ?= $(notdir $(patsubst %/,%,$(SRC_DIR)))
PROJECT ?= $(TOP)
BUILD_DIR ?= build/$(TOP)

FAMILY ?= artix7
PART ?= xc7a35tcpg236-1
BOARD ?= cmoda7_35t

VHDL_SRCS := $(sort $(wildcard $(SRC_DIR)/*.vhd) $(wildcard $(SRC_DIR)/*.vhdl))
XDC ?= $(firstword $(wildcard $(SRC_DIR)/*.xdc))

DBPART := $(shell echo $(PART) | sed -e 's/-[0-9]$$//')
CHIPDB ?= build/chipdb
CHIPDB_FILE := $(CHIPDB)/$(DBPART).bin

JSON := $(BUILD_DIR)/$(PROJECT).json
YOSYS_REPORT := $(BUILD_DIR)/$(PROJECT)_yosys.rpt
ROUTED_JSON := $(BUILD_DIR)/$(PROJECT)_routed.json
FASM := $(BUILD_DIR)/$(PROJECT).fasm
FRAMES := $(BUILD_DIR)/$(PROJECT).frames
BIT := $(BUILD_DIR)/$(PROJECT).bit
BBA := $(BUILD_DIR)/$(DBPART).bba

PYPY3 ?= pypy3
PNR_ARGS ?=
PROGRAM_ARGS ?= --board $(BOARD)

.DEFAULT_GOAL := all

.PHONY: all help program clean pnrclean check-src check-toolchain

all: check-src check-toolchain $(BIT)

help:
	@echo "Targets:"
	@echo "  make [SRC_DIR=blink]     Build a bitstream"
	@echo "  make program             Program the board with openFPGALoader"
	@echo "  make clean               Remove generated build outputs"
	@echo ""
	@echo "Key variables:"
	@echo "  SRC_DIR=<dir>            Source directory containing .vhd/.vhdl and .xdc"
	@echo "  TOP=<entity>             Top-level VHDL entity (default: directory name)"
	@echo "  YOSYS_REPORT=<path>      Synthesis resource report file (default: $(YOSYS_REPORT))"
	@echo "  PART=<part>              FPGA part (default: xc7a35tcpg236-1)"
	@echo "  BOARD=<board>            openFPGALoader board name (default: cmoda7-35t)"

program: $(BIT)
	@$(MAKE) check-toolchain
	openFPGALoader $(PROGRAM_ARGS) --bitstream $(BIT)

check-src:
	@test -n "$(strip $(VHDL_SRCS))" || { echo "No VHDL sources found in $(SRC_DIR)"; exit 1; }
	@test -n "$(strip $(XDC))" || { echo "No XDC constraints file found in $(SRC_DIR)"; exit 1; }

check-toolchain:
	@test -n "$(strip $(NEXTPNR_XILINX_PYTHON_DIR))" || { echo "NEXTPNR_XILINX_PYTHON_DIR is not set. Load the project environment with direnv or nix develop ./nix"; exit 1; }
	@test -n "$(strip $(PRJXRAY_DB_DIR))" || { echo "PRJXRAY_DB_DIR is not set. Load the project environment with direnv or nix develop ./nix"; exit 1; }

$(BUILD_DIR):
	mkdir -p $@

$(JSON): $(VHDL_SRCS) | $(BUILD_DIR)
	yosys -m ghdl -p "ghdl --std=08 $(VHDL_SRCS) -e $(TOP); synth_xilinx -flatten -abc9 -arch xc7 -top $(TOP); tee -o $(YOSYS_REPORT) stat -tech xilinx; write_json $@"

$(CHIPDB_FILE): | $(BUILD_DIR)
	mkdir -p $(dir $@)
	$(PYPY3) $(NEXTPNR_XILINX_PYTHON_DIR)/bbaexport.py --device $(PART) --bba $(BBA)
	bbasm -l $(BBA) $@
	rm -f $(BBA)

$(FASM): $(JSON) $(CHIPDB_FILE) $(XDC) | $(BUILD_DIR)
	nextpnr-xilinx --chipdb $(CHIPDB_FILE) --xdc $(XDC) --json $(JSON) --write $(ROUTED_JSON) --fasm $@ $(PNR_ARGS)

$(FRAMES): $(FASM)
	fasm2frames --part $(PART) --db-root $(PRJXRAY_DB_DIR)/$(FAMILY) $< > $@

$(BIT): $(FRAMES)
	xc7frames2bit --part_file $(PRJXRAY_DB_DIR)/$(FAMILY)/$(PART)/part.yaml --part_name $(PART) --frm_file $< --output_file $@

clean:
	rm -rf build

pnrclean:
	rm -f $(FASM) $(FRAMES) $(BIT) $(ROUTED_JSON)
