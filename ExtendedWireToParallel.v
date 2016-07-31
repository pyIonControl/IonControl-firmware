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
module ExtendedWireToParallel(
	input wire [15:0] data_in,
	input wire clk_in,
	input wire write,
	output reg [15:0] address = 0,
	output reg [63:0] data_out = 0,
	output reg data_available = 0,
	output reg apply_immediately = 0,
	input wire [63:0] wide_in,
	input wire wide_update,
	input wire wide_clk,
	input wire [15:0] wide_address
    );
	 
reg [2:0] state = 0;
reg [63:0] wide_buffer = 0;
reg [63:0] receiver_buffer = 0;
reg [63:0] receiver_double_buffer = 0;
reg wide_available;
reg receiver_available;
reg [15:0] external_address = 0;
reg [15:0] external_address_buffer = 0;
 
wire receiver_available_sync;
monoflop_sync external_mf( .clock(wide_clk), .enable(1'b1), .trigger(receiver_available), .q(receiver_available_sync) );

always @(posedge wide_clk) begin
	if (data_available) begin
		data_available <= 1'b0;
	end else if (wide_update) begin
		data_out <= wide_in;
		data_available <= 1'b1;
		address <= wide_address;
		apply_immediately <= 1'b0;
	end else if (receiver_available_sync) begin
		data_out <= receiver_buffer;
		data_available <= 1'b1;
		address <= external_address;
		apply_immediately <= 1'b1;
	end
end
	 
always @(posedge clk_in) begin
	receiver_available <= 1'b0;   // default
	case (state) 
		3'h0: begin
			if (write) begin
				external_address_buffer <= data_in;
				state <= 3'h1;
			end
		end
		3'h1: begin
			if (write) begin
				receiver_double_buffer[15:0] <= data_in[15:0];
				state <= 3'h2;
			end
		end
		3'h2: begin
			if (write) begin
				receiver_double_buffer[31:16] <= data_in[15:0];
				state <= 3'h3;
			end
		end
		3'h3: begin
			if (write) begin
				receiver_double_buffer[47:32] <= data_in[15:0];
				state <= 3'h4;
			end
		end
		3'h4: begin
			if (write) begin
				receiver_buffer[63:0] <= {data_in[15:0], receiver_double_buffer[47:0]};
				external_address <= external_address_buffer;
				receiver_available <= 1'b1;
				state <= 3'h0;
			end			
		end
	endcase
end


endmodule
