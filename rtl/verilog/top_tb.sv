

module top_tb;

   timeunit 1ns;
   timeprecision 100ps;

   localparam real T_40Mhz   = 25;
   //localparam DVSR      = 22;
   localparam DVSR      = 174;
   localparam DVSR1     = 11;
   localparam WORD_SIZE =  8;

   bit clk25M = 1'b0;
   bit clk40M = 1'b0;
   bit nRst   = 1'b0;

   wire  uart_rx ;
   wire  uart_tx;
   wire  spi_clk;
   wire  sl;
   wire  mosi      ;
   wire  miso = mosi;

   reg   ldXmtDataReg;
   reg   byteReady;
   reg   tByte;
   reg   txDone;
   reg[7:0]   dataBus;


   task task_uart_tx (input [7:0] txData);
      begin
         {ldXmtDataReg, byteReady, tByte} <= 3'b000;
         dataBus <= txData;
         @(posedge clk40M);
         {ldXmtDataReg, byteReady, tByte} <= 3'b100;
         @(posedge clk40M);
         {ldXmtDataReg, byteReady, tByte} <= 3'b010;
         @(posedge clk40M);
         {ldXmtDataReg, byteReady, tByte} <= 3'b001;
         @(posedge clk40M);
         {ldXmtDataReg, byteReady, tByte} <= 3'b000;
         dataBus <= 8'h00;
         @(posedge clk40M);
      end
   endtask // task_uart_tx

   always #(T_40Mhz/2) clk40M = ~clk40M;

   //logic     CLI;
   initial begin
      repeat(3) @(posedge clk40M);
      #15 nRst <= 1'b1;
      repeat(1) @(posedge clk40M);
      task_uart_tx(8'hab);
      @(txDone);
      task_uart_tx(8'ha1);
      @(txDone);
      task_uart_tx(8'ha1);
      @(txDone);
      task_uart_tx(8'ha0);
      @(txDone);
      task_uart_tx(8'hd1);
      @(txDone);
      task_uart_tx(8'hd0);
      @(txDone);
      repeat(3000) @(posedge clk40M);
      $finish;
   end

   uart_transmitter
     #(
        .DVSR      (DVSR     )
       ,.WORD_SIZE (WORD_SIZE))
   uart_transmitter0
     (
      .clk           (clk40M       )
      ,.nRST         (nRst         )
      ,.serialOut    (uart_rx      )
      ,.dataBus      (dataBus      )
      ,.byteReady    (byteReady    )
      ,.ldXmtDataReg (ldXmtDataReg )
      ,.tByte        (tByte        )
      ,.txDone       (txDone       ));

   top #(.DVSR      (DVSR1     ))
   dut
     (
      .clk25M  (clk25M )
      ,.clk40M (clk40M )
      ,.nRst   (nRst   )
      ,.uart_rx(uart_rx)
      ,.uart_tx(uart_tx)
      ,.spi_clk(spi_clk)
      ,.sl     (sl     )
      ,.mosi   (mosi   )
      ,.miso   (miso   )
      );


endmodule // top
