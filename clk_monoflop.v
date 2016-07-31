`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module clk_monoflop(
	input wire clk,
	input wire trigger,
	input wire enable,
	output reg q=0
    );

reg previous = 0;

always @(posedge clk) begin
	previous <= trigger & enable;
	q <= trigger & ~previous & enable;
end

endmodule
