#VLIB = $(shell which vlib)
#VLOG = $(shell which vlog)
#VSIM = $(shell which vsim)
VLIB =  vlib
VLOG =  vlog
VSIM =  vsim

WORK = work
NOVPOT=-novopt

VLOG_OPTIONS = -lint -y $(VDIR) +libext+.v +incdir+$(VDIR)
VSIM_OPTIONS = -c -voptargs=+acc $(TB) -do "run -all; quit"
#GVSIM_OPTIONS =  -voptargs=+acc $(TB) -do "add wave *; radix -hex; run -all; quit"
GVSIM_OPTIONS =  -voptargs=+acc $(TB) -do "add wave *; run 1ms; quit"

VDIR =./../../../rtl/verilog
VSRCS =$(wildcard $(VDIR)/*.sv)

DUT  = led_test
TB   = $(DUT)_tb
V=@

all: lib com sim
sim:com
	$(V)echo " "
	$(V)echo " -------   Starting Simulation!!!!!  --------------------"
	$(VSIM) $(VSIM_OPTIONS)
#	$(VSIM) $(VSIM_OPTIONS) $(WORK).$(TB)
gsim:
	$(V)echo " "
	$(V)echo " -------   Starting Simulation!!!!!  --------------------"
	$(VSIM) $(GVSIM_OPTIONS)
#	$(VSIM) $(GVSIM_OPTIONS) $(WORK).$(TB)
com:
	$(V)echo " "
	$(V)echo " -------   Compiling verilog source files !!! ------------"
	$(VLOG) $(VLOG_OPTIONS) -work $(WORK) $(VSRCS)
	$(V)echo " "
	$(V)echo " -------   Compiling testbench !!! ------------"
	$(VLOG) $(VLOG_OPTIONS) -work $(WORK) $(VDIR)/$(TB).sv
#	$(VLOG) $(VLOG_OPTIONS) -f vlog.args

lib:
	$(V)echo " -------   Generating $(WORK) directory if it does not exist!!! ----------"
	if [ ! -d $(WORK) ]; then vlib $(WORK); fi

clean:
	rm -rf $(WORK) transcript *.wlf
