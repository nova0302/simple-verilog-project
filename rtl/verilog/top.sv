

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

   logic [0:4][7:0] uartRcvDataArr;
   always_ff@(posedge clk40M, negedge nRst) begin
      if(!nRst)
        currState <= eCmd;
      else
        currState <= nextState;
   end

   logic[7:0]pout;
   logic mem_wr_req;
   always_ff@(posedge clk40M) begin
      if(mem_wr_req)
        uartRcvDataArr[currState] <= pout;
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
           if(rcvDataValid && (pout == 8'hA0 || pout == 8'hA1 || pout == 8'hA2))begin
              nextState  = eAddrLsb;
              mem_wr_req = 1'b1;
           end
        end
        eAddrLsb: begin
           nextState  = eAddrMsb;
           mem_wr_req = 1'b1;
        end
        eAddrMsb: begin
           nextState  = eDataLsb;
           mem_wr_req = 1'b1;
        end
        eDataLsb: begin
           nextState = eDataMsb;
           mem_wr_req    = 1'b1;
        end
        eDataMsb: begin
           nextState = eCmd;
           mem_wr_req    = 1'b1;
           cmdUpdateNext = 1'b0;
        end
      endcase // case (currState)
   end // always_comb

   wire[7:0] cmd     = uartRcvDataArr[0];
   wire[7:0] addrLsb = uartRcvDataArr[1];
   wire[7:0] addrMsb = uartRcvDataArr[2];
   wire[7:0] dataLsb = uartRcvDataArr[3];
   wire[7:0] dataMsb = uartRcvDataArr[4];

   uart_receiver
     #(.DVSR(DVSR))
   uart_receiver0
     (
       .clk              (clk40M        )
      ,.reset            (~nRst         )
      ,.rx               (uart_rx       ) // rx serial data from pc
      ,.ready            (              )
      ,.rcvDataValid     (rcvDataValid  )
      ,.pout             (pout          ));

   enum {eSpiIdle, eSpiAddrLsb, eSpiAddrMsb, eSpiDataLsb, eSpiDataMsb}spiState, spiStateNext;
   logic [7:0] spi_tx_byte;
   logic       spi_dv;
   logic       spi_tx_ready;
   always_ff@(posedge clk40M, negedge nRst)begin
      if(!nRst)
        spiState <= eSpiIdle;
      else
        spiState <= spiStateNext;
   end
   always_comb begin
      spi_dv = 1'b0;
      spiStateNext = eSpiIdle;
      case(spiState)
        eSpiIdle: begin
           if(cmdUpdate && cmd == 8'hA1)
             spiStateNext = eSpiAddrLsb;
        end
        eSpiAddrLsb: begin
           spiStateNext = eSpiAddrMsb;
           spi_tx_byte = addrLsb;
           spi_dv      = 1'b1;
        end
        eSpiAddrMsb: begin
           if(spi_tx_ready)begin
              spiStateNext = eSpiDataLsb;
              spi_tx_byte = addrMsb;
              spi_dv = 1'b1;
           end
        end
        eSpiDataLsb: begin
           if(spi_tx_ready)begin
              spiStateNext = eSpiDataMsb;
              spi_tx_byte = addrLsb;
              spi_dv = 1'b1;
           end
        end
        eSpiDataMsb: begin
           if(spi_tx_ready)begin
              spiStateNext = eSpiIdle;
              spi_tx_byte = addrLsb;
              spi_dv = 1'b1;
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
