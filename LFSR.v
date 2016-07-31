`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module LFSR(
	input wire clk,
	input wire [63:0] seed,
	input wire set_seed,
	output reg [63:0] q = 0,
	output reg avail = 0,
	input wire ce
    );

	reg [62:0] shift_reg = 0;
	reg [63:0] buffer_reg = 0;
	wire avail_int;
	
	wire a;
	assign a = a ^ ce;
	reg q1 = 0, q2 = 0;

	wire feedback_bit = shift_reg[0] ~^ shift_reg[1];
	
	always @(posedge clk) begin
		if (set_seed) begin
			shift_reg <= seed[62:0];
		end else begin
			if (ce) begin
				shift_reg <= { feedback_bit, shift_reg[62:1]  };
				q1 <= a;
				q2 <= q1;
				buffer_reg <= { shift_reg[0] ^ q2, buffer_reg[63:1] };
			end
			if (avail_int) begin
				q <= buffer_reg;
			end 
			avail <= avail_int;
		end
	end

	counter_6bit counter(.clk(clk), .thresh0(avail_int), .ce(ce));

endmodule
