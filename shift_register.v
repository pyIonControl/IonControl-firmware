`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module shift_register(
	input wire clk,
	input wire in,
	output reg q=0
    );


always @(posedge clk) begin
	q <= in;
end

endmodule
