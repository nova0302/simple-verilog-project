//`include "defines.sv"
`timescale 1ns/10ps
module   led_test_tb;

   localparam PERIOD = 10;
   localparam NUM_COUNT = 5;

   reg clk, rst_n, led;

   initial begin
      clk <= 1'b1;
      forever #(PERIOD/2) clk <= ~clk;
   end

   initial begin
      repeat(30) @(posedge clk);
      $finish;
   end

   always @(posedge clk)
     $monitor("@%0tns count=%0h led = %0d",$time, dut.count_r, led);

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

endmodule // led_test_tb
