

module FPGA
  #(parameter NUM_COUNT = 50000000)
   (
    input clk, rst_n

    , output bit CLI
    , output bit HD
    , output bit VD
    );

   timeunit 1ns;
   timeprecision 1ns;

   localparam PERIOD = 10; // 1MHz

   //logic     CLI;
   initial begin
      CLI <= 1'b1;
      forever #(PERIOD/2) CLI <= ~CLI;
   end

   localparam DIV = 10; // 1MHz

   localparam H_PXL_MAX = 2 ** 6; // 64
   localparam V_PXL_MAX = 2 ** 5; // 32
   //localparam H_PXL_MAX = 65536 / DIV; // 1MHz
   //localparam V_PXL_MAX = 8192 / DIV; // 1MHz

   localparam H_BACK_PORCH = H_PXL_MAX/10; // 1MHz
   localparam V_BACK_PORCH = V_PXL_MAX/10; // 1MHz

   int hd;
   always_ff @(posedge CLI, negedge rst_n)
     if(!rst_n)
       hd <= 0;
     else
       if(hd == H_PXL_MAX-1)
         hd <= 0;
       else
         hd <= hd + 1;

   assign HD = (hd > H_BACK_PORCH);

   int vd;
   always_ff @(posedge CLI, negedge rst_n)
     if(!rst_n)
       vd <= 0;
     else
       if(hd == H_PXL_MAX-1)
         if(vd == V_PXL_MAX-1)
           vd <= 0;
         else
           vd <= vd + 1;
   assign VD = (vd > V_BACK_PORCH);


endmodule // led
