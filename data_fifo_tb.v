`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module data_fifo_tb;

	parameter MASTER_PERIOD = 4;
	// clocks
	wire rd_clk, wr_clk;
	clock_gen #(10) mclka(rd_clk);
	clock_gen #(10) mclkb(wr_clk);

	// Inputs
	reg rst;
	reg [15:0] din;
	reg wr_en, rd_en;

	// Outputs
	wire full, empty;
	wire [63:0] dout;
	wire [12:0] wr_data_count;

	// Instantiate the Unit Under Test (UUT)
	data_fifo uut (
		  .rst(rst),
		  .wr_clk(wr_clk),
		  .rd_clk(rd_clk),
		  .din(din),
		  .wr_en(wr_en),
		  .rd_en(rd_en),
		  .dout(dout),
		  .full(full),
		  .empty(empty),
		  .wr_data_count(wr_data_count)
		);

	initial begin
		// Initialize Inputs
		rst = 0;
		din = 0;
		wr_en = 0;
		rd_en = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
      din = 16'h0123;
		wr_en = 1;
		
		#10;
		wr_en = 0;
		
		#10;
      din = 16'h4567;
		wr_en = 1;
		
		#10;
		wr_en = 0;
		
		#10;
      din = 16'h89ab;
		wr_en = 1;
		
		#10;
		wr_en = 0;

		#10;
      din = 16'hcdef;
		wr_en = 1;
		
		#10;
		wr_en = 0;

		#20;
		#40;
		rd_en = 1;
		
		#10;
		rd_en = 0;

	end
      
endmodule

