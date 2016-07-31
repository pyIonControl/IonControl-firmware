`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module MultAccum_limited(
	input wire clk,
	input wire sclr,
	input wire ce,
	input wire signed [15:0] a,
	input wire signed [31:0] b,
	output wire signed [31:0] s,
	output wire overflow,
	output wire underflow,
	input wire [15:0] output_offset,
	input wire set_output_offset,
	input wire set_output_clk
    );

	wire [33:0] my_s;
	wire next_neg = a[15]^b[31];
	assign overflow = (my_s[32]) & ~my_s[33];
	assign underflow = my_s[33];
 
	wire [31:0] product;
	multiplier16_32 mult( .a(a), .b(b), .p(product) );
	
	Accumulator34 accum( .b(set_output_offset? {output_offset, 16'h0} : product), 
						      .clk( clk ),
								.sclr(sclr),
								.ce( ce & ~((overflow & ~next_neg) | (underflow & next_neg) ) | sclr | set_output_offset ),
								.bypass(set_output_offset),
								.q(my_s)
	);

	assign s = my_s[31:0];

endmodule
