
module pick
  #(parameter NUM_COUNT = 50000000)
   (
     input CLK
    ,input nRST
    ,input GO
    ,input wire[15:0] DIN
    ,output PUSH
    ,output wire[15:0] PIXEL_DATA
    );

   parameter NUM_PIX = 16;

   enum   {eIDLE, eFFFF0, eFFFF1, eAAAA, eCNTL, ePIXEL_DATA}currState, nextState;

   always_ff @(posedge CLK, nRST) begin
      if(!nRST)
        currState <= eIDLE;
      else
        currState <= nextState;
   end

   int pixel_cnt;
   always_ff @(posedge CLK, negedge nRST) begin
      if(!nRST)
        pixel_cnt <= 0;
      else if(currState == eCNTL)
        pixel_cnt <= NUM_PIX;
      else if(currState == ePIXEL_DATA)
        pixel_cnt <= pixel_cnt - 1;
   end

   always_comb begin
      nextState = eIDLE;
      unique case(currState)
        eIDLE: if(GO) nextState = eFFFF0;
        eFFFF0: if(DIN == 16'hFFFF) nextState  = eFFFF1;
        eFFFF1: if(DIN == 16'hFFFF) nextState  = eAAAA;
        eAAAA: if(DIN == 16'hAAAA) nextState  = eCNTL;
        eCNTL:  nextState  = ePIXEL_DATA;
        ePIXEL_DATA: if(pixel_cnt > 1) nextState = ePIXEL_DATA;  else nextState = eIDLE;
      endcase // unique case (currState)
   end

   assign PUSH = (currState == ePIXEL_DATA) ? 1'b1 : 1'b0;
   assign PIXEL_DATA = (currState == ePIXEL_DATA) ? DIN : 16'h0;

endmodule // pick
