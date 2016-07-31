//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module multibit_set_reset( 
	input wire clock, 
	input wire [bits-1:0] set_data, 
	input wire set,
	input wire reset, 
	input wire [23:0] data,
	output reg [bits-1:0] q = 0,
	output reg [23:0] data_buffer );

parameter bits = 38;

always @(posedge clock)
begin
	if (reset)
		q <= 0;
	else if (set) begin
		q <= set_data;
		data_buffer <= data;
	end
end

endmodule
