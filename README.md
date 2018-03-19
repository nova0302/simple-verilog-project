
* Important
  - the pin file should have one blank line at the top of the file.

* This is a sample project for Systemverilog sim and pnr with Modelsim and Quartus.

** for functional simulation.
   1. put your design files(verilog & systemverilog) in ./rtl/verilog/
   2. go to ./design/sim/rtl_sim
   3. $>make

** for gate level simulation
   1. got to ./design/sim/gate_sim
   2. $>make 

** for FPGA build and program 
   1. go to ./design/pnr/quartus
   2. $>make && make program
