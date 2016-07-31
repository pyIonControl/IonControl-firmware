`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module clk_timed_monoflop(
	input wire clk,
	input wire trigger,
	input wire [PulseLengthWidth-1:0] pulselength, 
	input wire enable,
	output reg q=0
    );
parameter PulseLengthWidth = 4;

reg triggered = 0;
reg [PulseLengthWidth-1:0] countdown = 0;

always @(posedge clk) begin
		casez ({ trigger, triggered, q})
			default: begin
				triggered <= 1'b0;
				q <= 1'b0;
				countdown <= pulselength;
			end
			3'b100: begin // trigger, not triggered, not q
				if (enable) begin
					triggered <= 1'b1;
					q <= 1'b1;
				end
			end
			3'b?11: begin // trigger, triggered, q
				if( |countdown ) begin
					countdown <= countdown - 1'b1;
				end else begin
					q <= 1'b0;
				end
			end
			3'b110: begin // trigger, triggered, not q
			end
		endcase
end

endmodule
