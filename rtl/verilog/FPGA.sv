
module FPGA (output serialOut);
   timeunit 1ns;
   timeprecision 1ns;

   localparam numChannel       = 4;
   localparam numPixel         = 16;
   localparam pixelWidth       = 16;
   localparam ADDI_T           = 100;
   localparam UART_T           = 10;
   localparam FIFO_DEPTH       = 4;
   localparam FIFO_DATA_WIDTH  = 16;

   wire [numChannel-1:0] [FIFO_DATA_WIDTH-1:0] fifoOut;
   bit                                         nRST = 1'b0;
   //wire                     PIXEL_VALID;
   wire [numChannel-1:0]                       PIXEL_VALID;
   //wire [15:0]              PIXEL_DATA;
   wire [numChannel-1:0][15:0]                 PIXEL_DATA;
   wire [numChannel-1:0]                       full;
   wire [numChannel-1:0]                       empty;
   logic [15:0]                                DIN;

   logic                                       rd;

   bit                                         uart_clk = 1'b0;
   int                                         uart_skew = {$random} % 10;
   initial #1 #(uart_skew) forever #(UART_T/2) uart_clk = ~uart_clk;

   bit                                         addi_clk   = 1'b0;
   int                                         addi_skew = {$random} % 30;
   initial #1 #(addi_skew) forever #(ADDI_T/2) addi_clk = ~addi_clk;

   task t_sync;
      begin
         repeat (2) begin
            @(posedge addi_clk);
            DIN <= 16'hFFFF;
         end
         @(posedge addi_clk);
         DIN <= 16'hAAAA;
         @(posedge addi_clk);
         DIN <= 16'hCCCC;
      end
   endtask // t_sync

   task t_packet;
      begin
         //      while(!nRST);
         DIN <= 16'h0;
         t_sync;
         repeat (16)  begin
            @(posedge addi_clk);
            DIN <= DIN + 1;
         end
      end
   endtask // t_packet

   initial begin: main_stimulus
      repeat (3) @(posedge addi_clk);
      nRST <= 1'b1;
      repeat (1) @(posedge addi_clk);
      repeat (2) begin
         t_packet;
         repeat (700) @(posedge addi_clk);
      end
      $finish;
   end

   genvar i;

   generate
      for(i=0; i < numChannel; i++) begin: pick_fifo_gen

         pick #(.pixelWidth(pixelWidth))
         pick0
            (
             .CLK          (addi_clk      )
             ,.nRST        (nRST          )
             ,.DIN         (DIN           )
             ,.PIXEL_VALID (PIXEL_VALID[i])
             ,.PIXEL_DATA  (PIXEL_DATA[i]));

         fifo_async_top #(FIFO_DEPTH, FIFO_DATA_WIDTH)
         fifo_async_top0
           (
            .clkw     (addi_clk      )
            ,.resetw  (~nRST         )
            ,.wr      (PIXEL_VALID[i])
            ,.full    ()
            ,.fifoIn  (PIXEL_DATA[i] )

            ,.clkr    (uart_clk      )
            ,.resetr  (~nRST         )
            ,.rd      (rd            )
            ,.empty   (empty[i]      )
            ,.fifoOut (fifoOut[i]  ));
      end // for (i=0; i<4; i++)
   endgenerate

   enum   {eIdle, eLdFifoOut, eLdXmtDataReg, eByteReady, eTByte, eTxDone}currState, nextState;
   bit    byteReady, ldXmtDataReg, tByte, txDone;
   always_ff@(posedge uart_clk, negedge nRST) begin:nextStateReg
      if(!nRST)
        currState  <= eIdle;
      else
        currState <= nextState;
   end

   int channelCounter;
   int channelCounterNext;
   always_ff@(posedge uart_clk, negedge nRST) begin:channelCounterReg
      if(!nRST)
        channelCounter <= 0;
      else
        channelCounter <= channelCounterNext;
   end

   logic ldDataBus;
   logic [numChannel*2-1:0][FIFO_DATA_WIDTH/2-1:0] fifoOutVector;
   genvar                                          l;
   generate
      for(l=0; l < numChannel; l++) begin
         always_ff@(posedge uart_clk)begin
            if(ldDataBus)begin
               fifoOutVector[2*l+1]   <= fifoOut[l][15:8];
               fifoOutVector[2*l]     <= fifoOut[l][7:0];
            end
         end
      end
   endgenerate

   always_comb begin:nextStateCom
      {ldXmtDataReg, byteReady, tByte, rd} = 4'b0000; // default value
      nextState = currState; //default state
      channelCounterNext = channelCounter;
      ldDataBus = 1'b0;
      unique case(currState)
        eIdle:begin
           channelCounterNext = 0;
           if(!empty[0])begin
              {ldXmtDataReg, byteReady, tByte, rd} = 4'b0001;
              nextState = eLdFifoOut;
           end
        end

        eLdFifoOut:begin
           ldDataBus = 1'b1;
           nextState = eLdXmtDataReg;
        end

        eLdXmtDataReg:begin
           {ldXmtDataReg, byteReady, tByte, rd} = 4'b1000;
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
              if(channelCounter < numChannel*2-1) begin
                 channelCounterNext = channelCounter + 1;
                 nextState = eLdXmtDataReg;
              end
              else begin
                 nextState = eIdle;
              end
           end
        end
      endcase // unique case (currState)
   end // always_comb
   wire[7:0] dataBus = fifoOutVector[channelCounter];

   uart_transmitter #(4,8)
   uart_transmitter0
     (
      .clk          (uart_clk    )
      ,.nRST        (nRST        )
      ,.serialOut   (serialOut   )
      ,.dataBus     (dataBus     )
      ,.byteReady   (byteReady   )
      ,.ldXmtDataReg(ldXmtDataReg)
      ,.tByte       (tByte       )
      ,.txDone      (txDone      ));


endmodule
