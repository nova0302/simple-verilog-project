
module FPGA_RX (output serialOut);
   timeunit 1ns;
   timeprecision 1ns;


   bit  clk;
   bit  reset;
   bit  rx;
   bit  ready         ;
   bit  rcvDataValid;
   wire[7:0]  pout;
   bit        msbFirst = 1'b1;
   bit        start = 1'b1;
   logic [1:0] cdiv = 2'b01;


   uart_receiver #(52)
   uart_receiver0
     (
      .clk            (clk          )
      ,.reset         (reset        )
      ,.rx            (rx           )
      ,.ready         (ready        )
      ,.rcvDataValid  (rcvDataValid )
      ,.pout          (pout         ));


   enum   {eCmd, eAddress, eDataLsb, eDataMsb, eDataValid}currState, nextState;
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


   spi_master
     spi_master0
       (
        .rstb  (!reset     )
        ,.clk   (clk       )
        ,.mlb   (msbFirst  )
        ,.start (start     )
        ,.tdat  ({dataMsb, dataLsb} )
        ,.cdiv  (cdiv      )
        ,.din   (din       )
        // .ss(ss),
        ,.sck   (sck       )
        ,.dout  (dout      )
        ,.done  (Mdone     )
        ,.rdata ());




endmodule
