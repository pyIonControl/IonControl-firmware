`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module DAC8568Bitbang(
	input wire clk,
	input wire [31:0] data,
	input wire wr_en,
	output reg busy,
	output wire dac_clk_enable,
	output wire dac_sync,
	output wire dac_din
    );

reg [31:0] data_to_send = 32'h0;
reg [7:0] bits_to_send = 8'h0;

reg csb = 0;
assign dac_din = data_to_send[31];
assign dac_sync = ~csb;
assign dac_clk_enable = csb;

wire wr_en_pulse;
clk_monoflop wr_en_mf( .clk( clk ), .trigger(wr_en), .enable(1'b1), .q(wr_en_pulse) );

	// reading from fifo
reg read_state = 1'h0;
always @(posedge clk) begin
	busy <= 1'b1;
	case (read_state)
		1'h0: begin
			busy <= 1'b0;
			if (wr_en_pulse) begin
				data_to_send <= data;
				read_state <= 1'h1;
				bits_to_send <= 8'd32;
				csb <= 1'b1;
				busy <= 1'b1;
			end
		end
		1'h1: begin
			if (bits_to_send>1) begin
				data_to_send <= { data_to_send[30:0], 1'b0 };
				bits_to_send <= bits_to_send - 1'b1;
			end else begin
				csb <= 1'b0;
				read_state <= 1'h0;
				data_to_send[31] <= 1'b0;
			end
		end
	endcase
end


endmodule
