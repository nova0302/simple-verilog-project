

module top
  (
   input clk25M//, nRst

   ,input uart_rx//, nRst
   ,output uart_tx//, nRst

   //, output bit CLI
   ,output spi_clk//, nRst
   ,output sl
   ,output mosi
   ,input  miso//, nRst
   );

   timeunit 1ns;
   timeprecision 100ps;

   localparam T_40Mhz = 25; // 1MHz

   localparam DVSR              = 22; // for 115200 with 40MHz clk

   localparam SPI_MODE          =  3;
   localparam LSB_FIRST         =  1; // according ADDI data sheet
   localparam CLKS_PER_HALF_BIT =  8; // 40Mhz / 16 = 2.5Mhz
   localparam MAX_BYTES_PER_CS  =  4; // 4 bytes per a transaction
   localparam CS_INACTIVE_CLKS  =  1;


   bit   clk40M= 1'b0;
   always #(T_40Mhz/2) clk40M = ~clk40M;

   //logic     CLI;
   bit   nRst = 1'b0;

   initial begin
      repeat(3) @(posedge CLI);
      #15 nRst <= 1'b1;
      repeat(3000) @(posedge CLI);
      $finish;
   end

   enum {eCmd,, eAddrLsb, eAddrMsb, eDataLsb, eDataMsb}currState, nextState;

   logic [0:4][7:0] uartRcvDataArr;
   always_ff@(posedge clk40M, negedge nRst) begin
      if(!nRst)
        currState <= eCmd;
      else
        currState <= nextState;
   end

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

   always_comb begin
      mem_wr_req    = 1'b0;
      cmdUpdateNext = 1'b0;
      case(currState)
        eCmd: begin
           if(rcvDataValid && (pout == 8'bhA0 || pout == 8'hA1 || pout == 8'hA2))begin
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
      end

   wire cmd     = uartRcvDataArr[0];
   wire addrLsb = uartRcvDataArr[1];
   wire addrMsb = uartRcvDataArr[2];
   wire dataLsb = uartRcvDataArr[3];
   wire dataMsb = uartRcvDataArr[4];

   uart_receiver
     #(.DVSR(DVSR))
   uart_receiver0
     (
      .clk               (clk40M        )
      ,.reset            (~nRst         )
      ,.rx               (rx            ) // rx serial data from pc
      ,.ready            (              )
      ,.rcvDataValid     (rcvDataValid  )
      ,.pout             (pout          ));

   enum {eSpiIdle, eSpiAddrLsb, eSpiAddrMsg, eSpiDataLsb, eSpiDataMsb}spiCurrState, spiNextState;
   logic[7:0] spi_tx_byte;
   logic      spi_dv;
   logic      spi_tx_ready;
   always_ff@(posedge clk40M, negedge nRst)begin
      if(!nRst)
        spiCurrState <= eSpiIdle;
      else
        spiCurrState <= spiNextState;
   end
   always_comb begin
      spi_dv = 1'b0;
      spiNextState = eSpiIdle;
      case(spiCurrState)
        eSpiIdle: begin
           if(cmdUpdate && cmd == 8'hA1)
             spiNextState = eSpiAddrLsb;
        end
        eSpiAddrLsb: begin
           spiNextState = eSpiAddrMsb;
           spi_tx_byte = addrLsb;
           spi_dv      = 1'b1;
        end
        eSpiAddrMsg: begin
           if(spi_tx_ready)begin
              spiNextState = eSpiDataLsb;
              spi_tx_byte = addrMsb;
              spi_dv = 1'b1;
           end
        end
        eSpiDataLsb: begin
           if(spi_tx_ready)begin
              spiNextState = eSpiDataMsb;
              spi_tx_byte = addrLsb;
              spi_dv = 1'b1;
           end
        end
        eSpiDataMsb: begin
           if(spi_tx_ready)begin
              spiNextState = eSpiIdle;
              spi_tx_byte = addrLsb;
              spi_dv = 1'b1;
           end
        end
      end

   logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] w_Master_RX_Count, r_Master_TX_Count = 3'b100;
   SPI_Master_With_Single_CS
     #( .SPI_MODE          (SPI_MODE          )
        ,.LSB_FIRST        (LSB_FIRST         )
        ,.CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT )
        ,.MAX_BYTES_PER_CS (MAX_BYTES_PER_CS  )
        ,.CS_INACTIVE_CLKS (CS_INACTIVE_CLKS  ))
   SPI_Master_With_Single_CS0
     (
      ,.i_Rst_L          (nRst        )
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
