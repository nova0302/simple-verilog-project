
module test
  (
   input        clk, rst_n,
   input [3:0]  in_val,
   output [3:0] out_val
   );

   assign out_val = (clk) ? in_val : rst_n;

endmodule // test


module always_test;
   reg clk;
   reg rst_n;
   reg [3:0] in_val;
   wire [3:0] out_val;

   test dut(.*);

   initial begin
      $dumpfile("assign_out.vcd");
      $dumpvars(-1, tb);
      $monitor("%b", out_val);
   end

   always begin
      #5;
      clk = ~clk;
      in_val = in_val + 1;
   end

   initial begin
      clk = 0;
      rst_n = 0;

      in_val = 0;
      #60;

      $finish;
   end

endmodule // always_test
