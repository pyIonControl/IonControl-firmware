`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module ScanGenerator(
	input wire clk,
	input wire [15:0] increment,
	input wire sinit,
	input wire [15:0] scan_min,
	input wire [15:0] scan_max,
	input wire scan_enable,
	output reg [15:0] q
    );
	 
	 
	wire [16:0] accum_q;
	reg direction = 1'b1;
	
	always @(posedge clk) begin
		if (~accum_q[16]) q <= accum_q;
	end
	
	wire invert_direction = accum_q[16:0]>scan_max || accum_q[16:0]<scan_min;
	reg overflow = 1'b0;
	always @(posedge clk) begin
		if (overflow) begin
			if (~invert_direction) overflow <= 1'b0;
		end else begin
			if (invert_direction) begin
				direction <= ~direction;
				overflow <= 1'b1;
			end
		end
	end

	ScanAccumulator ScanAccum( .clk(clk), .add(direction), .ce(scan_enable), .sinit(sinit),
										.b(increment), .q(accum_q) );

endmodule
