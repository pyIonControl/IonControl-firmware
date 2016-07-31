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

module AsyncReceiver(
	input wire clk,
	output wire [7:0] command,
	output wire [63:0] data,
	input wire rd_en,
	input wire RxD,
	output wire valid,
	output wire [63:0] raw_data,
	output wire raw_data_write);

	parameter oversample = 9;

	reg wr_en = 1'b0;
	wire empty, full;
	reg [71:0] data_received = 72'h0;
	reg [7:0] bits_to_receive = 8'h0;
	reg [7:0] bits_received = 8'h0;
	assign raw_data_write = wr_en;
	assign raw_data = data_received;

	TransmitterReceiverFifo fifo( .wr_clk(clk), .rd_clk(clk), .din(data_received), .dout({command, data}), .wr_en(wr_en), .rd_en(rd_en), .full(full), .empty(empty) );
	assign valid = ~empty;

	reg done_receiving = 0;

	reg [1:0] RxD_sync;
	always @(posedge clk) RxD_sync <= {RxD_sync[0], RxD};
	
	reg [1:0] RxD_cnt = 0;
	reg RxD_bit;
	reg last_RxD_bit;

	always @(posedge clk) begin
	  if(RxD_sync[1] && RxD_cnt!=2'h3) RxD_cnt <= RxD_cnt + 1;
	  else
	  if(~RxD_sync[1] && RxD_cnt!=2'h0) RxD_cnt <= RxD_cnt - 1;

	  if(RxD_cnt==2'b00) RxD_bit <= 0;
	  else
	  if(RxD_cnt==2'b11) RxD_bit <= 1;
	  
	  last_RxD_bit <= RxD_bit;
	end

	reg [3:0] state;
	always @(posedge clk) begin
		wr_en <= 1'b0;
		case(state)
		  4'h0: if(RxD_bit) begin
						state <= 4'h8; // start bit found?
						bits_to_receive <= 8'd72;
						bits_received <= 8'h0;
				  end
		  4'h8: if (next_bit) begin
				bits_received <= bits_received + 8'h1;
				if (bits_received==bits_to_receive) state <= 4'h1;
			 end
		  4'h1: if (next_bit) begin
				if (RxD_bit) state <= 4'h2; // if this is the stop bit go on else
				else state <= 4'h0;         // abort the thing
		    end
		  4'h2: begin
				wr_en <= 1'b1;
				state <= 4'h3;
			end
		  4'h3: begin
				if (next_bit) state <= 4'h0;
			end
		  default: state <= 4'h0;
		endcase
	end
	
	reg [3:0] bit_spacing;

	////////////////////
	//  next_bit generator
	/////////////////////
	always @(posedge clk)
	if(state==0)
	  bit_spacing <= 4'h1;
	else
	  if ((RxD_bit ^ last_RxD_bit) & ~(|bit_spacing[3:2])) begin // resync
		  bit_spacing <= 4'h2;
	  end else begin
		  if (bit_spacing==oversample)
			 bit_spacing <= 4'h0;
		  else
			 bit_spacing <= bit_spacing + 4'h1;
	  end

	wire next_bit = (bit_spacing==6); 
	
	///////////////////////
	// data assembler
	///////////////////////
	always @(posedge clk) if(next_bit && state[3]) data_received <= {data_received[70:0], RxD_bit }; 
	

endmodule 