//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module clk_buffer_single(
	input wire clk, 
	input wire in, 
	output reg q );

always @(posedge clk)
begin
	q <= in;
end

endmodule
