`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module DAC8568_tb;

	parameter MASTER_PERIOD = 20;
	wire clk;
	wire sclk_in;
	clock_gen #(MASTER_PERIOD) mclk(clk);
	clock_gen #(25) msclk(sclk_in);
	// Inputs
	reg [3:0] cmd;
	reg [15:0] data;
	reg [7:0] address;
	reg ready;
	reg [15:0] lock_data0;
	reg [15:0] lock_data1;
	reg [15:0] lock_data2;
	reg [15:0] lock_data3;
	reg [15:0] lock_data4;
	reg [15:0] lock_data5;
	reg [15:0] lock_data6;
	reg [15:0] lock_data7;
	reg lock_ready0;
	reg lock_ready1;
	reg lock_ready2;
	reg lock_ready3;
	reg lock_ready4;
	reg lock_ready5;
	reg lock_ready6;
	reg lock_ready7;

	// Outputs
	wire dac_clk_enable;
	wire dac_sync;
	wire dac_din;
	wire ndone;

	// Instantiate the Unit Under Test (UUT)
	DAC8568 uut (
		.clk(clk), 
		.sclk_in(sclk_in), 
		.cmd(cmd), 
		.data(data), 
		.address(address), 
		.ready(ready), 
		.dac_clk_enable(dac_clk_enable), 
		.dac_sync(dac_sync), 
		.dac_din(dac_din), 
		.ndone(ndone), 
		.lock_data0(lock_data0), 
		.lock_data1(lock_data1), 
		.lock_data2(lock_data2), 
		.lock_data3(lock_data3), 
		.lock_data4(lock_data4), 
		.lock_data5(lock_data5), 
		.lock_data6(lock_data6), 
		.lock_data7(lock_data7), 
		.lock_ready0(lock_ready0), 
		.lock_ready1(lock_ready1), 
		.lock_ready2(lock_ready2), 
		.lock_ready3(lock_ready3), 
		.lock_ready4(lock_ready4), 
		.lock_ready5(lock_ready5), 
		.lock_ready6(lock_ready6), 
		.lock_ready7(lock_ready7)
	);

	initial begin
		// Initialize Inputs
		cmd = 0;
		data = 0;
		address = 0;
		ready = 0;
		lock_data0 = 0;
		lock_data1 = 0;
		lock_data2 = 0;
		lock_data3 = 0;
		lock_data4 = 0;
		lock_data5 = 0;
		lock_data6 = 0;
		lock_data7 = 0;
		lock_ready0 = 0;
		lock_ready1 = 0;
		lock_ready2 = 0;
		lock_ready3 = 0;
		lock_ready4 = 0;
		lock_ready5 = 0;
		lock_ready6 = 0;
		lock_ready7 = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		cmd = 3;
		data = 16'h3355;
		address = 8'h5;
		ready = 1;
		#20
		ready = 0;
		
		cmd = 3;
		data = 16'h3355;
		address = 8'h5;
		ready = 1;
		#20
		ready = 0;
		
		lock_data3 = 16'h2233;
		lock_ready3 = 1;
		#20
		lock_ready3 = 0;

		#20;
		lock_data0 = 16'h2200;
		lock_ready0 = 1;
		#20
		lock_ready0 = 0;

		#20;
		lock_data1 = 16'h2211;
		lock_ready1 = 1;
		#20
		lock_ready1 = 0;

		#20;
		cmd = 3;
		data = 16'h3333;
		address = 8'h3;
		ready = 1;
		#20
		ready = 0;
		
		#3300;
		cmd = 3;
		data = 16'h3355;
		address = 8'h5;
		ready = 1;
		#20
		ready = 0;
		

	end
      
endmodule

