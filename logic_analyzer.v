//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

/*
This module is used to record when data is changing. 
It takes in a 38 bit wire for standard outputs and 38 bit wire for trigger lines.
For standard outputs level changes are reported. For trigger lines it is reported when
a channel is active.

Whenever any of those signals changes, the signals are recorded, together with
a timestamp, in a FIFO queue. An overflow bit in the datastream indicates when
the counter rolls over.

The connection to the computer is with a fifo, 64bit write width, 16bit read width.

A 24 counter keeps track of the time. A overflow record allows to measure without maximum time constraint.

Data Output format into fifo

Bit  Value
63   Overflow marker, the rest will be 0
62   1: data record, 0: tigger record
24-61: 38 monitored lines
0-23: counter value
*/



module logic_analyzer(

	input wire [63:0] data_in, //This is the data to monitor. 37 bits = 24 outputs + 6 DDS triggers 
	input wire [63:0] aux_data_in,  // Additional data lines for debugging internal things
	input wire [63:0] gate_data_in,
	input wire [63:0] trigger_in, // Lines to be monitores as trigger
	input wire reset,       //Reset the counter, should happen when the sequence starts
	input wire clk,
	output reg fifo_wr_en = 0,            //fifo write enable
	output wire [63:0] fifo_data_out, //This is the output of the FIFO queue
	input wire fifo_full,
	input wire enable );     // enables the logic analyzer circuit

reg [63:0] fifo_data = 0;
wire [23:0] count_value;    // current value of counter
reg overflow_ack = 0;    // Acknowledge the overflow event
reg trigger_ack = 0;      // Acknowledge trigger recording
wire [63:0] trigger_buffer;
wire [23:0] trigger_count_value;

wire disabled_pulse;    // single clock cycle pulse on negative edge of enable
wire internal_enable;   // is extended with respect to enable to send the disabled marker
wire disabled_available; // indicated that the disable marjer has to be sent
reg disabled_sent_ack = 0; // acknowledge the sending of the disable marker

wire [63:0] data_in_shifted;

monoflop disable_mf( .clock(clk), .enable(internal_enable), .trigger( ~enable ), .q(disabled_pulse) );      // generates a single pulse on the falling edge of enable
set_reset #(1'b0) disabled_sr( .clock(clk), .set(disabled_pulse), .reset(disabled_sent_ack), .q(disabled_available) );  // 

set_reset #(1'b0) internal_disable_sr( .clock(clk), .set(enable), .reset(disabled_sent_ack), .q(internal_enable) );   // keeps internal_enable high until the disable marker us sent

logic_analyzer_counter lac( .clk(clk), .ce(enable), .sclr(reset | ~internal_enable ), .q(count_value), .thresh0(overflow)  );

// Use a flip flop to buffer the counter overflow to not miss it
set_reset #(1'b0) overflow_ff( .clock(clk), .set(overflow), .reset(overflow_ack | reset), .q(buf_overflow) );

// and another set

// Use a flip flop to buffer trigger inputs to not miss them
multibit_set_reset #(64) trigger_ff( .clock(clk), .set(|trigger_in), .set_data(trigger_in), .reset(trigger_ack | reset), .q(trigger_buffer), 
												 .data(count_value), .data_buffer(trigger_count_value) );    // we also buffer the count to be able to report the right tigger time
												 
reg aux_data_ack = 0;
wire [63:0] aux_data_buffer;
wire [23:0] aux_count_value;
reg [63:0] last_aux_data_sent = 0;
wire aux_available;
edge_buffer #(64) aux_data_edge_buffer( .clock(clk), .set(last_aux_data_sent!=aux_data_in), .reset(aux_data_ack | reset), .data(aux_data_in), .avail(aux_available), .q(aux_data_buffer) );
edge_buffer #(24) aux_count_edge_buffer(.clock(clk), .set(last_aux_data_sent!=aux_data_in), .reset(aux_data_ack | reset), .data(count_value), .avail(), .q(aux_count_value) ); 

reg data_ack = 0;
wire [63:0] data_buffer;
wire [23:0] count_value_buffer;
wire data_available;
reg [63:0] last_data_sent; //Updated to data each clock cycle
edge_buffer #(64) data_edge_buffer( .clock(clk), .set(last_data_sent!=data_in), .reset(data_ack | reset), .data(data_in), .avail(data_available), .q(data_buffer) );
edge_buffer #(24) count_edge_buffer(.clock(clk), .set(last_data_sent!=data_in), .reset(data_ack | reset), .data(count_value), .avail(), .q(count_value_buffer) ); 

reg gate_data_ack = 0;
wire [63:0] gate_data_buffer;
wire [23:0] gate_count_value;
reg [63:0] last_gate_data_sent = 0;
wire gate_available;
edge_buffer #(64) gate_data_edge_buffer( .clock(clk), .set(last_gate_data_sent!=gate_data_in), .reset(gate_data_ack | reset), .data(gate_data_in), .avail(gate_available), .q(gate_data_buffer) );
edge_buffer #(24) gate_count_edge_buffer(.clock(clk), .set(last_gate_data_sent!=gate_data_in), .reset(gate_data_ack | reset), .data(count_value), .avail(), .q(gate_count_value) ); 


reg [3:0] state = 0;

always @ (posedge clk) begin
	if (reset | ~internal_enable) begin
		last_data_sent <= 64'h0;
		fifo_wr_en <= 0;
		overflow_ack <= 1'b0;  
		trigger_ack <= 1'b0;  
		aux_data_ack <= 1'b0;
		gate_data_ack <= 1'b0;
		disabled_sent_ack	<= 1'b0;
		data_ack <= 1'b0;
	end
	else begin
		if (fifo_wr_en) begin
			fifo_wr_en <= 1'b0;
		end
		else begin
			overflow_ack <= 1'b0;   // default value
			trigger_ack <= 1'b0;    // default value
			disabled_sent_ack <= 1'b0; // default value
			aux_data_ack <= 1'b0;   // default value
			data_ack <= 1'b0;
			gate_data_ack <= 1'b0;
			
			case (state)
			4'h0: begin
				if (buf_overflow) begin
					fifo_wr_en <= 1;
					overflow_ack <= 1'b1;
					fifo_data <= { 8'h2, 56'h0 };
				end
				else if (data_available) begin
					fifo_wr_en <= 1;
					fifo_data <= { 8'h3, data_buffer[31:0], count_value_buffer[23:0] };
					state <= 4'h3;
				end
				else if(|trigger_buffer) begin
					fifo_wr_en <= 1;
					fifo_data <= { 8'h4, trigger_buffer[31:0], trigger_count_value[23:0] };
					state <= 4'h4;
				end
				else if(aux_available) begin
					fifo_wr_en <= 1'b1;
					fifo_data <= { 8'h5, aux_data_buffer[31:0], aux_count_value[23:0] };
					state <= 4'h5;
				end
				else if(gate_available) begin
					fifo_wr_en <= 1'b1;
					fifo_data <= { 8'h6, gate_data_buffer[31:0], gate_count_value[23:0] };
					state <= 4'h6;
				end
				else if (disabled_available) begin
					fifo_wr_en <= 1;
					fifo_data <= { 8'h1, 32'hf, count_value[23:0] };
					disabled_sent_ack <= 1'b1;
				end
			end
			4'h3: begin
				fifo_wr_en <= 1;
				last_data_sent <= data_buffer;
				fifo_data <= data_buffer[63:0];
				data_ack <= 1'b1;
				state <= 4'h0;
			end
			4'h4: begin
				fifo_wr_en <= 1;
				fifo_data <= trigger_buffer[63:0];
				trigger_ack <= 1'b1;
				state <= 4'h0;
			end
			4'h5: begin
				fifo_wr_en <= 1'b1;
				last_aux_data_sent <= aux_data_buffer;
				fifo_data <= aux_data_buffer[63:0];
				aux_data_ack <= 1'b1;
				state <= 4'h0;
			end
			4'h6: begin
				fifo_wr_en <= 1'b1;
				last_gate_data_sent <= gate_data_buffer;
				fifo_data <= gate_data_buffer[63:0];
				gate_data_ack <= 1'b1;
				state <= 4'h0;
			end
			endcase
		end
	end
end


// taking care of the byteorder here to receive 0123 4567 89ab cdef
// we need to send                              cdef 89ab 4567 0123 
assign fifo_data_out[63:0] = { fifo_data[15:0], fifo_data[31:16], fifo_data[47:32], fifo_data[63:48] }; 

endmodule
