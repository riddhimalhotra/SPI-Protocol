`timescale 1ns / 1ps


///////////////spi master



module spi_m(
input clk, sdi, newd,
input [7:0] din,
output reg sdo,cs,
output sclk,
output  [7:0] dout
    );
 reg [7:0] dout_o = 0;
 
 /////////////sclk gen
reg [1:0] scount = 0; 
reg sclk_t = 0;
  
always@(posedge clk)
begin
        if(scount < 3)
            begin
             scount <= scount + 1;
            end
        else
            begin
            scount <= 0;
            sclk_t   <= ~sclk_t;
            end
end    
    
  ////send data
reg [7:0] data_in = 0;
reg [3:0] count = 0;
typedef enum logic [1:0] {sample = 0, send = 1, waitt = 2} state_type;
state_type state = sample;

reg [7:0] din_t = 0;

always@(posedge sclk)
begin
case(state)
     sample : 
     begin
            if(newd == 1'b1) 
                 begin
                    din_t   <= din;
                    state   <= send;
                    count   <= 1;
                    cs      <= 1'b0;
                    sdo     <= din[0];
                 end
            else
                     begin
                     state <= sample;
                     cs <= 1'b1;
                     end
     end
 
     send : 
     begin
              if(count <= 7)
               begin
                 sdo <= din_t[count];
                 count <= count + 1;
               end
              else
                begin
                 count <= 0;
                 state <= waitt;
                 cs   <= 1'b0;
                end
     end
     
     waitt: begin
         if(count <= 7)
               begin
                 count <= count + 1;
               end
              else
                begin
                 count <= 0;
                 state <= sample;
                 cs   <= 1'b1;
                end
     
     end
endcase
end



////////////////// recv data serially 
reg [3:0] count_o = 0;  
typedef enum logic [1:0] {idle_o = 0, wait_o = 1, collect_o = 2} state_type_o;
state_type_o state_o = idle_o;
  
always@(posedge sclk)
  begin
  case(state_o)
idle_o: 
begin
        if(newd == 1'b1)
           state_o <= wait_o;
         else
           state_o <= idle_o;
end

wait_o: begin
       if(count_o <= 7)
        begin
        count_o <= count_o + 1;
        state_o <= wait_o;
        end
        else
        begin
         state_o <= collect_o;
         count_o <= 0;
        end
end  



collect_o: 
begin
         if(count_o <= 7)
               begin
                dout_o[count_o] <= sdi;
                count_o <= count_o + 1; 
                state_o   <= collect_o;
               end 
          else
               begin
                count_o    <= 0;
                state_o    <= idle_o;
               end
end

default: ;
endcase
end

assign sclk = sclk_t;
///////////////////////////////////////////////////   
assign dout = ((count == 8) && (state == waitt)) ? dout_o : 8'h00;
    
endmodule








module spi_s(
input sclk, sdi , cs,
output reg sdo
    );
    
    
    
  ////receive data serially  
reg [7:0] data_in = 0;
reg [3:0] count = 0;
reg newd = 0;
reg [7:0] dout_t = 0;
typedef enum logic {idle = 0, collect = 1} state_type;
state_type state = idle;

always@(negedge sclk)
begin
case(state)
idle: 
begin
   newd <= 1'b0;
   if(cs == 1'b0)
   begin
    data_in[7:0] <= {sdi,data_in[7:1]};
    count <= 1;
    state <= collect;
  end
  else 
  begin
  state <= idle;
  end
end


collect: 
begin
           if(count <= 7)
                 begin
                 data_in[7:0] <= {sdi,data_in[7:1]};
                 state    <= collect;
                 count    <= count + 1;
                 end
           else 
                 begin
                 state <= idle;
                 count  <= 0;
                 newd <= 1'b1;
                 dout_t <= data_in;
                 end
end

default: state <= idle;

endcase
end 


////////////////// send data serially 

reg [3:0] count_o = 0;  
typedef enum logic {idle_o = 0, send_o = 1} state_type_o;
state_type_o state_o = idle_o;
  
always@(negedge sclk)
  begin
  case(state_o)
idle_o: 
begin
        if(newd == 1'b1 && cs == 1'b0)
              begin 
               state_o   <= send_o;
               count_o   <= 1;
               sdo <= dout_t[0];
              end
         else
             begin
               state_o <= idle_o;  
             end
end  

send_o: 
begin
         if(count_o <= 7)
               begin
                sdo <= dout_t[count_o];
                count_o <= count_o + 1; 
                state_o   <= send_o;
               end 
          else
               begin
                count_o    <= 0;
                state_o    <= idle_o;
               end
end

default: ;
endcase
end


///////////////////////////////////////////////////   
    
endmodule


////////////////////////////////////////////


module daisy_c
(
input clk, newd,
input [7:0] din,
output [7:0] dout
);

wire sdi, sdo ,sclk, cs;

spi_m  master (clk, sdi, newd, din, sdo, cs, sclk, dout);
spi_s slave   (sclk, sdo, cs, sdi );


endmodule

