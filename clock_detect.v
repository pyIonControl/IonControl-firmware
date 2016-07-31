`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module clock_detect(
	input wire clk0,
	input wire clk1,
	output reg clk1_present = 0,
	output reg switching = 0
    );
	 
wire thresh0;
wire [11:0] q;
reg clear = 0;
wire clear1;

clock_counter clk0_counter( .clk(clk0), .thresh0(thresh0), .sclr(clear) );
monoflop mf( .clock(clk1), .trigger(clear), .enable(1'b1), .q(clear1) );
clock_counter clk1_counter( .clk(clk1), .q(q), .sclr(clear1) );

reg [3:0] state = 0;
reg present = 0;

always @(posedge clk0) begin
	case (state) 
		4'h0: begin
			switching <= 1'b0;
			if (thresh0) begin
				if (q>16'he00) begin
					state <= 4'h1;
					present <= 1'b1;
				end else begin
					state <= 4'h1;
					present <= 1'b0;
				end
				clear <= 1'b1;
			end else begin
				clear <= 1'b0;
			end
		end
		4'h1: begin
		   if ( present ^ clk1_present ) begin
				switching <= 1'b1;
				state <= 4'h2;				
			end else begin
				state <= 4'h0;								
			end
		end
		4'h2: begin
			clk1_present <= present;
			switching <= 1'b1;
			state <= 4'h3;
		end
		4'h3: begin
			state <= 4'h4;
		end
		4'h4: begin
			switching <= 1'b0;
			state <= 4'h0;
		end
	endcase
end


endmodule
