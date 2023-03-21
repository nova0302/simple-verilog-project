
module pick
  #(parameter pixelWidth = 16)
   (
    input CLK // from selectIO
    ,input nRST
    ,input go
    ,input wire[pixelWidth-1:0] DIN
    ,output PIXEL_VALID
    ,output wire[pixelWidth-1:0] PIXEL_DATA
    );

   parameter numPixel = 16;

   enum   {eIdle, eFFFF0, eFFFF1, eAAAA, eCNTL, ePIXEL_DATA}currState, nextState;

   always_ff @(posedge CLK, nRST) begin
      if(!nRST)
        currState <= eIdle;
      else
        currState <= nextState;
   end

   int pixel_cnt;
   int pixel_cnt_next;
   always_ff @(posedge CLK, negedge nRST) begin
      if(!nRST)
        pixel_cnt <= 0;
      else
        pixel_cnt <= pixel_cnt_next;
   end

   always_comb begin
      nextState = eIdle; //default state
      pixel_cnt_next = pixel_cnt;

      unique case(currState)
        eIdle: begin
           if(go) nextState  = eFFFF0;
        end
        eFFFF0: begin
           nextState = (DIN == 16'hFFFF) ? eFFFF1 : eFFFF0;
        end

        eFFFF1: begin
           nextState = (DIN == 16'hFFFF) ? eAAAA : eFFFF0;
        end

        eAAAA: begin
           nextState = (DIN == 16'hAAAA) ? eCNTL : eFFFF0;
        end

        eCNTL:  begin
           pixel_cnt_next = 1;
           nextState  = ePIXEL_DATA;
        end

        ePIXEL_DATA:begin
           pixel_cnt_next = pixel_cnt + 1;
           if(pixel_cnt > numPixel - 1)
             nextState = eIdle;
           else
             nextState = ePIXEL_DATA;
        end
      endcase // unique case (currState)
   end

   assign PIXEL_VALID = (currState == ePIXEL_DATA) ? 1'b1 : 1'b0;
   assign PIXEL_DATA  = (currState == ePIXEL_DATA) ? DIN : 16'h0;

endmodule // pick
