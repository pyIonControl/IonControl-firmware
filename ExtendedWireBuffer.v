`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// A way to implement 64 bit wire ins. Transmitted are 5 words with 16 bits each.
// The first word is the address, the remaining 4 words are the data LSW first
//
///////////////////////
module ExtendedWireBuffer(
	input wire [63:0] data_in,
	input wire update_in,
	input wire clk,
	input wire [15:0] my_address,
	input wire [15:0] address,
	input wire apply_immediately,
	input wire pp_update,
	output reg [63:0] data_out = 0,
	output reg update
    );

parameter forward_all_updates = 1'b0;	 
	
	 
reg [63:0] data_buffer = 0;
reg apply_immediately_buffer = 0;
	 
always @(posedge clk) begin
	if (update_in & (address==my_address)) begin
		data_buffer <= data_in;
		apply_immediately_buffer <= apply_immediately;
	end
	
	if (apply_immediately_buffer | pp_update) begin
		data_out <= data_buffer;
		apply_immediately_buffer <= 1'b0;
		update <= forward_all_updates | (~(data_out == data_buffer));
	end else begin
		update <= 1'b0;
	end
end

endmodule
