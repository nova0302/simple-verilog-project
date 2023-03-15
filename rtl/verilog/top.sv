

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
   ,input  miso
   );

   //localparam DVSR              = 22; // for 115200 with 40MHz clk

   localparam SPI_MODE          =  3;
   localparam LSB_FIRST         =  1; // according ADDI data sheet
   localparam CLKS_PER_HALF_BIT =  8; // 40Mhz / 16 = 2.5Mhz
   localparam MAX_BYTES_PER_CS  =  4; // 4 bytes per a transaction
   localparam CS_INACTIVE_CLKS  =  1;

   enum {eCmd, eAddrLsb, eAddrMsb, eDataLsb, eDataMsb}currState, nextState;
   enum       {eSpiIdle, eSpiSetupData, eSpiWaitForReady}spiState, spiStateNext;

   logic [0:4][7:0] uartRcvDataArr;
   always_ff@(posedge clk40M, negedge nRst) begin
      if(!nRst)
        currState <= eCmd;
      else
        currState <= nextState;
   end

   logic[7:0]pout;
   logic     mem_wr_req;
   always_ff@(posedge clk40M) begin
      if(mem_wr_req)
        uartRcvDataArr[currState] <= pout;
      /*
        case(currState)
          eCmd:     uartRcvDataArr[0] <= pout;
          eAddrLsb: uartRcvDataArr[1] <= pout;
          eAddrMsb: uartRcvDataArr[2] <= pout;
          eDataLsb: uartRcvDataArr[3] <= pout;
          eDataMsb: uartRcvDataArr[4] <= pout;
        endcase
      */
   end

   reg cmdUpdate, cmdUpdateNext;
   always_ff@(posedge clk40M, negedge nRst)begin
      if(!nRst)
        cmdUpdate <= 1'b0;
      else
        cmdUpdate <= cmdUpdateNext;
   end

   logic rcvDataValid;
   always_comb begin
      mem_wr_req    = 1'b0;
      cmdUpdateNext = 1'b0;
      case(currState)
        eCmd: begin
           if(rcvDataValid
              && (spiState == eSpiIdle)
              && (pout == 8'hA0 || pout == 8'hA1 || pout == 8'hA2))begin
              nextState  = eAddrLsb;
              mem_wr_req = 1'b1;
           end
        end
        eAddrLsb: begin
           if(rcvDataValid) begin
              nextState  = eAddrMsb;
              mem_wr_req = 1'b1;
           end
        end
        eAddrMsb: begin
           if(rcvDataValid) begin
              nextState  = eDataLsb;
              mem_wr_req = 1'b1;
           end
        end
        eDataLsb: begin
           if(rcvDataValid) begin
              nextState = eDataMsb;
              mem_wr_req    = 1'b1;
           end
        end
        eDataMsb: begin
           if(rcvDataValid) begin
              nextState = eCmd;
              mem_wr_req    = 1'b1;
              cmdUpdateNext = 1'b1;
           end
        end
      endcase // case (currState)
   end // always_comb

   wire[7:0] cmd     = uartRcvDataArr[0];
   wire [7:0] addrLsb = uartRcvDataArr[1];
   wire [7:0] addrMsb = uartRcvDataArr[2];
   wire [7:0] dataLsb = uartRcvDataArr[3];
   wire [7:0] dataMsb = uartRcvDataArr[4];

   uart_receiver
     #(.DVSR(DVSR))
   uart_receiver0
     (
      .clk              (clk40M        )
      ,.reset           (~nRst         )
      ,.rx              (uart_rx       ) // rx serial data from pc
      ,.ready           (              )
      ,.rcvDataValid    (rcvDataValid  )
      ,.pout            (pout          ));

   logic [7:0] spi_tx_byte ;
   logic       spi_tx_dv, spi_tx_dv_next;
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
           if(cmdUpdate && cmd == 8'hA1)begin
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
     (
      .i_Rst_L          (nRst        )
      ,.i_Clk            (clk40M      )

      ,.i_TX_Count       (r_Master_TX_Count  )
      ,.i_TX_Byte        (spi_tx_byte   )
      ,.i_TX_DV          (spi_tx_dv     )
      ,.o_TX_Ready       (spi_tx_ready  )

      ,.o_RX_Count       ()
      ,.o_RX_DV          ()
      ,.o_RX_Byte        ()

      ,.o_SPI_Clk        (spi_clk     )
      ,.i_SPI_MISO       (miso        )
      ,.o_SPI_MOSI       (mosi        )
      ,.o_SPI_CS_n       (sl          ));






endmodule // top
