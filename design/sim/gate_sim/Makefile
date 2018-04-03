
QUARTUS_ROOT?= C:/tools/hardware/hdl/intelFPGA_lite/17.0/quartus
DEVICE_FAMILY = cycloneive
#DEVICE_FAMILY = maxv

PROJECT = led_test
TB = ./../../../rtl/verilog/$(PROJECT)_tb.v
TB_MODULE = $(PROJECT)_tb

NET_LIST = $(PROJECT).vo

VLOG_ARGS = -quiet +incdir+./../../../rtl/verilog +define+GATE_SIM

VSIM_ARGS = -quiet -t ps +transport_int_delays +transport_path_delays \
 -L $(DEVICE_FAMILY)_ver \
 -L 220model_ver \
 -L altera_ver \
 -L altera_mf_ver \
 -L fiftyfivenm_ver 

# -L altera_lnsim \

WORK = work

V?=@
all: lib com sim
sim: 
	$(V)echo " "
	$(V)echo " -------   Starting Simulation!!!!!  --------------------"
	$(V)vsim -c $(VSIM_ARGS) $(WORK).$(TB_MODULE) -do "run -all"
	$(V)echo " --   Clearing up files for gate level simulation in ./../../pnr/quartus  --"
	$(V)make -C ./../../pnr/quartus/ clean
	ls  ./../../pnr/quartus
gsim: 
	$(V)echo " "
	$(V)echo " -------   Starting GUI Simulation!!!!!  --------------------"
	$(V)vsim $(VSIM_ARGS) $(WORK).$(TB_MODULE) -do "add wave *;run -all"
com: $(NET_LIST) 
	$(V)echo " "
	$(V)echo " -------   Compiling testbench & netlist !!! ------------"
	$(V)vlog $(VLOG_ARGS)  -work $(WORK) $(NET_LIST) $(TB)
lib:
	$(V)echo " -------   Generating $(WORK) directory if it does not exist!!! ----------"
	$(V)if [ -d $(WORK) ]; then vdel -lib $(WORK) -all && vlib $(WORK); fi
	$(V)if [ ! -d $(WORK) ]; then vlib $(WORK); fi

$(NET_LIST): 
	$(V)echo " "
	$(V)echo " ------- Generating netlist if it has'n benn generated yet !!!!! -----------"
	$(V)make -C ./../../pnr/quartus/ clean
	$(V)make -C ./../../pnr/quartus/ GATE_SIM=1
	$(V)make -C ./../../pnr/quartus/ netlist 
clean:
	$(V)echo " "
	$(V)echo " ------- Clearing up this folder!!!!! ---------"
	$(V)rm -rf *.vo *.sdo *.xrf *.sft transcript $(WORK) *.wlf *.csd verilog_libs *.vo *.sdo *.sft *.wlf *.tcl
