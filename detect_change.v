`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module detect_change(
	input wire clk,
	input wire [47:0] data,
	output reg [47:0] q = 0,
	output reg update = 0
    );
	 
	 
always @(posedge clk) begin
	if (update)
		update <= 1'b0;
	else
		if (data[47:0] != q[47:0]) begin
			q <= data;
			update <= 1'b1;
		end
end


endmodule
