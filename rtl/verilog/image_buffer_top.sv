/*
 *
 *  cmd
 * A0 -> TG
 * A1 -> spi
 * A2 -> image buffer
 *
 */

module image_buffer_top
  (input clk40M
   , input nRst
   , input cmdUpdate
   , input[7:0] cmd
   , input lvds_clk
   , input[15:0] lvds_ch0
   , input[15:0] lvds_ch1
   , input[15:0] lvds_ch2
   , input[15:0] lvds_ch3
   , output serialOut

   );


   logic [3:0] rd = 1'b0;
   wire [3:0]  empty;
   logic [3:0][15:0] lvds_ch;
   assign lvds_ch[0] = lvds_ch0;
   assign lvds_ch[1] = lvds_ch1;
   assign lvds_ch[2] = lvds_ch2;
   assign lvds_ch[3] = lvds_ch3;
   logic [3:0][15:0] fifoOut;
   wire [7:0][7:0]   fifoOutArr;

   genvar            j;
   generate
      for(j=0; j<4; j++) begin
         assign fifoOutArr[2*j  ] = fifoOut[j][7:0];
         assign fifoOutArr[2*j+1] = fifoOut[j][15:8];
      end
   endgenerate

   logic [2:0]       channelCount, channelCountNext;

   genvar            i;
   generate
      for(i=0; i<4; i++) begin: gen_image_buf
         image_buffer
            image_buffer0
            (
             .clk40M   (clk40M   )
             ,.nRst     (nRst      )
             ,.cmdUpdate(cmdUpdate )
             ,.cmd      (cmd       )

             ,.lvds_clk (lvds_clk  )
             ,.pInput   (lvds_ch[i])

             ,.empty    (empty[i]  )
             ,.rd       (rd[i]     )
             ,.fifoOut  (fifoOut[i]));
      end // block: gen_image_buf
   endgenerate

   enum {eInit, eLdXmtDataReg, eByteReady, eTByte, eWiatForTxDone}currState, nextState;
   always_ff@(posedge clk40M, negedge nRst) begin
      if(~nRst)
        currState <= eInit;
      else
        currState <= nextState;
   end
   always_ff@(posedge clk40M, negedge nRst) begin
      if(!nRst)
        channelCount <= 3'b000;
      else
        channelCount <= channelCountNext;
   end

   bit ldXmtDataReg;
   bit byteReady;
   bit tByte;
   logic [7:0] dataBus;
   wire        txDone;
   always_comb begin
      nextState = currState;
      rd = 4'h0;
      ldXmtDataReg = 1'b0;
      byteReady = 1'b0;
      tByte = 1'b0;
      channelCountNext = channelCount;
      case(currState)
        eInit: begin
           if(!empty[0])begin
              nextState = eLdXmtDataReg;
              rd = 4'hf;
              channelCountNext = 3'b000;
           end
        end
        eLdXmtDataReg: begin
           nextState = eByteReady;
           ldXmtDataReg = 1'b1;
        end
        eByteReady: begin
           nextState = eTByte;
           byteReady = 1'b1;
        end
        eTByte: begin
           nextState = eWiatForTxDone;
           tByte = 1'b1;
        end
        eWiatForTxDone: begin
           if(txDone) begin
              if(channelCount == 3'b111)begin
                 nextState = eInit;
              end
              else begin
                 nextState = eLdXmtDataReg;
                 channelCountNext = channelCount + 1'b1;
              end
           end
        end
      endcase // case (currState)
   end

   assign dataBus = fifoOutArr[channelCount];

   uart_transmitter
     #(
       .DVSR      (347     )
       ,.WORD_SIZE (8      ))
   uart_transmitter0
     (
      .clk           (clk40M       )
      ,.nRST         (nRst         )
      ,.serialOut    (serialOut    )
      ,.dataBus      (dataBus      )
      ,.byteReady    (byteReady    )
      ,.ldXmtDataReg (ldXmtDataReg )
      ,.tByte        (tByte        )
      ,.txDone       (txDone       ));

endmodule // image_buffer_top
