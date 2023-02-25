
   timeunit 1ns;
   timeprecision 1ns;

module pll (
            input bit ref_clk
            ,output bit out_clk
            );
   parameter FACTOR = 4;

   initial begin
      real stamp;
      out_clk = 1'b0;
      @(ref_clk);
      stamp = $realtime;
      forever begin
         real period;
         @(ref_clk);
         period = ($realtime - stamp) / FACTOR;
         stamp = $realtime;
         repeat (FACTOR-1) begin
            out_clk = ~out_clk;
            #(period);
         end
         out_clk = ~out_clk;
      end // forever begin
   end // initial begin

endmodule // led
