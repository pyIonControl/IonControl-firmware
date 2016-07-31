`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module delayed_on_gate(
	input wire clk,
	input wire gate,
	input wire [31:0] delay,
	output reg q = 0
    );

reg [3:0] state = 0;
reg [31:0] count = 0;

reg gate_buffer;

always @(posedge clk) begin
	gate_buffer <= gate;
end

always @(posedge clk) begin
	case (state)
		default: begin
			q <= 1'b0;
			if (gate_buffer) begin
				count <= delay;
				state <= 4'h1;
			end
		end
		4'h1: begin
			if (gate_buffer) begin
				if (count==0) begin
					q <= 1'b1;
					state <= 4'h2;
				end else begin
					count <= count - 1'b1;
				end
			end else begin
				q <= 1'b0;
				state <= 4'h0;
			end
		end
		4'h2: begin
			if (~gate_buffer) begin
				q <= 1'b0;
				state <= 4'h0;
			end
		end
	endcase
end

endmodule
