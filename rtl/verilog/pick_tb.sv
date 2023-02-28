
module pick_tb;

   timeunit 1ns;
   timeprecision 1ns;

   bit CLK = 1'b0;
   bit RST_N = 1'b0;
   bit GO;
   logic [15:0]	DIN;
   wire		PUSH;
   wire [15:0]	PIXEL_DATA;

   logic [4:0]	index = 0;
   logic [0:31]	fifo[15:0];
   always@(posedge CLK, negedge RST_N) begin
      if(!RST_N)begin
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
	 @(posedge CLK);
	 DIN <= 16'hFFFF;
      end
      @(posedge CLK);
      DIN <= 16'hAAAA;
   endtask // init_seq

   task t_go;
      while(!RST_N);
      repeat (4) @(posedge CLK);
      GO <= 1'b1;
      DIN <= 16'h0;
      init_seq;

      repeat (16)  begin
	 @(posedge CLK);
	 DIN <= DIN + 1;
      end
      repeat (4) @(posedge CLK);

   endtask // t_go

   pick dut(.*);

   always #5 CLK = ~CLK;

   initial begin
      repeat (3) t_go;
   end

   initial begin
      repeat (3) @(posedge CLK);
      RST_N <= 1'b1;
      repeat (300) @(posedge CLK);
      $finish;
   end

endmodule // pick_tb
