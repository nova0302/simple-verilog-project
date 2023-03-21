

module pll_tb;

   timeunit 1ns;
   timeprecision 1ns;

   localparam PERIOD = 100; // 1MHz

   bit ref_clk;
   bit out_clk;


   always @(posedge out_clk)
     $monitor("@%0tns ref_clk=%b ",$time, ref_clk);

   initial begin
      ref_clk = 1'b0;
      forever #(PERIOD/2) ref_clk = ~ref_clk;
   end

   initial begin
      repeat (30) @ (posedge ref_clk);
      $stop;
      //$finish;
   end

   pll dut(.*);

endmodule // pll_tb
