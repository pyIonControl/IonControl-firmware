//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module clk_buffer(
	input wire clk, 
	input wire [width-1:0] in, 
	output reg [width-1:0] q );

parameter width = 8;

always @(posedge clk)
begin
	q <= in;
end

endmodule
