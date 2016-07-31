`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module value_limit(
		input wire clk,
		input wire signed [input_bits-1:0] value,
		output reg out[output_msb-output_lsb-1:0] out = 0,
		output reg clipped = 0
    );
parameter input_bits = 16;	 
parameter output_msb = 15;
parameter output_lsb = 5;
parameter output_min = 0;
parameter output_max = 16'h7fff;

always @(posedge clk) begin
	if (value<output_min) begin
		out <= output_min;
		clipped <= 1'b1;
	end
	else if (value>output_max) begin
	   out <= output_max;
		clipped <= 1'b1;
	end
	else begin
		out <= value[output_msb:output_lsb];
		clipped <= 1'b0;
	end
end


endmodule
