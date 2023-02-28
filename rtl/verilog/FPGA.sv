
module FPGA
  #(parameter NUM_COUNT = 50000000)
   (
    input clk//, rst_n

    //, output bit CLI
    , output bit HD
    , output bit VD
    );

   timeunit 1ns;
   timeprecision 1ns;

   localparam PERIOD = 1000; // 1MHz
   localparam H_PXL_MAX = 2 ** 6; // 64
   localparam V_PXL_MAX = 2 ** 5; // 32
   //localparam H_PXL_MAX = 2 ** 16; // 65536
   //localparam V_PXL_MAX = 2 ** 13; // 8192

   localparam H_BACK_PORCH = H_PXL_MAX/10;
   //localparam V_BACK_PORCH = V_PXL_MAX/10;
   localparam V_BACK_PORCH = 0;

   bit    CLI = 1'b0;
   always #(PERIOD/2) CLI = ~CLI;

   //logic     CLI;
   bit    rst_n = 1'b0;
   initial begin
      repeat(3) @(posedge CLI);
      #15 rst_n <= 1'b1;
   end

   initial begin
      repeat(3000) @(posedge CLI);
      $finish;
   end

   always@(posedge CLI)
     $monitor("@%0tns hd=%0d, vd=%0d HD:%b VD:%d", $time, hd, vd, HD, VD);

   int hd;
   always_ff @(posedge CLI, negedge rst_n)begin
     if(!rst_n)
       hd <= 0;
     else
       if(hd == H_PXL_MAX-1)
         hd <= 0;
       else
         hd <= hd + 1;
   end

   assign HD = (hd > H_BACK_PORCH);

   int vd;
   always_ff @(posedge CLI, negedge rst_n) begin
      if(!rst_n)
	vd <= 0;
      else
	if(hd == H_PXL_MAX-1)
	  if(vd == V_PXL_MAX-1)
	    vd <= 0;
	  else
	    vd <= vd + 1;
   end
   //assign VD = (vd > V_BACK_PORCH);
   assign VD = (vd > V_BACK_PORCH);

endmodule // led
