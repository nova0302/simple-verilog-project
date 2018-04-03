###################################################################
# Project Configuration:
#
# Specify the name of the design (project) and the Quartus II
# Settings File (.qsf) and the list of source files used.
###################################################################

PROJECT = led_test
TOP_LEVEL_ENTITY = led_test
ASSIGNMENT_FILES = $(PROJECT).qpf $(PROJECT).qsf
SRCS = ./../../../rtl/verilog/led_test.v

###################################################################
# Part, Family, Boardfile DE1 or DE2
ifdef GATE_SIM
FAMILY = "Cyclone IV E"
PART = EP4CE22F17C6
BOARDFILE = DE0_Nano_Pins
else
FAMILY = "MAX 10"
PART = 10M50DAF484C7G
BOARDFILE = de10_lite_pins
endif
###################################################################

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and database
# program: program your device with the compiled design
###################################################################

all: output_files/smart.log output_files/$(PROJECT).asm.rpt output_files/$(PROJECT).sta.rpt

clean:
	rm -rf *.rpt *.chg smart.log *.htm *.eqn *.pin *.sof *.pof \
	db incremental_db *.smsg *.summary *.qpf *.qsf *.jdi *.qws \
	simulation *.done transcript output_files *.sld

map: output_files/smart.log output_files/$(PROJECT).map.rpt
fit: output_files/smart.log output_files/$(PROJECT).fit.rpt
asm: output_files/smart.log output_files/$(PROJECT).asm.rpt
sta: output_files/smart.log output_files/$(PROJECT).sta.rpt
smart: output_files/smart.log

###################################################################
# Executable Configuration
###################################################################
ifdef GATE_SIM
MAP_ARGS = --family=$(FAMILY) --write_settings_files=on \
	     $(addprefix --source=,$(SRCS)) \
	   --verilog_macro="SIMULATION=1"
else
MAP_ARGS = --family=$(FAMILY) --write_settings_files=on \
	     $(addprefix --source=,$(SRCS)) 
endif
FIT_ARGS = --part=$(PART) --read_settings_files=on
ASM_ARGS =
STA_ARGS = --sdc=led_test.sdc
EDA_ARGS = --simulation --tool=modelsim --format=verilog\
--output_directory=./../../sim/gate_sim

###################################################################
# Target implementations
###################################################################

STAMP = echo done >

output_files/$(PROJECT).map.rpt: output_files/map.chg $(SOURCE_FILES)
	quartus_map $(MAP_ARGS) $(PROJECT)
	$(STAMP) output_files/fit.chg
output_files/$(PROJECT).fit.rpt: output_files/fit.chg output_files/$(PROJECT).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT)
	$(STAMP) output_files/asm.chg
	$(STAMP) output_files/sta.chg
output_files/$(PROJECT).asm.rpt: output_files/asm.chg output_files/$(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT)
output_files/$(PROJECT).sta.rpt: output_files/sta.chg output_files/$(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT)
output_files/smart.log: $(ASSIGNMENT_FILES)
	quartus_sh --determine_smart_action $(PROJECT) > output_files/smart.log

###################################################################
# Project initialization
###################################################################

$(ASSIGNMENT_FILES):
	if [ ! -d output_files ]; then mkdir output_files; fi
	quartus_sh --prepare -f $(FAMILY) -t $(TOP_LEVEL_ENTITY) $(PROJECT)
	-cat $(BOARDFILE) >> $(PROJECT).qsf
output_files/map.chg:
	$(STAMP) $@
output_files/fit.chg:
	$(STAMP) $@
output_files/sta.chg:
	$(STAMP) $@
output_files/asm.chg:
	$(STAMP) $@

###################################################################
# Programming the device
###################################################################

#program: $(PROJECT).sof
program: output_files/$(PROJECT).sof
	quartus_pgm --no_banner --mode=jtag -o "P;$<"

###################################################################
# netlist generation for gate level simulation
###################################################################

netlist:
	quartus_eda $(PROJECT) $(EDA_ARGS)

help:
	@echo "--   make for project build and synthesis!!"
	@echo "--   make program for sof download!!"
	@echo "--   make netlist for netlist generation for gate simulation!!"
