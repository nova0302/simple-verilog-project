`define fun_sim

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

`ifdef fun_sim
   localparam DELAY_500US  =  20;
   localparam DELAY_100US  =  5;
`else
   localparam DELAY_500US  =  20000;
   localparam DELAY_100US  =  5000;
`endif

   enum   {eSpiInit, eSpiInit1, eSpiInitWait, eSpiInitDly, eSpiIdle, eSpiChkCmd, eSpiSetupData, eSpiWaitForReady}spiState, spiStateNext;

   logic [0:4][7:0] uartRcvDataArr;
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
   always_ff@(posedge clk40M, negedge nRst)begin
      if(!nRst)
        spiState       <= eSpiInit;
      else
        spiState <= spiStateNext;
   end

   always_ff@(posedge clk40M) begin
      spi_tx_ready_dly <= spi_tx_ready;
   end

   //integer     initDataIndex, initDataIndexNext;
   logic[3:0]     initDataIndex, initDataIndexNext;
   always_ff@(posedge clk40M, negedge nRst)begin
      if(!nRst)
        initDataIndex <= 0;
      else
        initDataIndex <= initDataIndexNext;
   end

   logic [0:9][15:0] initAddr=
              '{16'h0030, 16'h00f3, 16'h00f9, 16'h0000, 16'h0001,
                16'h0033, 16'h00a0, 16'h00a2, 16'h0038, 16'h0031};

   logic [0:9][15:0] initData=
              '{16'h0001, 16'h0000, 16'hc007, 16'h0000, 16'h0000,
                16'h0001, 16'h0000, 16'h0001, 16'h0000, 16'h0001};

   logic[0:3][7:0] spi_tx_byte_array, spi_tx_byte_array_next;
   always_ff@(posedge clk40M, negedge nRst)begin
      if(!nRst)
        spi_tx_byte_array <= '{8'h00, 8'h00, 8'h00, 8'h00};
      else
        spi_tx_byte_array <= spi_tx_byte_array_next;
   end

   bit spiTxStart;
   bit spiTxDone;

   wire spi_ready = spi_tx_ready & ~spi_tx_ready_dly;

   integer delayCounter, delayCounterNext;
   always_ff@(posedge clk40M, negedge nRst) begin
      if(!nRst)
        delayCounter <= 0;
      else
        delayCounter <= delayCounterNext;
   end

   always_comb begin
      spiStateNext = spiState;
      initDataIndexNext = initDataIndex;
      delayCounterNext = delayCounter;
      spi_tx_byte_array_next = spi_tx_byte_array;
      spiTxStart = 1'b0;

      case(spiState)

        eSpiInit: begin
           spiStateNext = eSpiInit1;
           spi_tx_byte_array_next[0] = initAddr[initDataIndex][7:0];
           spi_tx_byte_array_next[1] = initAddr[initDataIndex][15:8];
           spi_tx_byte_array_next[2] = initData[initDataIndex][7:0];
           spi_tx_byte_array_next[3] = initData[initDataIndex][15:8];
        end

        eSpiInit1: begin
           spiStateNext = eSpiInitWait;
           spiTxStart = 1'b1;
        end

        eSpiInitWait:begin
           if(spiTxDone)begin
              if(initDataIndex == 9)
                spiStateNext = eSpiIdle;
              else if(initDataIndex == 3 || initDataIndex == 4)
                spiStateNext = eSpiInitDly;
              else
                spiStateNext = eSpiInit;

              if(initDataIndex < 9) initDataIndexNext = initDataIndex + 1;
              if(initDataIndex == 3) delayCounterNext = DELAY_500US; //500us
              if(initDataIndex == 4) delayCounterNext = DELAY_100US;
           end // if (spi_ready)
        end
        eSpiInitDly: begin
           if(delayCounter > 0)
             delayCounterNext = delayCounter - 1;
           if(delayCounter < 1)
             spiStateNext = eSpiInit;
        end

        eSpiIdle: begin
           if(cmdUpdate)
             spiStateNext       = eSpiChkCmd;
        end
        eSpiChkCmd: begin
           if(cmd == 8'hA1)begin
              spiStateNext       = eSpiSetupData;
              spi_tx_byte_array_next = uartRcvDataArr[1:4];
           end
           else begin
              spiStateNext = eSpiIdle;
           end
        end
        eSpiSetupData: begin
           spiStateNext = eSpiWaitForReady;
           spiTxStart = 1'b1;
        end
        eSpiWaitForReady: begin
           //if(spi_ready)
           if(spiTxDone)
             spiStateNext = eSpiIdle;
        end
      endcase // case (spiState)
   end // always_comb

   enum {eSpiTxIdle, eSpiTxSetupData, eSpiTxWaitForSpiReady}spiTxState, spiTxStateNext;
   always_ff@(posedge clk40M, negedge nRst) begin
      if(!nRst)
        spiTxState <= eSpiTxIdle;
      else
        spiTxState <= spiTxStateNext;
   end
   logic [1:0] spiTxByteIndex, spiTxByteIndexNext;
   always_ff@(posedge clk40M, negedge nRst) begin
      if(!nRst)
        spiTxByteIndex <= 2'b00;
      else
        spiTxByteIndex <= spiTxByteIndexNext;
   end

   always_comb begin
      spi_tx_dv =1'b0;
      spi_tx_byte  = 8'h00;
      spiTxStateNext = spiTxState;
      spiTxByteIndexNext = spiTxByteIndex;
      spiTxDone =1'b0;
      case(spiTxState)
        eSpiTxIdle: begin
           if(spiTxStart)begin
              spiTxStateNext = eSpiTxSetupData;
              spiTxByteIndexNext = 2'b00;
           end

        end
        eSpiTxSetupData: begin
           spiTxStateNext = eSpiTxWaitForSpiReady;
           spi_tx_byte = spi_tx_byte_array[spiTxByteIndex];
           spi_tx_dv =1'b1;
        end
        eSpiTxWaitForSpiReady: begin
           if(spi_ready) begin
              if(spiTxByteIndex == 3)
                spiTxStateNext = eSpiTxIdle;
              else
                spiTxStateNext = eSpiTxSetupData;
              if(spiTxByteIndex == 3) spiTxDone =1'b1;
              if(spiTxByteIndex < 3) spiTxByteIndexNext = spiTxByteIndex + 1'b1;
           end
        end
      endcase // case (spiTxState)
   end

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
