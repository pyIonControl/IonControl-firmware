//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module DAC8568(
	input wire clk,
	input wire sclk_in,
	input wire [3:0] cmd,
	input wire [15:0] data,
	input wire [7:0] address,
	input wire ready,
	output wire dac_clk_enable,
	output wire dac_sync,
	output wire dac_din,
	output wire ndone,
	input wire [15:0] lock_data0,
	input wire [15:0] lock_data1,
	input wire [15:0] lock_data2,
	input wire [15:0] lock_data3,
	input wire [15:0] lock_data4,
	input wire [15:0] lock_data5,
	input wire [15:0] lock_data6,
	input wire [15:0] lock_data7,
	input wire lock_ready0,
	input wire lock_ready1,
	input wire lock_ready2,
	input wire lock_ready3,
	input wire lock_ready4,
	input wire lock_ready5,
	input wire lock_ready6,
	input wire lock_ready7	);

	wire SDIO, CSB;
	wire done;
	assign ndone = ~done;

	reg [15:0] cmd_word = 16'h0;
	reg wr_en = 1'b0, rd_en = 1'b0;
	wire empty, full, valid;
	wire [23:0] dout;
	reg [31:0] data_to_send = 32'h0;
	reg [7:0] bits_to_send = 8'h0;
	reg csb = 1'b0;
	reg [3:0] cmd_buffer = 0;
	reg [15:0] data_buffer = 0;
	reg [7:0] address_buffer = 0;

	dac_fifo fifo( .wr_clk(clk), .rd_clk(clk), .rst(1'b0), .din({cmd_buffer, address_buffer[3:0], data_buffer}), 
					   .dout(dout), .wr_en(wr_en), .rd_en(rd_en), .full(full), .empty(empty), .valid(valid) );

	/// writing to fifo
	reg write_state = 1'b0;	
	always @(posedge clk) begin
		case (write_state)
		1'b0: begin
			if (ready & ~(|address[7:3])) begin
				wr_en <= 1'b1;
				write_state <= 1'b1;
				cmd_buffer <= cmd;
				data_buffer <= data;
				address_buffer <= address;
			end 
		end
		1'b1: begin
			wr_en <= 1'b0;
			if (~ready) write_state <= 1'b0;
		end
		endcase
	end

	wire [15:0] lock_buffer_0, lock_buffer_1, lock_buffer_2, lock_buffer_3, lock_buffer_4, lock_buffer_5, lock_buffer_6, lock_buffer_7;
	wire [7:0] lock_avail;
	reg [7:0] lock_ack;
	buffer #(16) lock_buffer_buffer_0( .clock(clk), .set(lock_ready0), .reset(lock_ack[0]), .data(lock_data0), .enable(1'b1), .q(lock_buffer_0), .avail(lock_avail[0]) );
	buffer #(16) lock_buffer_buffer_1( .clock(clk), .set(lock_ready1), .reset(lock_ack[1]), .data(lock_data1), .enable(1'b1), .q(lock_buffer_1), .avail(lock_avail[1]) );
	buffer #(16) lock_buffer_buffer_2( .clock(clk), .set(lock_ready2), .reset(lock_ack[2]), .data(lock_data2), .enable(1'b1), .q(lock_buffer_2), .avail(lock_avail[2]) );
	buffer #(16) lock_buffer_buffer_3( .clock(clk), .set(lock_ready3), .reset(lock_ack[3]), .data(lock_data3), .enable(1'b1), .q(lock_buffer_3), .avail(lock_avail[3]) );
	buffer #(16) lock_buffer_buffer_4( .clock(clk), .set(lock_ready4), .reset(lock_ack[4]), .data(lock_data4), .enable(1'b1), .q(lock_buffer_4), .avail(lock_avail[4]) );
	buffer #(16) lock_buffer_buffer_5( .clock(clk), .set(lock_ready5), .reset(lock_ack[5]), .data(lock_data5), .enable(1'b1), .q(lock_buffer_5), .avail(lock_avail[5]) );
	buffer #(16) lock_buffer_buffer_6( .clock(clk), .set(lock_ready6), .reset(lock_ack[6]), .data(lock_data6), .enable(1'b1), .q(lock_buffer_6), .avail(lock_avail[6]) );
	buffer #(16) lock_buffer_buffer_7( .clock(clk), .set(lock_ready7), .reset(lock_ack[7]), .data(lock_data7), .enable(1'b1), .q(lock_buffer_7), .avail(lock_avail[7]) );

	reg pipe_value_pending = 0;
	wire done_pulse;
	set_reset #(1'b1) done_ff( .clock(clk), .set(done_pulse), .reset((ready & ~(|address[7:3]))), .q(done) );
	
	clk_monoflop done_mf( .clk( clk ), .trigger(~dac_wr_busy), .enable(empty&~pipe_value_pending), .q(done_pulse) );
	
	wire [2:0] channel_no;
	assign channel_no = { dout[17]^dout[18], dout[16]^dout[18], dout[18] };  // This is because someone did not bother to label the board outputs the same
	// as the chip outputs :(  with this adjustment channel numbers correspond to board output numbers (-1) because we count from 0
	

	// reading from fifo
	reg [3:0] read_state = 4'h0;
	reg [2:0] next_channel = 3'h0;
	reg dac_wr_en = 1'h0;
	always @(posedge clk) begin
		rd_en <= 1'b0;
		dac_wr_en <= 1'b0;
		case (read_state)
			default: begin   // 4'h0
				pipe_value_pending <= 1'b0;
				if (valid) begin
					read_state <= 4'h1;
				end else begin
					read_state <= { 1'b1, next_channel };
				end
				lock_ack <= 8'h0;
			end
			4'h1: begin
				case (dout[23:20])
					4'h0: begin  // Write to selected DAC input register
						data_to_send <= { 4'h0, 4'h0, 1'h0, channel_no, dout[15:0], 4'h0};
					end
					4'h1: begin // Update Selected DAC Register
						data_to_send <= { 4'h0, 4'h1, 1'h0, channel_no, dout[15:0], 4'h0};
					end
					4'h2: begin // Write to Selected DAC Input Register and Update All DAC Registers
						data_to_send <= { 4'h0, 4'h2, 1'h0, channel_no, dout[15:0], 4'h0};
					end
					4'h3: begin // Write to Selected DAC Input Register and Update Respective DAC Register
						data_to_send <= { 4'h0, 4'h3, 1'h0, channel_no, dout[15:0], 4'h0};
					end
					4'h7: begin // enable/disable internal reference
						data_to_send <= { 4'h0, 4'h8, 4'h0, 16'h0, dout[3:0] };
					end
				endcase
				rd_en <= 1'b1;
				pipe_value_pending <= 1'b1;
				read_state <= 4'h2;
			end
			4'h2: begin
				if (~dac_wr_busy) begin
					dac_wr_en <= 1'b1;
					read_state <= 4'h3;
				end
			end
			4'h3: begin
				read_state <= 4'h4;
			end
			4'h4: begin
				read_state <= 4'h0;
			end
			4'h8: begin
				next_channel <= 3'h1;
				if (lock_avail[0]) begin
					data_to_send <= { 4'h0, 4'h3, 1'h0, 3'h0, lock_buffer_0[15:0], 4'h0};
					read_state <= 4'h2;
					lock_ack[0] <= 1'b1;
				end else begin
					read_state <= 4'h0;
				end
			end
			4'h9: begin
				next_channel <= 3'h2;
				if (lock_avail[1]) begin
					data_to_send <= { 4'h0, 4'h3, 1'h0, 3'h2, lock_buffer_1[15:0], 4'h0};
					read_state <= 4'h2;
					lock_ack[1] <= 1'b1;
				end else begin
					read_state <= 4'h0;
				end
			end
			4'ha: begin
				next_channel <= 3'h3;
				if (lock_avail[2]) begin
					data_to_send <= { 4'h0, 4'h3, 1'h0, 3'h4, lock_buffer_2[15:0], 4'h0};
					read_state <= 4'h2;
					lock_ack[2] <= 1'b1;
				end else begin
					read_state <= 4'h0;
				end
			end
			4'hb: begin
				next_channel <= 3'h4;
				if (lock_avail[3]) begin
					data_to_send <= { 4'h0, 4'h3, 1'h0, 3'h6, lock_buffer_3[15:0], 4'h0};
					read_state <= 4'h2;
					lock_ack[3] <= 1'b1;
				end else begin
					read_state <= 4'h0;
				end
			end
			4'hc: begin
				next_channel <= 3'h5;
				if (lock_avail[4]) begin
					data_to_send <= { 4'h0, 4'h3, 1'h0, 3'h7, lock_buffer_4[15:0], 4'h0};
					read_state <= 4'h2;
					lock_ack[4] <= 1'b1;
				end else begin
					read_state <= 4'h0;
				end
			end
			4'hd: begin
				next_channel <= 3'h6;
				if (lock_avail[5]) begin
					data_to_send <= { 4'h0, 4'h3, 1'h0, 3'h5, lock_buffer_5[15:0], 4'h0};
					read_state <= 4'h2;
					lock_ack[5] <= 1'b1;
				end else begin
					read_state <= 4'h0;
				end
			end
			4'he: begin
				next_channel <= 3'h7;
				if (lock_avail[6]) begin
					data_to_send <= { 4'h0, 4'h3, 1'h0, 3'h3, lock_buffer_6[15:0], 4'h0};
					read_state <= 4'h2;
					lock_ack[6] <= 1'b1;
				end else begin
					read_state <= 4'h0;
				end
			end
			4'hf: begin
				next_channel <= 3'h0;
				if (lock_avail[7]) begin
					data_to_send <= { 4'h0, 4'h3, 1'h0, 3'h1, lock_buffer_7[15:0], 4'h0};
					read_state <= 4'h2;
					lock_ack[7] <= 1'b1;
				end else begin
					read_state <= 4'h0;
				end
			end
		endcase
	end

   DAC8568Bitbang bitbang( .clk(sclk_in), .data(data_to_send), .wr_en(dac_wr_en), .busy(dac_wr_busy), 
								   .dac_clk_enable(dac_clk_enable), .dac_sync(dac_sync), .dac_din(dac_din) );

endmodule 