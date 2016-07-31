//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module set_reset( 
	input wire clock, 
	input wire set, 
	input wire reset, 
	output reg q = initial_state );

parameter initial_state = 1'b0;

always @(posedge clock)
begin
	if (reset)
		q <= 1'b0;
	else if (set) begin
		q <= 1'b1;
	end
end

endmodule
