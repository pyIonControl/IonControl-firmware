`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module ExtendedWireToParallel_tb;

	// Inputs
	wire ti_clk;
	wire clk;
	clock_gen #(22) myclk(ti_clk);
	clock_gen #(20) wclk(clk);


	reg [15:0] data_in;
	reg write;
	reg [63:0] wide_in;
	reg wide_update;
	reg [15:0] wide_address;
	reg pp_update;

	// Outputs
	wire [15:0] address;
	wire [63:0] data_out;
	wire data_available;
	wire [63:0] bufferData;
	wire buffer_update;
	wire apply_immediately;

	// Instantiate the Unit Under Test (UUT)
	ExtendedWireToParallel uut (
		.data_in(data_in), 
		.clk_in(ti_clk), 
		.write(write), 
		.address(address), 
		.data_out(data_out), 
		.data_available(data_available), 
		.wide_in(wide_in), 
		.wide_update(wide_update), 
		.wide_clk(clk), 
		.wide_address(wide_address),
		.apply_immediately(apply_immediately)
	);

	ExtendedWireBuffer ExtendedWireInHostShutter( 
		.data_in(data_out), 
		.update_in(data_available), 
		.clk(clk), 
		.address(address), 
		.my_address(16'h07), 
		.data_out(bufferData),
		.update(buffer_update),
		.apply_immediately(apply_immediately),
		.pp_update(pp_update)		);

	initial begin
		// Initialize Inputs
		data_in = 0;
		write = 0;
		wide_in = 0;
		wide_update = 0;
		wide_address = 0;
		pp_update = 0;

		// Wait 100 ns for global reset to finish
		#100;
		#10;
        
		// Add stimulus here
		// write wire 7
		data_in = 7;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h1234;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h5678;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h9abc;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'hdeff;
		write = 1;
		#22;
		write = 0;
		#22;
		
		// write wire 7
		data_in = 7;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h1234;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h5678;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h9abc;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'hdeff;
		write = 1;
		#22;
		write = 0;
		#22;
		// write wire 7
		data_in = 7;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h1234;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h5678;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h9abc;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'hdeff;
		write = 1;
		#22;
		write = 0;
		#22;
		// write wire 7
		data_in = 7;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h1234;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h5678;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h9abc;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'hdeff;
		write = 1;
		#22;
		write = 0;
		#22;
		// write wire 7
		data_in = 7;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h1234;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h5678;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h9abc;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'hdeff;
		write = 1;
		#22;
		write = 0;
		#22;
		// write wire 8
		data_in = 8;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h8765;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h4321;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h0123;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h4567;
		write = 1;
		#22;
		write = 0;
		#22;

		
		// write wire 9
		data_in = 9;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h9876;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h5432;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h1012;
		write = 1;
		#22;
		write = 0;
		#22;
		data_in = 16'h3456;
		write = 1;
		#22;
		write = 0;
		#22;
		
		wide_in = 64'h123454326789a987;
		wide_address = 16'h7;
		#200;
		wide_update = 1;
		#20
		wide_update = 0;
		
		#200;
		pp_update = 1;
		#20;
		pp_update = 0;

	end
      
endmodule

