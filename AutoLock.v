`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module AutoLock(
	input wire clk,
	input wire update,
	input wire [15:0] errorsig,
	input wire signed [15:0] discriminator,
	input wire signed [15:0] threshold,
	input wire enable,
	output reg enable_lock_out = 0,
	output reg scanEnable = 0,
	input wire [31:0] timeout );

	
	reg [3:0] state = 4'h0; 
	localparam s_idle = 4'h0,
				  s_searching = 4'h1,
	           s_wait = 4'h2,
				  s_locked = 4'h3,
				  s_dropout = 4'h4;
				  
	wire aboveThreshold = ($signed(discriminator)>$signed(threshold));
	reg [29:0] dropout_count = 0;
	
   // control state transitions
	always @(posedge clk) begin
		if (~enable) begin
			state <= s_idle;
			enable_lock_out <= 1'b0;
			scanEnable <= 1'b0;
		end
		else case (state)
			s_idle: begin
				state <= s_searching;
			end
			s_searching: begin
				if (aboveThreshold) begin
					state <= s_wait;
					enable_lock_out <= 1'b1;
					scanEnable <= 1'b0;
				end else begin
					enable_lock_out <= 1'b0;
					scanEnable <= 1'b1;					
				end
			end
			s_wait: begin
				state <= s_locked;
			end
			s_locked: begin
				if (aboveThreshold) begin
					enable_lock_out <= 1'b1;
					scanEnable <= 1'b0;
				end else begin
					state <= s_dropout;
				end
				dropout_count <= timeout[31:2];
			end
			s_dropout: begin
				if (aboveThreshold) begin
					state <= s_locked;
				end else begin
					if (|dropout_count) begin
						dropout_count <= dropout_count - 1;
					end else begin
						state <= s_searching;
					end
				end
			end
		endcase
	end
	

endmodule
