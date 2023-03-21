/*
 *  cmd
 * A0 -> TG
 * A1 -> spi
 * A2 -> image buffer
 */

module top_tb;

   timeunit 1ns;
   timeprecision 100ps;

   localparam real T_40Mhz   = 25;
   localparam real T_1Mhz   = 1000;
   //localparam DVSR      = 22;
   //localparam DVSR      = 174;
   localparam DVSR      = 347;
   //localparam DVSR1     = 11;
   localparam DVSR1     = 22;
   localparam WORD_SIZE =  8;

   bit clk25M = 1'b0;
   bit nRst   = 1'b0;

   wire rcvDataValid;
   wire [7:0] pout;

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


   bit clk40M = 1'b0;
   bit lvds_clk = 1'b0;
   logic [15:0] lvds_ch0;

   always #(T_40Mhz/2) clk40M = ~clk40M;
   task task_uart_tx (input [7:0] txData);
      begin
         {ldXmtDataReg, byteReady, tByte} <= 3'b100;
         dataBus <= txData;
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

   task task_lvds(input[15:0] pixel);
      begin
         @(posedge lvds_clk); lvds_ch0 <= pixel;
      end
   endtask // task_lvds

   always #(T_1Mhz/2) lvds_clk = ~lvds_clk;

   //logic     CLI;
   initial begin
      repeat(3) @(posedge clk40M);
      #15 nRst <= 1'b1;
      repeat(1) @(posedge clk40M);
      task_uart_tx(8'hab); @(txDone);
      task_uart_tx(8'ha2); @(txDone);
      task_uart_tx(8'ha0); @(txDone);
      task_uart_tx(8'ha1); @(txDone);
      task_uart_tx(8'hd0); @(txDone);
      task_uart_tx(8'hd2); @(txDone);
      repeat(30) @(posedge clk40M);
      task_lvds(16'h0000);
      task_lvds(16'hffff);
      task_lvds(16'hffff);
      task_lvds(16'haaaa);
      task_lvds(16'h0000);
      task_lvds(16'h0001);
      task_lvds(16'h0002);
      task_lvds(16'h0003);
      task_lvds(16'h0004);
      task_lvds(16'h0005);
      task_lvds(16'h0006);
      task_lvds(16'h0007);
      task_lvds(16'h0008);
      task_lvds(16'h0009);
      task_lvds(16'h000a);
      task_lvds(16'h000b);
      task_lvds(16'h000c);
      task_lvds(16'h000d);
      task_lvds(16'h000e);
      task_lvds(16'h000f);
      task_lvds(16'h000a);
      repeat(128) begin
         @(posedge rcvDataValid);
         $display("%0t - rcvData: 0x%0h", $time, pout);
      end
      repeat(3000) @(posedge clk40M);
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

      ,.lvds_clk   (lvds_clk )
      ,.lvds_ch0   (lvds_ch0 )
      ,.lvds_ch1   (lvds_ch0 )
      ,.lvds_ch2   (lvds_ch0 )
      ,.lvds_ch3   (lvds_ch0 )

      );

   uart_receiver
     #(.DVSR(DVSR1))
   uart_receiver0
     ( .clk              (clk40M        )
       ,.reset           (~nRst         )
       ,.rx              (uart_tx       ) // rx serial data from pc
       ,.ready           (              )
       ,.rcvDataValid    (rcvDataValid  )
       ,.pout            (pout          ));


endmodule // top
