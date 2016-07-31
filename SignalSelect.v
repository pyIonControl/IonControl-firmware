`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module SignalSelect(
	input wire clk,
	input wire [bitwidth*channels-1:0] signal_in,
	input wire [channels-1:0] available_in,
	input wire [7:0] channel_select,
	output reg [bitwidth-1:0] signal_out,
	output reg available_out
    );
parameter bitwidth = 16;
parameter channels = 8;

always @(posedge clk) begin
	case (channel_select)
		default: begin
			signal_out[bitwidth-1:0] <= 0;
			available_out <= 0;
		end
		8'h0: begin
			signal_out[bitwidth-1:0] <= signal_in[ 0*bitwidth +: bitwidth ];
			available_out <= available_in[0];
		end
		8'h1: begin
			signal_out[bitwidth-1:0] <= signal_in[ 1*bitwidth +: bitwidth ];
			available_out <= available_in[1];
		end
		8'h2: begin
			signal_out[bitwidth-1:0] <= signal_in[ 2*bitwidth +: bitwidth ];
			available_out <= available_in[2];
		end
		8'h3: begin
			signal_out[bitwidth-1:0] <= signal_in[ 3*bitwidth +: bitwidth ];
			available_out <= available_in[3];
		end
		8'h4: begin
			signal_out[bitwidth-1:0] <= signal_in[ 4*bitwidth +: bitwidth ];
			available_out <= available_in[4];
		end
		8'h5: begin
			signal_out[bitwidth-1:0] <= signal_in[ 5*bitwidth +: bitwidth ];
			available_out <= available_in[5];
		end
		8'h6: begin
			signal_out[bitwidth-1:0] <= signal_in[ 6*bitwidth +: bitwidth ];
			available_out <= available_in[6];
		end
		8'h7: begin
			signal_out[bitwidth-1:0] <= signal_in[ 7*bitwidth +: bitwidth ];
			available_out <= available_in[7];
		end
	endcase
end


endmodule
