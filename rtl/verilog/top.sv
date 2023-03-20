

module top
  #(parameter DVSR = 22)
   (
    input clk25M
    ,input clk40M
    ,input nRst
    ,input uart_rx
    ,output uart_tx

    ,output spi_clk
    ,output sl
    ,output mosi
    ,input miso

    ,input lvds_clk
    ,input[15:0] lvds_ch0
    ,input[15:0] lvds_ch1
    ,input[15:0] lvds_ch2
    ,input[15:0] lvds_ch3
    );



   wire [7:0] cmd;
   wire [7:0] addrLsb;
   wire [7:0] addrMsb;
   wire [7:0] dataLsb;
   wire [7:0] dataMsb;

   uart_rx_top
     uart_rx_top0
       (   .clk40M   (clk40M   )
           ,  .nRst     (nRst     )
           ,  .serialIn (uart_rx  )
           ,  .cmdUpdate(cmdUpdate)
           ,  .cmd      (cmd      )
           ,  .addrLsb  (addrLsb  )
           ,  .addrMsb  (addrMsb  )
           ,  .dataLsb  (dataLsb  )
           ,  .dataMsb  (dataMsb  ));

   spi_master_top
     spi_master_top0
       (  .clk40M   (clk40M   )
          , .nRst     (nRst     )

          , .cmdUpdate(cmdUpdate)
          , .i_cmd    (cmd    )
          , .i_addrLsb(addrLsb)
          , .i_addrMsb(addrMsb)
          , .i_dataLsb(dataLsb)
          , .i_dataMsb(dataMsb)

          , .spi_clk  (spi_clk  )
          , .sl       (sl       )
          , .mosi     (mosi     )
          , .miso     (miso     ));

   logic [3:0] rd = 1'b0;
   wire [3:0]  empty;
   logic [3:0][15:0] lvds_ch;
   assign lvds_ch[0] = lvds_ch0;
   assign lvds_ch[1] = lvds_ch1;
   assign lvds_ch[2] = lvds_ch2;
   assign lvds_ch[3] = lvds_ch3;
   logic [3:0][15:0] fifoOut;
   logic [1:0]       channelCount, channelCountNext;

   genvar      i;
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
   always_ff@(posedge clk40M, negedge nRst)begin
      if(~nRst)
        currState <= eInit;
      else
        currState <= nextState;
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
              channelCountNext = 2'b00;
           end
        end
        eLdXmtDataReg: begin
           nextState = eByteReady;
           ldXmtDataReg = 1'b0;
        end
        eByteReady: begin
           nextState = eTByte;
           byteReady = 1'b0;
        end
        eTByte: begin
           nextState = eWiatForTxDone;
           tByte = 1'b1;
        end
        eWiatForTxDone: begin
           if(txDone) begin
              if(channelCount<4)begin
                 channelCountNext = channelCount + 1'b1;
                 nextState = eLdXmtDataReg;
              end
              else begin
                 nextState = eInit;
              end
           end
        end
      endcase // case (currState)
   end

   assign dataBus = fifoOut[channelCount];

   uart_transmitter
     #(
       .DVSR      (347     )
       ,.WORD_SIZE (8      ))
   uart_transmitter0
     (
      .clk           (clk40M       )
      ,.nRST         (nRst         )
      ,.serialOut    (uart_tx      )
      ,.dataBus      (dataBus      )
      ,.byteReady    (byteReady    )
      ,.ldXmtDataReg (ldXmtDataReg )
      ,.tByte        (tByte        )
      ,.txDone       (txDone       ));

endmodule // top
