
module spi_master_top
  (input clk40M
   ,input nRst

   ,input cmdUpdate
   ,input[7:0]       i_cmd
   ,input[7:0]       i_addrLsb
   ,input[7:0]       i_addrMsb
   ,input[7:0]       i_dataLsb
   ,input[7:0]       i_dataMsb

   ,output spi_clk
   ,output sl
   ,output mosi
   ,input miso

   );

   localparam SPI_MODE          =  3;
   localparam LSB_FIRST         =  1; // according ADDI data sheet
   localparam CLKS_PER_HALF_BIT =  8; // 40Mhz / 16 = 2.5Mhz
   localparam MAX_BYTES_PER_CS  =  4; // 4 bytes per a transaction
   localparam CS_INACTIVE_CLKS  =  1;

   enum   {eSpiIdle, eSpiIdle1, eSpiSetupData, eSpiWaitForReady}spiState, spiStateNext;

   logic [4:0][7:0] uartRcvDataArr;
   always_ff@(posedge clk40M)begin
      if(cmdUpdate)begin
         uartRcvDataArr[0]  <= i_cmd      ;
         uartRcvDataArr[1]  <= i_addrLsb  ;
         uartRcvDataArr[2]  <= i_addrMsb  ;
         uartRcvDataArr[3]  <= i_dataLsb  ;
         uartRcvDataArr[4]  <= i_dataMsb  ;
      end
   end
   wire[7:0] cmd = uartRcvDataArr[0];

   logic [7:0] spi_tx_byte ;
   logic       spi_tx_dv ;
   logic       spi_tx_ready, spi_tx_ready_dly;
   logic [2:0] spiTxDataIndex;
   logic       resetIndex, increaseIndex;
   always_ff@(posedge clk40M, negedge nRst)begin
      if(!nRst)begin
         spiState       <= eSpiIdle;
         spiTxDataIndex <= 3'b001;
      end
      else begin
         spiState <= spiStateNext;

         if(resetIndex)
           spiTxDataIndex   <= 3'b001;
         else if(increaseIndex)
           spiTxDataIndex <= spiTxDataIndex + 1;

         spi_tx_ready_dly <= spi_tx_ready;
      end
   end

   always_comb begin
      spi_tx_byte = 8'h00;
      spi_tx_dv= 1'b0;
      spiStateNext = eSpiIdle;
      resetIndex = 1'b0;
      increaseIndex = 1'b0;
      case(spiState)
        eSpiIdle: begin
           if(cmdUpdate)begin
              spiStateNext       = eSpiIdle1;
           end
        end
        eSpiIdle1: begin
           if(cmd == 8'hA1)begin
              spiStateNext       = eSpiSetupData;
              resetIndex = 1'b1;
           end
        end
        eSpiSetupData: begin
           spiStateNext = eSpiWaitForReady;
           spi_tx_byte = uartRcvDataArr[spiTxDataIndex];
           spi_tx_dv   = 1'b1;
        end
        eSpiWaitForReady: begin
           if(spi_tx_ready && !spi_tx_ready_dly)begin
              if(spiTxDataIndex == 4)begin
                 spiStateNext = eSpiIdle;
              end
              else begin
                 spiStateNext = eSpiSetupData;
                 increaseIndex = 1'b1;
              end
           end
           else begin
              spiStateNext = eSpiWaitForReady;
           end
        end
      endcase // case (spiState)
   end // always_comb

   logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] w_Master_RX_Count, r_Master_TX_Count = 3'b100;
   SPI_Master_With_Single_CS
     #(  .SPI_MODE          (SPI_MODE          )
         ,.LSB_FIRST        (LSB_FIRST         )
         ,.CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT )
         ,.MAX_BYTES_PER_CS (MAX_BYTES_PER_CS  )
         ,.CS_INACTIVE_CLKS (CS_INACTIVE_CLKS  ))
   SPI_Master_With_Single_CS0
     ( .i_Rst_L          (nRst             )
       ,.i_Clk            (clk40M           )

       ,.i_TX_Count       (r_Master_TX_Count)
       ,.i_TX_Byte        (spi_tx_byte      )
       ,.i_TX_DV          (spi_tx_dv        )
       ,.o_TX_Ready       (spi_tx_ready     )

       ,.o_RX_Count       (w_Master_RX_Count)
       ,.o_RX_DV          (                 )
       ,.o_RX_Byte        (                 )

       ,.o_SPI_Clk        (spi_clk          )
       ,.i_SPI_MISO       (miso             )
       ,.o_SPI_MOSI       (mosi             )
       ,.o_SPI_CS_n       (sl               ));

endmodule // spi_master_top
