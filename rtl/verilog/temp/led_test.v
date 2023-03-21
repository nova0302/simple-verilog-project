
//`define SIMULATION

`timescale 1ns/10ps
module led_test 
`ifdef SIMULATION
  #(parameter NUM_COUNT = 5)
`else
   #(parameter NUM_COUNT = 50000000)
`endif
   (
    input  clk, rst_n,
    output led
    );

   integer count_r, count_n;
   reg 	   led_r, led_n;

   assign led = led_r;
   // conter register
   always@(posedge clk or negedge rst_n)
     if(!rst_n)
       count_r <= 0;
     else
       count_r <= count_n;

   // counter combinational logic
   always@* 
     if(count_r == NUM_COUNT)
       count_n = 0;
     else
       count_n = count_r+1;

   // led register
   always@(posedge clk or negedge rst_n)
     if(!rst_n)
       led_r <= 0;
     else
       led_r <= led_n;

   // led combinational logic
   always@*
     if(count_r == NUM_COUNT)
       led_n = ~led_r;
     else
       led_n = led_r;



endmodule // led
