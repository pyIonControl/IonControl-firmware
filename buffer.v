//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module buffer( 
	input wire clock, 
	input wire set, 
	input wire reset, 
	input wire enable,
	input wire [bitwidth-1:0] data, 
	output reg [bitwidth-1:0] q = 0, 
	output reg avail = 0 );

parameter bitwidth = 24;
	
always @(posedge clock)
begin
	if (reset)
		avail <= 1'b0;
	else if (set & enable) begin
		q[bitwidth-1:0] <= data[bitwidth-1:0];
		avail <= 1'b1;
	end
end

endmodule