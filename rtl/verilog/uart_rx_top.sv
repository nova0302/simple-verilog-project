
module uart_rx_top
   (input clk40M
    ,input nRst
    ,input serialIn

    ,output bit   cmdUpdate
    ,output[7:0]       cmd
    ,output[7:0]       addrLsb
    ,output[7:0]       addrMsb
    ,output[7:0]       dataLsb
    ,output[7:0]       dataMsb
    );

   localparam DVSR = 22;

   enum   {eCmd, eAddrLsb, eAddrMsb, eDataLsb, eDataMsb, eCmdUpdate}currState, nextState;

   always_ff@(posedge clk40M, negedge nRst) begin
      if(!nRst)
        currState <= eCmd;
      else
        currState <= nextState;
   end

   logic[7:0]pout;
   logic     mem_wr_req;
   logic [0:4][7:0] uartRcvDataArr;
   logic [2:0]      uartRcvDataArrIndex;

   assign        cmd     = uartRcvDataArr[0];
   assign        addrLsb = uartRcvDataArr[1];
   assign        addrMsb = uartRcvDataArr[2];
   assign        dataLsb = uartRcvDataArr[3];
   assign        dataMsb = uartRcvDataArr[4];

   always_ff@(posedge clk40M) begin
      if(mem_wr_req)
        uartRcvDataArr[uartRcvDataArrIndex] <= pout;
   end

   bit cmdUpdateNext;
   always_ff@(posedge clk40M, negedge nRst)begin
      if(!nRst)
        cmdUpdate <= 1'b0;
      else
        cmdUpdate <= cmdUpdateNext;
   end

   logic rcvDataValid;
   always_comb begin
      nextState = currState;
      mem_wr_req    = 1'b0;
      cmdUpdateNext = 1'b0;
      uartRcvDataArrIndex = 3'b000;
      case(currState)
        eCmd: begin
           if(rcvDataValid
              //              && (spiState == eSpiIdle)
              && (pout == 8'hA0 || pout == 8'hA1 || pout == 8'hA2))begin
              nextState  = eAddrLsb;
              mem_wr_req = 1'b1;
              uartRcvDataArrIndex = 3'b000;
           end
        end
        eAddrLsb: begin
           if(rcvDataValid) begin
              nextState  = eAddrMsb;
              mem_wr_req = 1'b1;
              uartRcvDataArrIndex = 3'b001;
           end
        end
        eAddrMsb: begin
           if(rcvDataValid) begin
              nextState  = eDataLsb;
              mem_wr_req = 1'b1;
              uartRcvDataArrIndex = 3'b010;
           end
        end
        eDataLsb: begin
           if(rcvDataValid) begin
              nextState = eDataMsb;
              mem_wr_req    = 1'b1;
              uartRcvDataArrIndex = 3'b011;
           end
        end
        eDataMsb: begin
           if(rcvDataValid) begin
              nextState = eCmdUpdate;
              mem_wr_req    = 1'b1;
              uartRcvDataArrIndex = 3'b100;
           end
        end
        eCmdUpdate: begin
           nextState = eCmd;
           cmdUpdateNext = 1'b1;
        end
      endcase // case (currState)
   end // always_comb

   uart_receiver
     #(.DVSR(DVSR))
   uart_receiver0
     ( .clk              (clk40M        )
       ,.reset           (~nRst         )
       ,.rx              (serialIn      ) // rx serial data from pc
       ,.ready           (              )
       ,.rcvDataValid    (rcvDataValid  )
       ,.pout            (pout          ));

endmodule // uart_rx_top
