//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module set_reset_pulse( 
	input wire clock, 
	input wire set, 
	input wire reset, 
	output reg q = initial_state,
   output reg q_pulse = 0	);

parameter initial_state = 1'b0;

always @(posedge clock)
begin
	if (reset) begin
		q <= 1'b0;
		q_pulse <= 1'b0;
	end
	else if (set) begin
		q <= 1'b1;
		if (~q)
		  q_pulse <= 1'b1;
	   else
	     q_pulse <= 1'b0;  
	end
   else q_pulse <= 1'b0;
end

endmodule
