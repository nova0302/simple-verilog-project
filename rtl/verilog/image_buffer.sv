/*
 *   Clock Domain Crossing
 *    signals from uart
 *   UART(clk40M) <-> selectIO(lvds_clk)
 *   , input cmdUpdate
 *   , input[7:0]cmd
 *
 */

module image_buffer
  (
   input clk40M
   , input nRst
   , input cmdUpdate
   , input[7:0]cmd

   , input lvds_clk
   , input[15:0]pInput

   , output empty
   , input rd
   , output[15:0]fifoOut

   );
   localparam LVDS_RCV_BUF_SIZE = 3;
   /****************** 40MHz Domain(clk40M)   *************************/
   // latch cmd for processing
   logic [7:0] cmdReg;
   always_ff@(posedge clk40M, negedge nRst)begin
      if(!nRst)
        cmdReg <= 8'h00;
      else if(cmdUpdate)
        cmdReg <= cmd;
   end
   // fast(40M) to slow(1M) stratching is needed
   integer stretchCounter;
   always_ff@(posedge clk40M, negedge nRst)begin
      if(cmdUpdate)
        stretchCounter <= 80;
      else if(stretchCounter > 0)
        stretchCounter <= stretchCounter - 1;
   end
   wire cmdUpdateStretched = (stretchCounter > 0) ? 1'b1 : 1'b0;


   /******************** 1MHz Domain(lvds_clk)    ***********************/

   bit  cmdUpdateReg, cmdUpdateMeta;
   always_ff@(posedge lvds_clk) begin
      cmdUpdateMeta <= cmdUpdateStretched;
      cmdUpdateReg <= cmdUpdateMeta;
   end

   enum {eInit, eWaitForValidPixel, eValidPixel}currState, nextState;
   logic [LVDS_RCV_BUF_SIZE-1:0][15:0] buf0;
   always_ff@(posedge lvds_clk)begin
      buf0 <= {buf0[LVDS_RCV_BUF_SIZE-2:0], pInput};
   end
   wire validPreamble = (buf0[2] == 16'hFFFF &&
                         buf0[1] == 16'hFFFF &&
                         buf0[0] == 16'hAAAA);
   logic [3:0] mod16Counter, mod16CounterNext;
   always_ff@(posedge lvds_clk, negedge nRst) begin
      if(!nRst)begin
         currState <= eWaitForValidPixel;
         mod16Counter <= 4'h0;
      end
      else begin
         currState <= nextState;
         mod16Counter <= mod16CounterNext;
      end
   end

   logic wr;
   logic [15:0] fifoIn;
   always_comb begin
      nextState = currState;
      mod16CounterNext = 4'h0;
      wr = 1'b0;
      fifoIn = 16'h00;
      case(currState)
        eInit: begin
           if(cmdUpdateReg == 1'b1 && cmdReg == 8'hA2)
             nextState = eWaitForValidPixel;
        end

        eWaitForValidPixel: begin
           mod16CounterNext = 4'hf;
           if(validPreamble)begin
              nextState = eValidPixel;
           end
        end

        eValidPixel: begin
           mod16CounterNext = mod16Counter - 1'b1;
           wr = 1'b1;
           fifoIn = buf0[0];
           if(mod16Counter > 0)
             nextState = eValidPixel;
           else
             nextState = eInit;
        end
      endcase // case (currState)
   end

   fifo_async_top
     #( .DEPTH(4)
        ,.WIDTH(16))
   fifo_async_top0
     (  .clkw   (lvds_clk )
        ,.resetw (~nRst   )
        ,.wr     (wr      )
        ,.full   (        )
        ,.fifoIn (fifoIn  )
        ,.clkr   (clk40M  )
        ,.resetr (~nRst   )
        ,.rd     (rd      )
        ,.empty  (empty   )
        ,.fifoOut(fifoOut ));



endmodule // image_buffer
