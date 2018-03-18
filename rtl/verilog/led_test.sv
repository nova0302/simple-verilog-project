
//`define SIMULATION

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
   int 	   count_r, count_n;
   logic   led0_r, led0_n;

   assign led = led0_r;

   always_ff @(posedge clk or negedge rst_n)
     if(!rst_n)
       count_r <= 0;
     else
       count_r <= count_n;

   always_comb
     if(count_r == NUM_COUNT)
       count_n = 0;
     else
       count_n = count_r + 1;


   always_ff @(posedge clk or negedge rst_n)
     if(!rst_n)
       led0_r <= 0;
     else
       led0_r <= led0_n;

   always_comb
     if(count_r == NUM_COUNT)
       led0_n = ~led0_r;
     else
       led0_n = led0_r;



endmodule // led
