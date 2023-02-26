//+++++++++++++++++++++++++++++++++++++++++++++++++
// Simple Program with ports
//+++++++++++++++++++++++++++++++++++++++++++++++++
program simple(input clk, led, output logic rst_n);
   //=================================================
   // Initial block inside program block
   //=================================================
   initial begin
     $monitor("@%0tns led = %0d",$time, led);
     rst_n = 0;
     #20 rst_n = 1;
     @ (posedge clk);
     repeat (100) @ (posedge clk);
     $finish;
  end
endprogram

//`include "defines.sv"
//`define GATE_SIM

module   led_test_tb;

   timeunit 1ns;
   timeprecision 1ns;

   localparam PERIOD = 10;
   localparam NUM_COUNT = 5;


   logic clk, rst_n, led;

   initial begin
      clk <= 1'b1;
      forever #(PERIOD/2) clk <= ~clk;
   end

   always @(posedge clk)
     $monitor("@%0tns count=%h led = %0d",$time, dut.count_r, led);

   initial begin
      rst_n = 0;
      #15 rst_n <= 1;
      @ (posedge clk);
      repeat (30) @ (posedge clk);
      $finish;
   end

`ifdef GATE_SIM
   led_test  dut(.*);
`else
   led_test #(.NUM_COUNT(NUM_COUNT)) dut(.*);
`endif

   reg [7:0] r_Mux_Addr_Data = 0;
   reg       r_Addr_Valid = 1'b0;
   reg       r_Data_Valid = 1'b0;

   task do_write;
      input [7:0] i_addr, i_data;
      begin
         // demonstrates driving external Global Reg
         r_Addr_Valid    = 1'b1;
         r_Mux_Addr_Data = i_addr;
         #10;
         r_Addr_Valid    = 1'b0;
         r_Data_Valid    = 1'b1;
         r_Mux_Addr_Data = i_data;
         #10;
         r_Data_Valid = 1'b0;
         #10;
      end
   endtask

   initial
     begin
        #10;
        do_write(8'h00, 8'hAB);
        do_write(8'h01, 8'hBC);
        do_write(8'h02, 8'hCD);
     end

endmodule // led_test_tb
   //   always @(posedge clk, negedge rst_n) begin
   //   end

   //  initial begin
   //     repeat(30) @(posedge clk);
   //     $finish;
   //  end
