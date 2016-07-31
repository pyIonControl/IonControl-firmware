//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module set_reset_count( 
	input wire clock, 
	input wire set, 
	input wire reset, 
	output reg q = initial_state );

parameter initial_state = 1'b0;
parameter threshold = 4'h1;

reg [3:0] count = 0;

always @(posedge clock)
begin
	if (reset) begin
		q <= 1'b0;
		count <= 4'h0;
	end
	else if (set) begin
		if (~q) begin
			count <= count + 1;
			q <= (count > threshold);
		end
	end
end

endmodule
