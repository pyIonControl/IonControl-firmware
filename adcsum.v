`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module adcsum(
		input wire clk,
		input wire [15:0] data,
		input wire data_ready,
		input wire sclr,
		output wire [31:0] q,
		output wire [15:0] count
    );
	 

ADCAccumCount accumcount( .clk(clk), .ce(data_ready), .sclr(sclr), .q(count) );
ADCAccumulator accum( .b(data), .clk(clk), .ce(data_ready), .sclr(sclr), .q(q) );


endmodule
