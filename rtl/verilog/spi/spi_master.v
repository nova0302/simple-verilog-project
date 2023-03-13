`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/02/21 11:14:46
// Design Name:
// Module Name: spi_master
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
/*
 rstb : active low asyn reset
 mlb=0 lsb first ,  mlb=1 msb first
 start=1 data send sart
 cdiv=0 1/4, cdiv=1 1/8,  =2 1/16, =3 1/32
 */

module spi_master
  (
   input            rstb,
   input            clk,
   input            mlb,
   input            start,
   input [7:0]      tdat, //tranmit data
   input [1:0]      cdiv, //clock divider
   input            din,
   //output reg [0:0] ss,
   output reg       sck,
   output reg       dout,
   output reg       done,
   output reg [7:0] rdata
   );

   parameter idle   = 2'b00;
   parameter send   = 2'b10;
   parameter finish = 2'b11;
   reg [1:0]        cur,nxt;

   reg [7:0]        treg,rreg;
   reg [3:0]        nbit;
   reg [4:0]        mid,cnt;
   reg              shift,clr;

   //FSM i/o
   always @(start or cur or nbit or cdiv or rreg)
     begin
        nxt=cur;
        clr=1'b0;
        shift=0;//ss=0;
        case(cur)
          idle:begin
             if(start==1)
               begin
                  case (cdiv)
                    2'b00: mid=2;
                    2'b01: mid=4;
                    2'b10: mid=8;
                    2'b11: mid=16;
                  endcase
                  shift=1;
                  done=1'b0;
                  nxt=send;
               end
          end //idle
          send:begin
             //ss=0;
             if(nbit!=8)
               begin shift=1; end
             else begin
                rdata=rreg;
                done=1'b1;
                nxt=finish;
             end
          end//send
          finish:begin
             shift=0;
             //ss=1;
             clr=1'b1;
             nxt=idle;
          end
          default: nxt=finish;
        endcase
     end//always

   //state transistion
   always@(negedge clk or negedge rstb)
     begin
        if(rstb==0)
          cur<=finish;
        else
          cur<=nxt;
     end

   `ifdef ORIGIN
   //setup falling edge (shift dout) sample rising edge (read din)
   always@(negedge clk or posedge clr) begin
      if(clr==1)
        begin cnt=0; sck=1; end
      else begin
         if(shift==1) begin
            cnt=cnt+1;
            if(cnt==mid) begin
               sck=~sck;
               cnt=0;
            end //mid
         end //shift
      end //rst
   end //always

   //sample @ rising edge (read din)
   always@(posedge sck or posedge clr ) begin // or negedge rstb
      if(clr==1)  begin
         nbit=0;
         rreg=8'hFF;
      end
      else begin
         if(mlb==0) //LSB first, din@msb -> right shift
           begin  rreg={din,rreg[7:1]};  end
         else  //MSB first, din@lsb -> left shift
           begin  rreg={rreg[6:0],din};  end
         nbit=nbit+1;
      end //rst
   end //always

   always@(negedge sck or posedge clr)
     begin
        if(clr==1) begin
           treg=8'hFF;  dout=1;
        end
        else begin
           if(nbit==0) begin //load data into TREG
              treg=tdat; dout=mlb?treg[7]:treg[0];
           end //nbit_if
           else begin
              if(mlb==0) //LSB first, shift right
                begin treg={1'b1,treg[7:1]}; dout=treg[0]; end
              else//MSB first shift LEFT
                begin treg={treg[6:0],1'b1}; dout=treg[7]; end
           end
        end //rst
     end //always

   `else
   //setup falling edge (shift dout) sample rising edge (read din)
   always@(negedge clk or posedge clr) begin
      if(clr) begin
         cnt <= 5'h0;
         sck <= 1'b1;
      end
      else begin
         if(shift) begin
            cnt <= cnt + 1;
            if(cnt == mid) begin
               sck <= ~sck;
               cnt <= 0;
            end //mid
         end //shift
      end //rst
   end //always

   //sample @ rising edge (read din)
   always@(posedge clk or posedge clr ) begin // or negedge rstb
      if(clr)  begin
         nbit <= 0;
         rreg <= 8'hFF;
      end
      else begin
         if(sck) begin
            if(mlb == 0) //LSB first, din@msb -> right shift
              rreg <= {din,rreg[7:1]};
            else  //MSB first, din@lsb -> left shift
              rreg <= {rreg[6:0],din};
            nbit <= nbit + 1;
         end
      end //rst
   end //always

   always@(negedge clk or posedge clr) begin
      if(clr) begin
         treg <= 8'hFF;
         dout <= 1'b1;
      end
      else begin
         if(sck)begin
            if(nbit ==0 ) begin //load data into TREG
               treg <= tdat;
               dout <= mlb ? treg[7] : treg[0];
            end //nbit_if
            else begin
               if(mlb == 0) begin //LSB first, shift right
                  treg <= {1'b1,treg[7:1]};
                  dout <= treg[0];
               end
               else begin //MSB first shift LEFT
                  treg <= {treg[6:0],1'b1};
                  dout <= treg[7];
               end
            end
         end // if (sck)
      end //rst
   end //always

   `endif
endmodule
