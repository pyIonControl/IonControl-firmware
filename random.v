`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module random(
	input wire int_clk,
	input wire rd_clk,
	output wire [63:0] random,
	input wire read_ack,
	input wire [62:0] seed,
	input wire set_seed,
	output wire valid
    );
	
	wire [63:0] rand_in;
	wire rand_valid;
	wire full;
	wire empty;
	LFSR LFSR(.clk(int_clk), .seed(seed), .set_seed(set_seed), .q(rand_in), .avail(rand_valid), .ce(~full));
	random_fifo fifo(.rd_clk(rd_clk), .wr_clk(int_clk), .din(rand_in), .wr_en(rand_valid & ~full), .full(full), .dout(random), .rd_en(read_ack), .valid(valid), .empty(empty));

endmodule
