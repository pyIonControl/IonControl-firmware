//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module teststate( 
	input wire clock, 
	input wire reset, 
	input wire trigger, 
	output reg q=0 );

reg tmp;

reg [3:0] state = 0;


always @(posedge clock) 
begin
	if (reset) begin
		q <= 0;
	end else begin
		q <= 0;
		
		case (state)
			4'h0: begin
						if (trigger) state <= 4'h1;
					end
			4'h1: begin
						q <= 1;
						state <= 4'h0;
					end
		endcase
	
	end
	
end

endmodule
