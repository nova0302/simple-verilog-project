

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
    );

   localparam LVDS_RCV_BUF_SIZE = 3;

   logic [LVDS_RCV_BUF_SIZE-1:0][15:0]ch0;
   always_ff@(posedge lvds_clk)begin
      ch0 <= {ch0[LVDS_RCV_BUF_SIZE-2:0], lvds_ch0};
   end
   wire validPreamble = (ch0[2] == 16'hFFFF &&
                         ch0[1] == 16'hFFFF &&
                         ch0[0] == 16'hAAAA);


   wire cmdUpdate;
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
    ,  .dataMsb  (dataMsb  )
    );

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
   , .miso     (miso     )
   );







endmodule // top
