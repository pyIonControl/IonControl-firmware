//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module buffer_dual_clk( 
	input wire clk,
	input wire subclk,
	input wire set, 
	input wire reset, 
	input wire enable,
	input wire [bitwidth-1:0] data, 
	output reg [bitwidth-1:0] q = 0, 
	output reg avail = 0 );

parameter bitwidth = 24;
reg [bitwidth-1:0] buffer;
reg availbuffer;
	
always @(posedge clk)
begin
	if (reset)
		availbuffer <= 1'b0;
	else if (set & enable) begin
		buffer[bitwidth-1:0] <= data[bitwidth-1:0];
		availbuffer <= 1'b1;
	end
end

always @(posedge subclk) begin
	avail <= availbuffer;
	q <= buffer;
end
	

endmodule