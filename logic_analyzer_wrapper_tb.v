`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module logic_analyzer_wrapper_tb;

	wire clk;
	clock_gen myclk(clk);
	// Inputs
	reg [15:0] control;
	reg [2:0] triggers;
	reg LogicAnalyzerRead;
	reg [31:0] data_in;
	reg [31:0] gate_data_in;
	reg [31:0] aux_data_in;
	reg [31:0] trigger_data_in;
	reg pp_active;

	// Outputs
	wire [15:0] status_data;
	wire [15:0] LogicAnalyzerData;

	// Instantiate the Unit Under Test (UUT)
	logic_analyzer_wrapper uut (
		.clk(clk), 
		.control(control), 
		.triggers(triggers), 
		.status_data(status_data), 
		.LogicAnalyzerData(LogicAnalyzerData), 
		.LogicAnalyzerRead(LogicAnalyzerRead), 
		.data_in(data_in), 
		.gate_data_in(gate_data_in),
		.aux_data_in(aux_data_in),
		.trigger_data_in(trigger_data_in), 
		.pp_active(pp_active)
	);

	initial begin
		// Initialize Inputs
		control = 1;
		triggers = 0;
		LogicAnalyzerRead = 0;
		data_in = 0;
		aux_data_in = 0;
		trigger_data_in = 0;
		pp_active = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		triggers[2] = 1;
		#20 triggers[2] = 0;
		data_in = 3;
		
		#100
		pp_active = 1;
		data_in = 7;
		
		#100
		data_in = 14;
		
		#200
		data_in = 42;
		trigger_data_in = 7;
		aux_data_in = 15;
		
		#20
		trigger_data_in = 0;
		
		#100
		data_in = 7;
		
		#100
		data_in = 1;
		pp_active = 0;
		data_in = 123;
		gate_data_in = 234;
		aux_data_in = 567;
		
	end
      
endmodule

