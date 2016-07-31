`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


// Combine the input from two fifos into one. Fifo1 has the higher priority and always comes first
// assumes fall through input fifos

module FifoMultiplexer(
	input wire rst,
	input wire wr_clk,
	input wire rd_clk,
	input wire [inwidth-1:0] din_1,
	input wire [inwidth-1:0] din_2,
	input wire wr_en_1,
	input wire wr_en_2,
	output wire full_1,
	output wire full_2,
	output wire full,
	output wire [outwidth-1:0] dout,
	input wire rd_en,
	output wire empty,
	output wire [12:0] rd_data_count );

parameter inwidth = 64;
parameter outwidth = 16;	
	
// registers and wires between fifos
wire [inwidth-1:0] dout_1, dout_2;
reg rd_en_1 = 0, rd_en_2 = 0;
wire empty_1, empty_2;
reg [inwidth-1:0] buffer = 0;
reg wr_en = 0;
	
// first level fifo for pulse programmer
output_fifo fifo_1( .clk(wr_clk), .rst(rst), .din(din_1), .wr_en(wr_en_1), 
						  .rd_en(rd_en_1), .dout(dout_1), .full(full_1), .empty(empty_1) );
									 
// first level fifo for ADC and counters
output_fifo fifo_2( .clk(wr_clk), .rst(rst), .din(din_2), .wr_en(wr_en_2), 
						  .rd_en(rd_en_2), .dout(dout_2), .full(full_2), .empty(empty_2) );

// big second level fifo
pipe_fifo data_out_fifo( .rst(rst), .wr_clk(wr_clk), .rd_clk(rd_clk), .din(buffer), .wr_en(wr_en), 
								 .rd_en(rd_en), .dout(dout), .full(full), .empty(empty), .valid(), .prog_empty(),
								 .rd_data_count(rd_data_count) );
	
reg [1:0] state = 0;
always @(posedge wr_clk)  begin
	case (state)
		2'h0: begin
			if (~full) begin
				if (~empty_1) begin
					buffer <= dout_1;
					wr_en <= 1'b1;
					state <= 2'h1;
				end 
				else if (~empty_2) begin
					buffer <= dout_2;
					wr_en <= 1'b1;
					state <= 2'h2;
				end 
			end
		end
		2'h1: begin
			wr_en <= 1'b0;
			rd_en_1 <= 1'b1;
			state <= 2'h3;
		end
		2'h2: begin
			wr_en <= 1'b0;
			rd_en_2 <= 1'b1;
			state <= 2'h3;
		end
		2'h3: begin
			rd_en_1 <= 1'b0;
			rd_en_2 <= 1'b0;
			state <= 2'h0;
		end
	endcase
end

endmodule
