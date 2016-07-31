//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

/* Transmission protocol is similar to RS232 using a single data line
   Data format is 1 start bit, 72 data bits, 1 stop bit
	Default state is 0 (as lines are 50Ohm terminated and this does not need to drive a current), Start bit is logic 1, Stop bit is logic 0
	Data is sent MSB first.
	Data is buffered in a fifo when ready is asserted
	*/

module AsyncTransmitter(
	input wire clk,       // write clock
	input wire [7:0] command,  // command input
	input wire [63:0] data,    // data input
	input wire ready,
	output reg TxD=0,          // communication line
	output wire ndone,
	output wire [3:0] debug );

	reg wr_en = 1'b0, rd_en = 1'b0;
	wire empty, full, valid;
	wire [71:0] dout;
	reg [71:0] data_to_send = 72'h0;
	reg [7:0] bits_to_send = 8'h0;
	reg csb = 1'b0;
	wire done;
	assign ndone = ~done;

	assign debug = { TxD, read_state };
	TransmitterReceiverFifo fifo( .wr_clk(clk), .rd_clk(clk), .din({command, data}), .dout(dout), .wr_en(wr_en), .rd_en(rd_en), .full(full), .empty(empty), .valid(valid) );

	/// writing to fifo
	reg write_state = 1'b0;	
	always @(posedge clk) begin
		case (write_state)
		1'b0: begin
			if (ready) begin
				wr_en <= 1'b1;
				write_state <= 1'b1;
			end
		end
		1'b1: begin
			wr_en <= 1'b0;
			if (~ready) write_state <= 1'b0;
		end
		endcase
	end

	reg done_sending = 0;
	set_reset #(1'b1) done_ff( .clock(clk), .set(done_sending & empty), .reset(ready), .q(done) );
	reg [7:0] delay = 0;
	parameter clock_cycles = 9;

	// reading from fifo
	reg [2:0] read_state = 3'h0;
	always @(posedge clk) begin
		if (|delay) begin
			delay <= delay - 8'b1;
		  end
	   else
		  begin
				done_sending <= 1'b0;
				case (read_state)
					3'h0: begin
						if (valid) begin
							read_state <= 3'h1;
						end
						TxD <= 1'b0;
					end
					3'h1: begin
						rd_en <= 1'b1;
						data_to_send <= dout;
						read_state <= 3'h2;
						TxD <= 1'b0;
					end
					3'h2: begin
						bits_to_send <= 8'd72;
						read_state <= 3'h3;
						rd_en <= 1'b0;
						TxD <= 1'b1;
						delay <= clock_cycles;
					end
					3'h3: begin
						TxD <= data_to_send[71];
						delay <= clock_cycles;
						if (bits_to_send>1) begin
							data_to_send <= { data_to_send[70:0], 1'b0 };
							bits_to_send <= bits_to_send - 1'b1;
						end else begin
							read_state <= 3'h4;
						end
					end
					3'h4: begin
						done_sending <= 1'b1;
						read_state <= 3'h5;
						TxD <= 1'b1;
						delay <= clock_cycles;
					end
					3'h5: begin
						TxD <= 1'b0;
						delay <= 8'd19;
						read_state <= 3'h0;
					end
					default: begin
						read_state <= 3'h0;
						TxD <= 1'b0;
					end
				endcase
			end
	end


endmodule 