`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module logic_analyzer_wrapper(
	input wire clk,
	input wire ti_clk,
	input wire [15:0] control, 
	input wire [2:0] triggers,
	output wire [15:0] status_data,
	output wire [15:0] LogicAnalyzerData,
	input wire LogicAnalyzerRead,
	input wire [63:0] data_in,
	input wire [63:0] aux_data_in,
	input wire [63:0] trigger_data_in,
	input wire [63:0] gate_data_in,
	input wire pp_active
    );

	wire LogicAnalyzerEmpty;
	wire LogicAnalyzerOverrun;
	wire [12:0] LogicAnalyzerRdCount;
	wire [63:0] LoginAnalyzerFifoDataIn;
	wire LogicAnalyzerFifoWrite;
	wire LogicAnalyzerReset;
	wire LogicAnalyzerOverrunAck;
	wire LogicAnalyzerOverrunBuffer;
	wire LogicAnalyzerEnable;
	wire LogicAnalyzerStop;
	wire LogicAnalyzerEnableTrigger;
	
	reg [63:0] data_in_buffered, aux_data_in_buffered, trigger_data_in_buffered, gate_data_in_buffered;
	reg pp_active_buffed;
	
	always @(posedge clk) begin
		data_in_buffered <= data_in;
		aux_data_in_buffered <= aux_data_in;
		gate_data_in_buffered <= gate_data_in;
		trigger_data_in_buffered <= trigger_data_in;
		pp_active_buffed <= pp_active;
	end

	monoflop LogicAnalyzerOverrun_mf(.clock(clk), .enable(1'b1), .trigger(triggers[0]), .q(LogicAnalyzerOverrunAck) );
	monoflop LogicAnalyzerReset_mf(.clock(clk), .enable(1'b1), .trigger(triggers[1]), .q(LogicAnalyzerReset) );
	monoflop LogicAnalyzerEnable_mf( .clock(clk), .enable(1'b1), .trigger(triggers[2]), .q(LogicAnalyzerEnableTrigger) );
	

	logic_analyzer logic_analyzer_inst( .clk(clk),
													.data_in( data_in_buffered ),
													.aux_data_in( aux_data_in_buffered ),
													.gate_data_in( gate_data_in_buffered ),
													.trigger_in( trigger_data_in_buffered ), 
													.reset(LogicAnalyzerReset),
													.fifo_wr_en(LogicAnalyzerFifoWrite), 
													.fifo_data_out(LoginAnalyzerFifoDataIn),
													.fifo_full(LogicAnalyzerFifoFull),
													.enable( pp_active_buffed & (control[0] | LogicAnalyzerEnable)  ) );     
													
	monoflop enable_reset_mf( .clock(clk), .enable(LogicAnalyzerEnable), .trigger(~pp_active_buffed), .q(LogicAnalyzerStop) );
	set_reset #(1'b0) enable_set_reset( .clock(clk), .set(LogicAnalyzerEnableTrigger), .reset(LogicAnalyzerStop), .q(LogicAnalyzerEnable) );

	set_reset logic_analyzer_overrun( .clock(clk), .set(LogicAnalyzerOverrun), .reset(LogicAnalyzerOverrunAck), .q(LogicAnalyzerOverrunBuffer) );

	logic_analyzer_fifo logic_analyzer_fifo_inst( .rst( control[1]), .wr_clk(clk), .rd_clk(ti_clk), .din(LoginAnalyzerFifoDataIn),
				.wr_en(LogicAnalyzerFifoWrite), .rd_en(LogicAnalyzerRead), .dout(LogicAnalyzerData), .full(LogicAnalyzerFifoFull),
				.overflow(LogicAnalyzerOverrun), .empty(LogicAnalyzerEmpty), .rd_data_count(LogicAnalyzerRdCount) );

	assign status_data = {LogicAnalyzerEmpty, LogicAnalyzerOverrunBuffer, 1'h0, LogicAnalyzerRdCount[12:0]};
endmodule
