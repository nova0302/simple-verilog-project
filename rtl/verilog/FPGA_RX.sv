
module FPGA_RX (output serialOut);
   timeunit 1ns;
   timeprecision 1ns;

   bit  clk;
   bit  reset;
   bit  rx;
   bit  ready         ;
   bit  rcvDataValid;
   wire [7:0] pout;
   bit        msbFirst = 1'b1;
   bit        start    = 1'b1;
   logic [1:0] cdiv    = 2'b01;

   uart_receiver #(52)
   uart_receiver0
     (
       .clk           (clk          )
      ,.reset         (reset        )
      ,.rx            (rx           )
      ,.ready         (ready        )
      ,.rcvDataValid  (rcvDataValid )
      ,.pout          (pout         ));

   enum        {eCmd, eAddress, eDataLsb, eDataMsb, eDataValid}currState, nextState;
   always_ff@(posedge clk, posedge reset)begin
      if(reset)
        currState <= eCmd;
      else
        currState <= nextState;
   end

   logic[7:0] cmd;
   bit        ldCmd;
   always_ff@(posedge clk, posedge reset)begin
      if(reset)
        cmd <= 8'h0;
      else if(ldCmd)
        cmd <= pout;
   end

   logic[7:0] address;
   bit        ldAddress;
   always_ff@(posedge clk, posedge reset)begin
      if(reset)
        address <= 8'h0;
      else if(ldAddress)
        address <= pout;
   end

   logic[7:0] dataLsb;
   bit        ldDataLsb;
   always_ff@(posedge clk, posedge reset)begin
      if(reset)
        dataLsb <= 8'h0;
      else if(ldDataLsb)
        dataLsb <= pout;
   end

   logic[7:0] dataMsb;
   bit        ldDataMsb;
   always_ff@(posedge clk, posedge reset)begin
      if(reset)
        dataMsb <= 8'h0;
      else if(ldDataMsb)
        dataMsb <= pout;
   end

   bit        dataValid;
   always_comb begin
      nextState = currState;
      ldCmd = 1'b0;
      ldAddress = 1'b0;
      ldDataLsb = 1'b0;
      ldDataMsb = 1'b0;
      dataValid = 1'b0;
      case(currState)
        eCmd: begin
           if(rcvDataValid)begin
              ldCmd = 1'b1;
              nextState = eAddress;
           end
        end
        eAddress: begin
           if(rcvDataValid)begin
              ldAddress = 1'b1;
              nextState = eDataLsb;
           end
        end
        eDataLsb: begin
           if(rcvDataValid)begin
              ldDataLsb = 1'b1;
              nextState = eDataMsb;
           end
        end
        eDataMsb: begin
           if(rcvDataValid)begin
              ldDataMsb = 1'b1;
              nextState = eDataValid;
           end
        end
        eDataValid: begin
           dataValid = 1'b1;
           nextState = eCmd;
        end
      endcase // case (currState)
   end

   SPI_Master_With_Single_CS
     #(
        .SPI_MODE         (SPI_MODE         )
       ,.CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
       ,.MAX_BYTES_PER_CS (MAX_BYTES_PER_CS )
       ,.CS_INACTIVE_CLKS (CS_INACTIVE_CLKS ))
   SPI_Master_With_Single_CS0
     (
      .i_Rst_L (i_Rst_L)     // FPGA Reset
      ,.i_Clk  (i_Clk  )     // FPGA Clock

      // TX (MOSI) Signals
      ,.i_TX_Count(i_TX_Count)  // # bytes per CS low
      ,.i_TX_Byte (i_TX_Byte )      // Byte to transmit on MOSI
      ,.i_TX_DV   (i_TX_DV   )      // Data Valid Pulse with i_TX_Byte
      ,.o_TX_Ready(o_TX_Ready)      // Transmit Ready for next byte

      // RX (MISO) Signals
      ,.o_RX_Count(o_RX_Count)  // Index RX byte
      ,.o_RX_DV   (o_RX_DV   )  // Data Valid pulse (1 clock cycle)
      ,.o_RX_Byte (o_RX_Byte )  // Byte received on MISO

      // SPI Interface
      ,.o_SPI_Clk (o_SPI_Clk )
      ,.i_SPI_MISO(i_SPI_MISO)
      ,.o_SPI_MOSI(o_SPI_MOSI)
      ,.o_SPI_CS_n(o_SPI_CS_n));
   );

endmodule
