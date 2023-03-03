
module FPGA
  (
   output serialOut

   );

   timeunit 1ns;
   timeprecision 1ns;

   localparam ADDI_T  = 100;
   localparam UART_T  = 10;
   localparam FIFO_DEPTH  = 4;
   localparam FIFO_DATA_WIDTH = 16;

   wire [FIFO_DATA_WIDTH-1:0] fifoOut;
   bit                        addi_clk   = 1'b0;
   bit                        nRST = 1'b0;
   bit                        GO    = 1'b0;
   wire                       PUSH;
   wire [15:0]                PIXEL_DATA;
   wire                       full, empty;
   logic [15:0]               DIN;

   logic [4:0]                index = 0;
   logic [0:31]               fifo[15:0];

   bit                        uart_clk = 1'b0;
   bit                        rd = 1'b0;

   always #(UART_T/2) uart_clk = ~uart_clk; // 1 / (115200 * 16) = 1 / 1843200
   always #(ADDI_T/2) addi_clk = ~addi_clk;

   always@(posedge addi_clk, negedge nRST) begin
      if(!nRST)begin
         index <= 0;
      end
      else begin
         if(PUSH)begin
            fifo[index] <= PIXEL_DATA;
            index = index + 1;
         end
      end
   end

   task init_seq;
      repeat (2) begin
         @(posedge addi_clk);
         DIN <= 16'hFFFF;
      end
      @(posedge addi_clk);
      DIN <= 16'hAAAA;
   endtask // init_seq

   task t_go;
      while(!nRST);
      repeat (4) @(posedge addi_clk);
      GO  <= 1'b1;
      DIN <= 16'h0;
      init_seq;
      repeat (16)  begin
         @(posedge addi_clk);
         DIN <= DIN + 1;
      end
      repeat (4) @(posedge addi_clk);
   endtask // t_go


   initial begin
      repeat (3) begin
         t_go;
         repeat (100) @(posedge addi_clk);
         t_go;
         repeat (100) @(posedge addi_clk);
      end
   end

   initial begin
      repeat (3) @(posedge addi_clk);
      nRST <= 1'b1;
      repeat (300) @(posedge addi_clk);
      $finish;
   end

   pick #(5)
   pick0
     (
      .CLK        (addi_clk       )
      ,.nRST      (nRST     )
      ,.GO        (GO        )
      ,.DIN       (DIN       )
      ,.PUSH      (PUSH      )
      ,.PIXEL_DATA(PIXEL_DATA));

   fifo_async_top #(FIFO_DEPTH, FIFO_DATA_WIDTH)
   fifo_async_top0
     (
      .clkw    (addi_clk   )
      ,.resetw (~nRST      )
      ,.wr     (PUSH       )
      ,.full   (full       )
      ,.fifoIn (PIXEL_DATA )

      ,.clkr (uart_clk )
      ,.resetr   (~nRST    )
      ,.rd       (rd       )
      ,.empty    (empty    )
      ,.fifoOut  (fifoOut  ));

   enum   {eLdXmtDataReg, eByteReady, eTByte, eTxDone}currState, nextState;
   bit    byteReady, ldXmtDataReg, tByte, txDone;
   always_ff@(posedge uart_clk, negedge nRST)begin
      if(!nRST)
        currState  <= eLdXmtDataReg;
      else
        currState <= nextState;
   end

   bit selMsb = 1'b0;
   bit selMsbNext;
   always_ff@(posedge uart_clk, negedge nRST)
     if(!nRST)
       selMsb <= 1'b1;
     else
       selMsb <= selMsbNext;

   always_comb begin
      {ldXmtDataReg, byteReady, tByte, rd} = 4'b0000; // default value
      nextState = currState; //default state
      selMsbNext = selMsb;
      unique case(currState)
        eLdXmtDataReg:
          if(!empty)begin
             {ldXmtDataReg, byteReady, tByte, rd} = 4'b1001;
             nextState = eByteReady;
          end
        eByteReady:begin
           {ldXmtDataReg, byteReady, tByte, rd} = 4'b0100;
           nextState = eTByte;
        end
        eTByte:begin
           {ldXmtDataReg, byteReady, tByte, rd} = 4'b0010;
           nextState = eTxDone;
        end
        eTxDone:begin
           if(txDone)begin
              nextState = eLdXmtDataReg;
              selMsbNext = ~selMsb;
           end
        end
      endcase // unique case (currState)
   end // always_comb
   wire[7:0] dataBus = (selMsb) ? fifoOut[15:8] : fifoOut[7:0];

   uart_transmitter #(4,8)
   uart_transmitter0
     (
      .clk          (uart_clk         )
      ,.nRST        (nRST        )
      ,.serialOut   (serialOut   )
      ,.dataBus     (dataBus     )
      ,.byteReady   (byteReady   )
      ,.ldXmtDataReg(ldXmtDataReg)
      ,.tByte       (tByte       )
      ,.txDone      (txDone      ));


endmodule
