# sources

SRC_DIR = src
SRC = \
	$(SRC_DIR)/selector.vhd\
	$(SRC_DIR)/oct_to_sym.vhd\
	$(SRC_DIR)/sym_to_chip.vhd\
	$(SRC_DIR)/dsss.vhd\
	$(SRC_DIR)/chip_to_dig_qpsk.vhd\
	$(SRC_DIR)/half_sine_shaper.vhd\
	$(SRC_DIR)/delay.vhd

# packages

PKG_DIR = $(SRC_DIR)/pkg
PKG = \
	$(PKG_DIR)/phy_pkg.vhd

# testbench sources

TB_TOPMOD ?= tb
TB_DIR = $(SRC_DIR)/tb
TB = \
	$(TB_DIR)/selector_tb.vhd\
	$(TB_DIR)/oct_to_sym_tb.vhd\
	$(TB_DIR)/sym_to_chip_tb.vhd\
	$(TB_DIR)/dsss_tb.vhd\
	$(TB_DIR)/chip_to_dig_qpsk_tb.vhd\
	$(TB_DIR)/half_sine_shaper_tb.vhd\
	$(TB_DIR)/delay_tb.vhd

GHDL_FLAGS=--std=08 -v --warn-error -fcaret-diagnostics -P/GHDL/0.36-mingw32-mcode/lib/ghdl/vendors/osvvm/v08

WAVE_VCD ?= wave.vcd

.DEFAULT_GOAL := help

help:
	@echo "to run a testbench,"
	@echo "   make gui TB_TOPMOD=<<testbench entity>>            # runs testbench and generates waveforms for gtkwave"
	@echo "   make run TB_TOPMOD=<<testbench entity>>            # runs testbench"
	@echo " or,"
	@echo "   make wave.vcd TB_TOPMOD=<<testbench entity>>       # .. and do quick reloads in gtkwave"
	@echo
	@echo "if TB_TOPMOD is not specified, the entity 'tb' is assumed"
	@echo "if WAVE_VCD is not specified, 'wave.vcd' is assumed"
	@echo
	@echo "don't forget,"
	@echo "   make clean"

.PHONY: run compile gui clean help

.PRECIOUS: $(WAVE_VCD)

run: compile
	ghdl --elab-run $(GHDL_FLAGS) $(TB_TOPMOD)

$(WAVE_VCD): compile
	ghdl --elab-run $(GHDL_FLAGS) $(TB_TOPMOD) --vcd=$(WAVE_VCD)

gui: $(WAVE_VCD)
	gtkwave --dark $(WAVE_VCD)

compile: $(SRC) $(TB_SRC)
	ghdl -a $(GHDL_FLAGS) $(PKG) $(SRC) $(TB)

clean:
	rm -f *.cf
	rm -f $(WAVE_VCD)
	rm -f *.o
	rm -f $(TB_TOPMOD)
