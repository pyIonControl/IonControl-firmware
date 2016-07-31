`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module average(
		input wire clk,
		input wire [15:0] data,
		input wire data_ready,
		output wire [31:0] q
    );
	 
reg [31:0] average = 0;
reg [1:0] state = 2'h0;
reg [15:0] data_buffer = 16'h0;
reg [2:0] delay = 3'h0;
assign q = average;

always @(posedge clk) begin
	case (state)
	2'h0: begin
		if (data_ready) begin
			data_buffer <= data;
			state <= 2'h1;
			delay <= 3'h5;
		end
	end
	2'h1: begin
		if (|delay)
			delay <= delay - 1'h1;
		else
			state <= 2'h2;
	end
	2'h2: begin
		average[31:0] <= $signed(average[31:0]) - $signed(average[23:8]) + $signed(data_buffer[15:0]);
		state <= 2'h0;
	end
	endcase
end
	 


endmodule
