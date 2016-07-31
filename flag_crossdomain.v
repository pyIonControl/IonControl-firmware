`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module flag_crossdomain(
	input wire clk_in,
	input wire flag_in,
	output wire busy,
	input wire clk_out,
	output wire flag_out
    );

reg flag_toggle_in = 0;
always @(posedge clk_in)  flag_toggle_in <= ( flag_in & ~ busy );

reg [2:0] sync_in_clk_out = 0;
always @(posedge clk_out) sync_in_clk_out <= { sync_in_clk_out[1:0], flag_toggle_in };

reg [1:0] sync_out_clk_in = 0;
always @(posedge clk_in) sync_out_clk_in <= { sync_out_clk_in[0], sync_in_clk_out[2] };

assign flag_out = sync_in_clk_out[2] ^ sync_in_clk_out[1];
assign busy = flag_toggle_in ^ sync_out_clk_in[1];

endmodule
