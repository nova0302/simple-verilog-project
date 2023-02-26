
module test
  (
   input        clk, rst_n,
   input [3:0]  in_val,
   output [3:0] out_val
   );

   assign out_val = (clk) ? in_val : rst_n;

endmodule // test


module always_test;
   reg clk = 1'b0;
   reg rst_n;
   reg [3:0] in_val = 0;
   wire [3:0] out_val;

   task hw_reset;
      rst_n = 1'b0;
      repeat (2) @(negedge clk);
      rst_n <= 1'b1;
      @(negedge clk);
   endtask // b0

   test dut(.*);

   initial begin
      $dumpfile("assign_out.vcd");
      $dumpvars(1, dut);
      //$dumpvars(-1, dut);
      $monitor("@%5tns %b", $time, out_val);
   end

   always #4 clk <= ~clk;


   initial begin
      hw_reset;
      forever begin
         //#(4)
         @(posedge clk)
         in_val <= in_val + 1;
      end
   end

   //   always begin
   //      #5;
   //      clk = ~clk;
   //      in_val = in_val + 1;
   //   end

   initial begin
      #60;
      $finish;
   end

endmodule // always_test
