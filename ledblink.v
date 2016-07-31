`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module ledblink(
	input wire clk,
	input wire trigger,
	output reg q = 0
    );

parameter duration = 32'd10000000;
reg [31:0] counter = 32'h0;

always @(posedge clk) begin
	if (trigger) begin
		counter <= duration;
		q <= 1'b1;
	end
	else begin
		if (counter>32'h0)
			counter <= counter - 1'h1;
		else
			q <= 1'b0;
	end
end

endmodule
