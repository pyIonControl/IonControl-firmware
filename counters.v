//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

// counters is responsible to count the number of clicks in count_in if enabled by count_enable and
// transmit the count over the pipe to the computer.
// if timestamp_enable is set for a line then it is also responsible for timestamping the photons and 
// transmit the timestamps back to the computer
// word size is 32bit
// 4bit code, 4bit channel number, 24bit count or timestamp
module counters(
	input wire fast_clk,
	input wire clk,
	input wire usb_clk,
	// pipe to computer
	output wire [63:0]      fifo_data,
	output reg             fifo_data_ready =0,
	input wire				  fifo_full,
	input wire				  fifo_rst,
	// count input
	input wire [15:0] count_in,
	input wire [23:0] count_enable,
	input wire [7:0] timestamp_enable,
	output wire [575:0] all_counts,
	output wire [191:0] adc_counts,
	output wire [447:0] adc_sum,
	// additional inputs so the sequencer can put stuff into the pipe
	input wire [129:0] output_data,
	input wire output_data_ready,
	output wire [39:0] tdc_count_out,
	// marker channels
	input wire [7:0] tdc_marker,
	input wire [7:0] counter_id,
	input wire [16*16-1:0] adc_data,
	input wire [15:0] adc_ready,
	input wire [15:0] adc_gate,
	input wire send_timestamp,
	input wire timestamp_counter_reset
);

	reg [63:0] fifo_data_out =0;
	
	assign fifo_data[63:0] = fifo_data_out[63:0];  // swap the data words because the fifo handles it differently
	reg [15:0] adc_gate_buffer;
	
	always @(posedge clk) begin
		adc_gate_buffer <= adc_gate;
	end


	///////////////////////////////////////////////////////////////////////
	// ADC
	wire [39:0] adc_result_0, adc_result_1, adc_result_2, adc_result_3, adc_result_4, adc_result_5, adc_result_6, adc_result_7;
	wire [39:0] adc_result_8, adc_result_9, adc_result_a, adc_result_b, adc_result_c, adc_result_d, adc_result_e, adc_result_f;
	wire [15:0] adc_result_ready;
	reg [15:0] adc_result_ack = 0;
	wire [7:0] adc_counter_id_0, adc_counter_id_1, adc_counter_id_2, adc_counter_id_3, adc_counter_id_4, adc_counter_id_5, adc_counter_id_6, adc_counter_id_7;
	wire [7:0] adc_counter_id_8, adc_counter_id_9, adc_counter_id_a, adc_counter_id_b, adc_counter_id_c, adc_counter_id_d, adc_counter_id_e, adc_counter_id_f;
	adc_wrapper adc_wrapper_0( .clk(clk), .adc_data(adc_data[0*16+:16]), .adc_ready(adc_ready[0]), .adc_gate(adc_gate_buffer[0]), .result(adc_result_0),
                .result_ready(adc_result_ready[0]), .result_ack(adc_result_ack[0]), .counter_id(counter_id), .counter_id_out(adc_counter_id_0) );
	adc_wrapper adc_wrapper_1( .clk(clk), .adc_data(adc_data[1*16+:16]), .adc_ready(adc_ready[1]), .adc_gate(adc_gate_buffer[1]), .result(adc_result_1),
                .result_ready(adc_result_ready[1]), .result_ack(adc_result_ack[1]), .counter_id(counter_id), .counter_id_out(adc_counter_id_1) );
	adc_wrapper adc_wrapper_2( .clk(clk), .adc_data(adc_data[2*16+:16]), .adc_ready(adc_ready[2]), .adc_gate(adc_gate_buffer[2]), .result(adc_result_2),
                .result_ready(adc_result_ready[2]), .result_ack(adc_result_ack[2]), .counter_id(counter_id), .counter_id_out(adc_counter_id_2) );
	adc_wrapper adc_wrapper_3( .clk(clk), .adc_data(adc_data[3*16+:16]), .adc_ready(adc_ready[3]), .adc_gate(adc_gate_buffer[3]), .result(adc_result_3),
                .result_ready(adc_result_ready[3]), .result_ack(adc_result_ack[3]), .counter_id(counter_id), .counter_id_out(adc_counter_id_3) );
	adc_wrapper adc_wrapper_4( .clk(clk), .adc_data(adc_data[4*16+:16]), .adc_ready(adc_ready[4]), .adc_gate(adc_gate_buffer[4]), .result(adc_result_4),
                .result_ready(adc_result_ready[4]), .result_ack(adc_result_ack[4]), .counter_id(counter_id), .counter_id_out(adc_counter_id_4) );
	adc_wrapper adc_wrapper_5( .clk(clk), .adc_data(adc_data[5*16+:16]), .adc_ready(adc_ready[5]), .adc_gate(adc_gate_buffer[5]), .result(adc_result_5),
                .result_ready(adc_result_ready[5]), .result_ack(adc_result_ack[5]), .counter_id(counter_id), .counter_id_out(adc_counter_id_5) );
	adc_wrapper adc_wrapper_6( .clk(clk), .adc_data(adc_data[6*16+:16]), .adc_ready(adc_ready[6]), .adc_gate(adc_gate_buffer[6]), .result(adc_result_6),
                .result_ready(adc_result_ready[6]), .result_ack(adc_result_ack[6]), .counter_id(counter_id), .counter_id_out(adc_counter_id_6) );
	adc_wrapper adc_wrapper_7( .clk(clk), .adc_data(adc_data[7*16+:16]), .adc_ready(adc_ready[7]), .adc_gate(adc_gate_buffer[7]), .result(adc_result_7),
                .result_ready(adc_result_ready[7]), .result_ack(adc_result_ack[7]), .counter_id(counter_id), .counter_id_out(adc_counter_id_7) );
	adc_wrapper adc_wrapper_8( .clk(clk), .adc_data(adc_data[8*16+:16]), .adc_ready(adc_ready[8]), .adc_gate(adc_gate_buffer[8]), .result(adc_result_8),
                .result_ready(adc_result_ready[8]), .result_ack(adc_result_ack[8]), .counter_id(counter_id), .counter_id_out(adc_counter_id_8) );
	adc_wrapper adc_wrapper_9( .clk(clk), .adc_data(adc_data[9*16+:16]), .adc_ready(adc_ready[9]), .adc_gate(adc_gate_buffer[9]), .result(adc_result_9),
                .result_ready(adc_result_ready[9]), .result_ack(adc_result_ack[9]), .counter_id(counter_id), .counter_id_out(adc_counter_id_9) );
	adc_wrapper adc_wrapper_a( .clk(clk), .adc_data(adc_data[10*16+:16]), .adc_ready(adc_ready[10]), .adc_gate(adc_gate_buffer[10]), .result(adc_result_a),
                .result_ready(adc_result_ready[10]), .result_ack(adc_result_ack[10]), .counter_id(counter_id), .counter_id_out(adc_counter_id_a) );
	adc_wrapper adc_wrapper_b( .clk(clk), .adc_data(adc_data[11*16+:16]), .adc_ready(adc_ready[11]), .adc_gate(adc_gate_buffer[11]), .result(adc_result_b),
                .result_ready(adc_result_ready[11]), .result_ack(adc_result_ack[11]), .counter_id(counter_id), .counter_id_out(adc_counter_id_b) );
	adc_wrapper adc_wrapper_c( .clk(clk), .adc_data(adc_data[12*16+:16]), .adc_ready(adc_ready[12]), .adc_gate(adc_gate_buffer[12]), .result(adc_result_c),
                .result_ready(adc_result_ready[12]), .result_ack(adc_result_ack[12]), .counter_id(counter_id), .counter_id_out(adc_counter_id_c) );
	adc_wrapper adc_wrapper_d( .clk(clk), .adc_data(adc_data[13*16+:16]), .adc_ready(adc_ready[13]), .adc_gate(adc_gate_buffer[13]), .result(adc_result_d),
                .result_ready(adc_result_ready[13]), .result_ack(adc_result_ack[13]), .counter_id(counter_id), .counter_id_out(adc_counter_id_d) );
	adc_wrapper adc_wrapper_e( .clk(clk), .adc_data(adc_data[14*16+:16]), .adc_ready(adc_ready[14]), .adc_gate(adc_gate_buffer[14]), .result(adc_result_e),
                .result_ready(adc_result_ready[14]), .result_ack(adc_result_ack[14]), .counter_id(counter_id), .counter_id_out(adc_counter_id_e) );
	adc_wrapper adc_wrapper_f( .clk(clk), .adc_data(adc_data[15*16+:16]), .adc_ready(adc_ready[15]), .adc_gate(adc_gate_buffer[15]), .result(adc_result_f),
                .result_ready(adc_result_ready[15]), .result_ack(adc_result_ack[15]), .counter_id(counter_id), .counter_id_out(adc_counter_id_f) );


	///////////////////////////////////////////////////////////////////////
	// counters
	wire [23:0] count0, count1, count2, count3, count4, count5, count6, count7;   // count outputs
	wire [23:0] count8, count9, counta, countb, countc, countd, counte, countf;
	wire [23:0] count10, count11, count12, count13, count14, count15, count16, count17;
	wire [7:0] counter_id_0, counter_id_1, counter_id_2, counter_id_3, counter_id_4, counter_id_5, counter_id_6, counter_id_7;
	wire [7:0] counter_id_8, counter_id_9, counter_id_a, counter_id_b, counter_id_c, counter_id_d, counter_id_e, counter_id_f;
	wire [7:0] counter_id_10, counter_id_11, counter_id_12, counter_id_13, counter_id_14, counter_id_15, counter_id_16, counter_id_17;
	wire [23:0] count_ready;
	reg [23:0] count_ack = 0;

	click_counter_encaps counter0( .clk(clk), .count_in(count_in[0]), .count_enable(count_enable[0]), .count(count0), .count_ready(count_ready[0]),
											 .count_ack(count_ack[0] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_0) );
	click_counter_encaps counter1( .clk(clk), .count_in(count_in[1]), .count_enable(count_enable[1]), .count(count1), .count_ready(count_ready[1]),
										    .count_ack(count_ack[1] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_1)  );
	click_counter_encaps counter2( .clk(clk), .count_in(count_in[2]), .count_enable(count_enable[2]), .count(count2), .count_ready(count_ready[2]),
											 .count_ack(count_ack[2] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_2)  );
	click_counter_encaps counter3( .clk(clk), .count_in(count_in[3]), .count_enable(count_enable[3]), .count(count3), .count_ready(count_ready[3]),
											 .count_ack(count_ack[3] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_3)  );
	click_counter_encaps counter4( .clk(clk), .count_in(count_in[4]), .count_enable(count_enable[4]), .count(count4), .count_ready(count_ready[4]),
											 .count_ack(count_ack[4] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_4)  );
	click_counter_encaps counter5( .clk(clk), .count_in(count_in[5]), .count_enable(count_enable[5]), .count(count5), .count_ready(count_ready[5]),
											 .count_ack(count_ack[5] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_5)  );
	click_counter_encaps counter6( .clk(clk), .count_in(count_in[6]), .count_enable(count_enable[6]), .count(count6), .count_ready(count_ready[6]),
											 .count_ack(count_ack[6] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_6)  );
	click_counter_encaps counter7( .clk(clk), .count_in(count_in[7]), .count_enable(count_enable[7]), .count(count7), .count_ready(count_ready[7]),
											 .count_ack(count_ack[7] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_7)  );
	click_counter_encaps counter8( .clk(clk), .count_in(count_in[8]), .count_enable(count_enable[8]), .count(count8), .count_ready(count_ready[8]),
											 .count_ack(count_ack[8] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_8)  );
	click_counter_encaps counter9( .clk(clk), .count_in(count_in[9]), .count_enable(count_enable[9]), .count(count9), .count_ready(count_ready[9]),
											 .count_ack(count_ack[9] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_9)  );
	click_counter_encaps countera( .clk(clk), .count_in(count_in[10]), .count_enable(count_enable[10]), .count(counta), .count_ready(count_ready[10]),
											 .count_ack(count_ack[10] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_a)  );
	click_counter_encaps counterb( .clk(clk), .count_in(count_in[11]), .count_enable(count_enable[11]), .count(countb), .count_ready(count_ready[11]),
										    .count_ack(count_ack[11] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_b)  );
	click_counter_encaps counterc( .clk(clk), .count_in(count_in[12]), .count_enable(count_enable[12]), .count(countc), .count_ready(count_ready[12]),
											 .count_ack(count_ack[12] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_c)  );
	click_counter_encaps counterd( .clk(clk), .count_in(count_in[13]), .count_enable(count_enable[13]), .count(countd), .count_ready(count_ready[13]),
										    .count_ack(count_ack[13] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_d)  );
	click_counter_encaps countere( .clk(clk), .count_in(count_in[14]), .count_enable(count_enable[14]), .count(counte), .count_ready(count_ready[14]),
											 .count_ack(count_ack[14] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_e)  );
	click_counter_encaps counterf( .clk(clk), .count_in(count_in[15]), .count_enable(count_enable[15]), .count(countf), .count_ready(count_ready[15]),
											 .count_ack(count_ack[15] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_f)  );
	click_counter_encaps counter10( .clk(clk), .count_in(count_in[0]), .count_enable(count_enable[16]), .count(count10), .count_ready(count_ready[16]),
											  .count_ack(count_ack[16] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_10)  );
	click_counter_encaps counter11( .clk(clk), .count_in(count_in[1]), .count_enable(count_enable[17]), .count(count11), .count_ready(count_ready[17]),
											  .count_ack(count_ack[17] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_11)  );
	click_counter_encaps counter12( .clk(clk), .count_in(count_in[2]), .count_enable(count_enable[18]), .count(count12), .count_ready(count_ready[18]),
											  .count_ack(count_ack[18] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_12)  );
	click_counter_encaps counter13( .clk(clk), .count_in(count_in[3]), .count_enable(count_enable[19]), .count(count13), .count_ready(count_ready[19]),
										     .count_ack(count_ack[19] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_13)  );
	click_counter_encaps counter14( .clk(clk), .count_in(count_in[4]), .count_enable(count_enable[20]), .count(count14), .count_ready(count_ready[20]),
											  .count_ack(count_ack[20] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_14)  );
	click_counter_encaps counter15( .clk(clk), .count_in(count_in[5]), .count_enable(count_enable[21]), .count(count15), .count_ready(count_ready[21]),
										     .count_ack(count_ack[21] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_15)  );
	click_counter_encaps counter16( .clk(clk), .count_in(count_in[6]), .count_enable(count_enable[22]), .count(count16), .count_ready(count_ready[22]),
											  .count_ack(count_ack[22] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_16)  );
	click_counter_encaps counter17( .clk(clk), .count_in(count_in[7]), .count_enable(count_enable[23]), .count(count17), .count_ready(count_ready[23]),
											  .count_ack(count_ack[23] | fifo_rst), .counter_id(counter_id), .counter_id_out(counter_id_17)  );

	assign all_counts = {count17, count16, count15, count14, count13, count12, count11, count10, 
								countf,  counte,  countd,  countc,  countb,  counta,  count9,  count8, 
								count7,  count6,  count5,  count4,  count3,  count2,  count1,  count0};
								
	assign adc_counts = { adc_result_f[29:28], adc_result_e[29:28], adc_result_d[29:28], adc_result_c[29:28],
						    	 adc_result_b[29:28], adc_result_a[29:28], adc_result_9[29:28], adc_result_8[29:28], 
								adc_result_7[29:28], adc_result_6[29:28], adc_result_5[29:28], adc_result_4[29:28], 
								adc_result_3[29:28], adc_result_2[29:28], adc_result_1[29:28], adc_result_0[29:28] };
								
	assign adc_sum = { adc_result_f[27:0], adc_result_e[27:0], adc_result_d[27:0], adc_result_c[27:0],
						    adc_result_b[27:0], adc_result_a[27:0], adc_result_9[27:0], adc_result_8[27:0], 
							 adc_result_7[27:0], adc_result_6[27:0], adc_result_5[27:0], adc_result_4[27:0], 
							 adc_result_3[27:0], adc_result_2[27:0], adc_result_1[27:0], adc_result_0[27:0] };
	// tdc 
	wire [39:0] tdc_count;
	reg send_timestamp_ack = 0;
	wire [47:0] send_timestamp_buffered;
	wire send_timestamp_available;
	wire send_timestamp_trigger;
	monoflop timestamp_mf( .clock(clk), .enable(1'b1), .trigger(send_timestamp), .q(send_timestamp_trigger) );
	buffer #(48) send_timestamp_buffer_reg( .clock(clk), .set(send_timestamp_trigger), .enable(1'b1), .reset(send_timestamp_ack | fifo_rst),
														 .data({counter_id, tdc_count}), .q(send_timestamp_buffered), .avail(send_timestamp_available) );
	
	// dealing with the input data to be added to the pipe
	reg output_buffer_ack;
	wire output_buffer_avail;
	wire [64:0] output_buffer_data;
	wire fifo_empty;
	PP_Out_Fifo fifo( .rd_clk(clk), .wr_clk(clk), .din(output_data), .wr_en(output_data_ready), .rd_en(output_buffer_ack), .dout(output_buffer_data), .empty(fifo_empty));
	assign output_buffer_avail = ~fifo_empty;
	
	// master clock with carry
	assign tdc_count_out = tdc_count;
	wire master_carry;
	wire master_carry_raw;
	reg master_carry_reset = 0;
	tdc_clock_counter tdc_counter( .clk(fast_clk), .sclr(timestamp_counter_reset), .q(tdc_count) );
	set_reset master_carry_ff( .clock(fast_clk), .set(tdc_count[39:0] == 40'hffffffffff), .reset(master_carry_reset), .q(master_carry_raw) );
	clk_buffer_single master_carry_clk_buffer( .clk(clk), .in(master_carry_raw), .q(master_carry) );
	
	// timestamps
	wire [47:0] ts0, ts1, ts2, ts3, ts4, ts5, ts6, ts7;   // timestamps
	wire [47:0] ts_start0, ts_start1, ts_start2, ts_start3, ts_start4, ts_start5, ts_start6, ts_start7;  // timestamps of enable
	wire [7:0] ts_ready, ts_start_ready;   
	reg [7:0] ts_ack = 0, ts_start_ack = 0;
	
	// we use monoflops to generate a one cycle pulse from the enable
	wire [7:0] timestamp_start;
	clk_monoflop start_mf_0( .clk(clk), .enable(1'b1), .trigger(timestamp_enable[0]), .q(timestamp_start[0]) );
	clk_monoflop start_mf_1( .clk(clk), .enable(1'b1), .trigger(timestamp_enable[1]), .q(timestamp_start[1]) );
	clk_monoflop start_mf_2( .clk(clk), .enable(1'b1), .trigger(timestamp_enable[2]), .q(timestamp_start[2]) );
	clk_monoflop start_mf_3( .clk(clk), .enable(1'b1), .trigger(timestamp_enable[3]), .q(timestamp_start[3]) );
	clk_monoflop start_mf_4( .clk(clk), .enable(1'b1), .trigger(timestamp_enable[4]), .q(timestamp_start[4]) );
	clk_monoflop start_mf_5( .clk(clk), .enable(1'b1), .trigger(timestamp_enable[5]), .q(timestamp_start[5]) );
	clk_monoflop start_mf_6( .clk(clk), .enable(1'b1), .trigger(timestamp_enable[6]), .q(timestamp_start[6]) );
	clk_monoflop start_mf_7( .clk(clk), .enable(1'b1), .trigger(timestamp_enable[7]), .q(timestamp_start[7]) );
	
	buffer_dual_clk #(48) tdc_buffer_0( .clk(fast_clk), .subclk(clk), .set(count_in[0]), .enable(timestamp_enable[0]), .reset(ts_ack[0] | fifo_rst), .data({counter_id, tdc_count}), .q(ts0), .avail(ts_ready[0]) );
	buffer_dual_clk #(48) tdc_buffer_1( .clk(fast_clk), .subclk(clk), .set(count_in[1]), .enable(timestamp_enable[1]), .reset(ts_ack[1] | fifo_rst), .data({counter_id, tdc_count}), .q(ts1), .avail(ts_ready[1]) );
	buffer_dual_clk #(48) tdc_buffer_2( .clk(fast_clk), .subclk(clk), .set(count_in[2]), .enable(timestamp_enable[2]), .reset(ts_ack[2] | fifo_rst), .data({counter_id, tdc_count}), .q(ts2), .avail(ts_ready[2]) );
	buffer_dual_clk #(48) tdc_buffer_3( .clk(fast_clk), .subclk(clk), .set(count_in[3]), .enable(timestamp_enable[3]), .reset(ts_ack[3] | fifo_rst), .data({counter_id, tdc_count}), .q(ts3), .avail(ts_ready[3]) );
	buffer_dual_clk #(48) tdc_buffer_4( .clk(fast_clk), .subclk(clk), .set(count_in[4]), .enable(timestamp_enable[4]), .reset(ts_ack[4] | fifo_rst), .data({counter_id, tdc_count}), .q(ts4), .avail(ts_ready[4]) );
	buffer_dual_clk #(48) tdc_buffer_5( .clk(fast_clk), .subclk(clk), .set(count_in[5]), .enable(timestamp_enable[5]), .reset(ts_ack[5] | fifo_rst), .data({counter_id, tdc_count}), .q(ts5), .avail(ts_ready[5]) );
	buffer_dual_clk #(48) tdc_buffer_6( .clk(fast_clk), .subclk(clk), .set(count_in[6]), .enable(timestamp_enable[6]), .reset(ts_ack[6] | fifo_rst), .data({counter_id, tdc_count}), .q(ts6), .avail(ts_ready[6]) );
	buffer_dual_clk #(48) tdc_buffer_7( .clk(fast_clk), .subclk(clk), .set(count_in[7]), .enable(timestamp_enable[7]), .reset(ts_ack[7] | fifo_rst), .data({counter_id, tdc_count}), .q(ts7), .avail(ts_ready[7]) );
	
	buffer_dual_clk #(48) tdc_start_0 ( .clk(fast_clk), .subclk(clk), .set(timestamp_start[0]), .enable(1'b1), .reset(ts_start_ack[0] | fifo_rst), .data({counter_id,tdc_count}), .q(ts_start0), .avail(ts_start_ready[0]) );
	buffer_dual_clk #(48) tdc_start_1 ( .clk(fast_clk), .subclk(clk), .set(timestamp_start[1]), .enable(1'b1), .reset(ts_start_ack[1] | fifo_rst), .data({counter_id,tdc_count}), .q(ts_start1), .avail(ts_start_ready[1]) );
	buffer_dual_clk #(48) tdc_start_2 ( .clk(fast_clk), .subclk(clk), .set(timestamp_start[2]), .enable(1'b1), .reset(ts_start_ack[2] | fifo_rst), .data({counter_id,tdc_count}), .q(ts_start2), .avail(ts_start_ready[2]) );
	buffer_dual_clk #(48) tdc_start_3 ( .clk(fast_clk), .subclk(clk), .set(timestamp_start[3]), .enable(1'b1), .reset(ts_start_ack[3] | fifo_rst), .data({counter_id,tdc_count}), .q(ts_start3), .avail(ts_start_ready[3]) );
	buffer_dual_clk #(48) tdc_start_4 ( .clk(fast_clk), .subclk(clk), .set(timestamp_start[4]), .enable(1'b1), .reset(ts_start_ack[4] | fifo_rst), .data({counter_id,tdc_count}), .q(ts_start4), .avail(ts_start_ready[4]) );
	buffer_dual_clk #(48) tdc_start_5 ( .clk(fast_clk), .subclk(clk), .set(timestamp_start[5]), .enable(1'b1), .reset(ts_start_ack[5] | fifo_rst), .data({counter_id,tdc_count}), .q(ts_start5), .avail(ts_start_ready[5]) );
	buffer_dual_clk #(48) tdc_start_6 ( .clk(fast_clk), .subclk(clk), .set(timestamp_start[6]), .enable(1'b1), .reset(ts_start_ack[6] | fifo_rst), .data({counter_id,tdc_count}), .q(ts_start6), .avail(ts_start_ready[6]) );
	buffer_dual_clk #(48) tdc_start_7 ( .clk(fast_clk), .subclk(clk), .set(timestamp_start[7]), .enable(1'b1), .reset(ts_start_ack[7] | fifo_rst), .data({counter_id,tdc_count}), .q(ts_start7), .avail(ts_start_ready[7]) );
	
	// markers
	reg [7:0] tdc_marker_ack = 0;
	wire [47:0] tdc_marker_buffered0, tdc_marker_buffered1, tdc_marker_buffered2, tdc_marker_buffered3, 
					tdc_marker_buffered4, tdc_marker_buffered5, tdc_marker_buffered6, tdc_marker_buffered7;
	wire [7:0] tdc_marker_ready;
	buffer_dual_clk #(48) tdc_marker_0( .clk(fast_clk), .subclk(clk), .set(tdc_marker[0]), .enable(1'b1), .reset(tdc_marker_ack[0] | fifo_rst), .data({counter_id,tdc_count}), .q(tdc_marker_buffered0), .avail(tdc_marker_ready[0]) );
	buffer_dual_clk #(48) tdc_marker_1( .clk(fast_clk), .subclk(clk), .set(tdc_marker[1]), .enable(1'b1), .reset(tdc_marker_ack[1] | fifo_rst), .data({counter_id,tdc_count}), .q(tdc_marker_buffered1), .avail(tdc_marker_ready[1]) );
	buffer_dual_clk #(48) tdc_marker_2( .clk(fast_clk), .subclk(clk), .set(tdc_marker[2]), .enable(1'b1), .reset(tdc_marker_ack[2] | fifo_rst), .data({counter_id,tdc_count}), .q(tdc_marker_buffered2), .avail(tdc_marker_ready[2]) );
	buffer_dual_clk #(48) tdc_marker_3( .clk(fast_clk), .subclk(clk), .set(tdc_marker[3]), .enable(1'b1), .reset(tdc_marker_ack[3] | fifo_rst), .data({counter_id,tdc_count}), .q(tdc_marker_buffered3), .avail(tdc_marker_ready[3]) );
	buffer_dual_clk #(48) tdc_marker_4( .clk(fast_clk), .subclk(clk), .set(tdc_marker[4]), .enable(1'b1), .reset(tdc_marker_ack[4] | fifo_rst), .data({counter_id,tdc_count}), .q(tdc_marker_buffered4), .avail(tdc_marker_ready[4]) );
	buffer_dual_clk #(48) tdc_marker_5( .clk(fast_clk), .subclk(clk), .set(tdc_marker[5]), .enable(1'b1), .reset(tdc_marker_ack[5] | fifo_rst), .data({counter_id,tdc_count}), .q(tdc_marker_buffered5), .avail(tdc_marker_ready[5]) );
	buffer_dual_clk #(48) tdc_marker_6( .clk(fast_clk), .subclk(clk), .set(tdc_marker[6]), .enable(1'b1), .reset(tdc_marker_ack[6] | fifo_rst), .data({counter_id,tdc_count}), .q(tdc_marker_buffered6), .avail(tdc_marker_ready[6]) );
	buffer_dual_clk #(48) tdc_marker_7( .clk(fast_clk), .subclk(clk), .set(tdc_marker[7]), .enable(1'b1), .reset(tdc_marker_ack[7] | fifo_rst), .data({counter_id,tdc_count}), .q(tdc_marker_buffered7), .avail(tdc_marker_ready[7]) );

	// statemachine reading from the counters and writing to the fifo
	reg [6:0] state = 7'h0;
	always @(posedge clk) begin
		case (state) 
		7'h0: begin
			state <= 7'h1;
			fifo_data_ready <= 1'b0;
			master_carry_reset <= 1'b0;
			output_buffer_ack <= 1'b0;
			count_ack <= 24'h0;
			ts_ack <= 8'h0;
			ts_start_ack <= 8'h0;
			tdc_marker_ack <= 8'h0;
			adc_result_ack <= 16'h0;
			send_timestamp_ack <= 1'b0;
		end
		7'h1: begin
			if (~fifo_full) begin
				if (output_buffer_avail) state <= 7'h3;
				else if (master_carry) state <= 7'h2;
				else if (count_ready[0]) state <= 7'h8;
				else if (count_ready[1]) state <= 7'h9;
				else if (count_ready[2]) state <= 7'ha;
				else if (count_ready[3]) state <= 7'hb;
				else if (count_ready[4]) state <= 7'hc;
				else if (count_ready[5]) state <= 7'hd;
				else if (count_ready[6]) state <= 7'he;
				else if (count_ready[7]) state <= 7'hf;
				else if (count_ready[8]) state <= 7'h28;
				else if (count_ready[9]) state <= 7'h29;
				else if (count_ready[10]) state <= 7'h2a;
				else if (count_ready[11]) state <= 7'h2b;
				else if (count_ready[12]) state <= 7'h2c;
				else if (count_ready[13]) state <= 7'h2d;
				else if (count_ready[14]) state <= 7'h2e;
				else if (count_ready[15]) state <= 7'h2f;
				else if (count_ready[16]) state <= 7'h30;
				else if (count_ready[17]) state <= 7'h31;
				else if (count_ready[18]) state <= 7'h32;
				else if (count_ready[19]) state <= 7'h33;
				else if (count_ready[20]) state <= 7'h34;
				else if (count_ready[21]) state <= 7'h35;
				else if (count_ready[22]) state <= 7'h36;
				else if (count_ready[23]) state <= 7'h37;
				else if (ts_ready[0]) state <= 7'h10;
				else if (ts_ready[1]) state <= 7'h11;
				else if (ts_ready[2]) state <= 7'h12;
				else if (ts_ready[3]) state <= 7'h13;
				else if (ts_ready[4]) state <= 7'h14;
				else if (ts_ready[5]) state <= 7'h15;
				else if (ts_ready[6]) state <= 7'h16;
				else if (ts_ready[7]) state <= 7'h17;				
				else if (ts_start_ready[0]) state <= 7'h18;
				else if (ts_start_ready[1]) state <= 7'h19;
				else if (ts_start_ready[2]) state <= 7'h1a;
				else if (ts_start_ready[3]) state <= 7'h1b;
				else if (ts_start_ready[4]) state <= 7'h1c;
				else if (ts_start_ready[5]) state <= 7'h1d;
				else if (ts_start_ready[6]) state <= 7'h1e;
				else if (ts_start_ready[7]) state <= 7'h1f;
				else if (tdc_marker_ready[0]) state <= 7'h20;
				else if (tdc_marker_ready[1]) state <= 7'h21;
				else if (tdc_marker_ready[2]) state <= 7'h22;
				else if (tdc_marker_ready[3]) state <= 7'h23;
				else if (tdc_marker_ready[4]) state <= 7'h24;
				else if (tdc_marker_ready[5]) state <= 7'h25;
				else if (tdc_marker_ready[6]) state <= 7'h26;
				else if (tdc_marker_ready[7]) state <= 7'h27;
				else if (adc_result_ready[0]) state <= 7'h38;
				else if (adc_result_ready[1]) state <= 7'h39;
				else if (adc_result_ready[2]) state <= 7'h3a;
				else if (adc_result_ready[3]) state <= 7'h3b;
				else if (adc_result_ready[4]) state <= 7'h3c;
				else if (adc_result_ready[5]) state <= 7'h3d;
				else if (adc_result_ready[6]) state <= 7'h3e;
				else if (adc_result_ready[7]) state <= 7'h3f;
				else if (adc_result_ready[8]) state <= 7'h40;
				else if (adc_result_ready[9]) state <= 7'h41;
				else if (adc_result_ready[10]) state <= 7'h42;
				else if (adc_result_ready[11]) state <= 7'h43;
				else if (adc_result_ready[12]) state <= 7'h44;
				else if (adc_result_ready[13]) state <= 7'h45;
				else if (adc_result_ready[14]) state <= 7'h46;
				else if (adc_result_ready[15]) state <= 7'h47;
				else if (send_timestamp_available) state <= 7'h48;
			end
		end
		7'h2: begin // timestamp overflow
			fifo_data_out <= { 16'hfffd, 48'h0};
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			master_carry_reset <= 1'b1;
		end
		7'h3: begin
			fifo_data_out <= output_buffer_data[63:0];
			if (output_buffer_data[64]) begin       // data only gets written if the 48 least significant bits are not 0 or bit 56 is not 0
				fifo_data_ready <= 1'b1;
			end
			state <= 7'h0;
			output_buffer_ack <= 1'b1;
		end
		7'h8: begin
			fifo_data_out <= { 8'h01, counter_id_0, 8'h00, 16'h0, count0[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[0] <= 1'b1;
		end
		7'h9: begin
			fifo_data_out <= { 8'h01, counter_id_1, 8'h01, 16'h0, count1[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[1] <= 1'b1;
		end
		7'ha: begin
			fifo_data_out <= { 8'h01, counter_id_2, 8'h02, 16'h0, count2[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[2] <= 1'b1;
		end
		7'hb: begin
			fifo_data_out <= { 8'h01, counter_id_3, 8'h03, 16'h0, count3[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[3] <= 1'b1;
		end
		7'hc: begin
			fifo_data_out <= { 8'h01, counter_id_4, 8'h04, 16'h0, count4[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[4] <= 1'b1;
		end
		7'hd: begin
			fifo_data_out <= { 8'h01, counter_id_5, 8'h05, 16'h0, count5[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[5] <= 1'b1;
		end
		7'he: begin
			fifo_data_out <= { 8'h01, counter_id_6, 8'h06, 16'h0, count6[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[6] <= 1'b1;
		end
		7'hf: begin
			fifo_data_out <= { 8'h01, counter_id_7, 8'h07, 16'h0, count7[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[7] <= 1'b1;
		end
		7'h28: begin
			fifo_data_out <= { 8'h01, counter_id_8, 8'h08, 16'h0, count8[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[8] <= 1'b1;
		end
		7'h29: begin
			fifo_data_out <= { 8'h01, counter_id_9, 8'h09, 16'h0, count9[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[9] <= 1'b1;
		end
		7'h2a: begin
			fifo_data_out <= { 8'h01, counter_id_a, 8'h0a, 16'h0, counta[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[10] <= 1'b1;
		end
		7'h2b: begin
			fifo_data_out <= { 8'h01, counter_id_b, 8'h0b, 16'h0, countb[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[11] <= 1'b1;
		end
		7'h2c: begin
			fifo_data_out <= { 8'h01, counter_id_c, 8'h0c, 16'h0, countc[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[12] <= 1'b1;
		end
		7'h2d: begin
			fifo_data_out <= { 8'h01, counter_id_d, 8'h0d, 16'h0, countd[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[13] <= 1'b1;
		end
		7'h2e: begin
			fifo_data_out <= { 8'h01, counter_id_e, 8'h0e, 16'h0, counte[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[14] <= 1'b1;
		end
		7'h2f: begin
			fifo_data_out <= { 8'h01, counter_id_f, 8'h0f, 16'h0, countf[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[15] <= 1'b1;
		end
		7'h30: begin
			fifo_data_out <= { 8'h01, counter_id_10, 8'h10, 16'h0, count10[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[16] <= 1'b1;
		end
		7'h31: begin
			fifo_data_out <= { 8'h01, counter_id_11, 8'h11, 16'h0, count11[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[17] <= 1'b1;
		end
		7'h32: begin
			fifo_data_out <= { 8'h01, counter_id_12, 8'h12, 16'h0, count12[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[18] <= 1'b1;
		end
		7'h33: begin
			fifo_data_out <= { 8'h01, counter_id_13, 8'h13, 16'h0, count13[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[19] <= 1'b1;
		end
		7'h34: begin
			fifo_data_out <= { 8'h01, counter_id_14, 8'h14, 16'h0, count14[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[20] <= 1'b1;
		end
		7'h35: begin
			fifo_data_out <= { 8'h01, counter_id_15, 8'h15, 16'h0, count15[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[21] <= 1'b1;
		end
		7'h36: begin
			fifo_data_out <= { 8'h01, counter_id_16, 8'h16, 16'h0, count16[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[22] <= 1'b1;
		end
		7'h37: begin
			fifo_data_out <= { 8'h01, counter_id_17, 8'h17, 16'h0, count17[23:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			count_ack[23] <= 1'b1;
		end
		7'h10: begin
			fifo_data_out <= { 8'h02, ts0[47:40], 8'h00, ts0[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_ack[0] <= 1'b1;
		end
		7'h11: begin
			fifo_data_out <= { 8'h02, ts1[47:40], 8'h01, ts1[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_ack[1] <= 1'b1;
		end
		7'h12: begin
			fifo_data_out <= { 8'h02, ts2[47:40], 8'h02, ts2[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_ack[2] <= 1'b1;
		end
		7'h13: begin
			fifo_data_out <= { 8'h02, ts3[47:40], 8'h03, ts3[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_ack[3] <= 1'b1;
		end
		7'h14: begin
			fifo_data_out <= { 8'h02, ts4[47:40], 8'h04, ts4[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_ack[4] <= 1'b1;
		end
		7'h15: begin
			fifo_data_out <= { 8'h02, ts5[47:40], 8'h05, ts5[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_ack[5] <= 1'b1;
		end
		7'h16: begin
			fifo_data_out <= { 8'h02, ts6[47:40], 8'h06, ts6[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_ack[6] <= 1'b1;
		end
		7'h17: begin
			fifo_data_out <= { 8'h02, ts7[47:40], 8'h07, ts7[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_ack[7] <= 1'b1;
		end
		7'h18: begin
			fifo_data_out <= { 8'h03, ts_start0[47:40], 8'h0, ts_start0[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_start_ack[0] <= 1'b1;
		end
		7'h19: begin
			fifo_data_out <= { 8'h03, ts_start1[47:40], 8'h1, ts_start1[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_start_ack[1] <= 1'b1;
		end
		7'h1a: begin
			fifo_data_out <= { 8'h03, ts_start2[47:40], 8'h2, ts_start2[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_start_ack[2] <= 1'b1;
		end
		7'h1b: begin
			fifo_data_out <= { 8'h03, ts_start3[47:40], 8'h3, ts_start3[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_start_ack[3] <= 1'b1;
		end
		7'h1c: begin
			fifo_data_out <= { 8'h03, ts_start4[47:40], 8'h4, ts_start4[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_start_ack[4] <= 1'b1;
		end
		7'h1d: begin
			fifo_data_out <= { 8'h03, ts_start5[47:40], 8'h5, ts_start5[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_start_ack[5] <= 1'b1;
		end
		7'h1e: begin
			fifo_data_out <= { 8'h03, ts_start6[47:40], 8'h6, ts_start6[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_start_ack[6] <= 1'b1;
		end
		7'h1f: begin
			fifo_data_out <= { 8'h03, ts_start7[47:40], 8'h7, ts_start7[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			ts_start_ack[7] <= 1'b1;
		end
		7'h20: begin
			fifo_data_out <= { 8'h04, tdc_marker_buffered0[47:40], 8'h00, tdc_marker_buffered0[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			tdc_marker_ack[0] <= 1'b1;
		end
		7'h21: begin
			fifo_data_out <= { 8'h04, tdc_marker_buffered1[47:40], 8'h01, tdc_marker_buffered1[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			tdc_marker_ack[1] <= 1'b1;
		end
		7'h22: begin
			fifo_data_out <= { 8'h04, tdc_marker_buffered2[47:40], 8'h02, tdc_marker_buffered2[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			tdc_marker_ack[2] <= 1'b1;
		end
		7'h23: begin
			fifo_data_out <= { 8'h04, tdc_marker_buffered3[47:40], 8'h03, tdc_marker_buffered3[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			tdc_marker_ack[3] <= 1'b1;
		end
		7'h24: begin
			fifo_data_out <= { 8'h04, tdc_marker_buffered4[47:40], 8'h04, tdc_marker_buffered4[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			tdc_marker_ack[4] <= 1'b1;
		end
		7'h25: begin
			fifo_data_out <= { 8'h04, tdc_marker_buffered5[47:40], 8'h05, tdc_marker_buffered5[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			tdc_marker_ack[5] <= 1'b1;
		end
		7'h26: begin
			fifo_data_out <= { 8'h04, tdc_marker_buffered6[47:40], 8'h06, tdc_marker_buffered6[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			tdc_marker_ack[6] <= 1'b1;
		end
		7'h27: begin
			fifo_data_out <= { 8'h04, tdc_marker_buffered7[47:40], 8'h07, tdc_marker_buffered7[39:0] };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			tdc_marker_ack[7] <= 1'b1;
		end
		7'h38: begin
			fifo_data_out <= { 8'h05, adc_counter_id_0, 8'h00, adc_result_0 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[0] <= 1'b1;
		end
		7'h39: begin
			fifo_data_out <= { 8'h05, adc_counter_id_1, 8'h01, adc_result_1 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[1] <= 1'b1;
		end
		7'h3a: begin
			fifo_data_out <= { 8'h05, adc_counter_id_2, 8'h02, adc_result_2 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[2] <= 1'b1;
		end
		7'h3b: begin
			fifo_data_out <= { 8'h05, adc_counter_id_3, 8'h03, adc_result_3 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[3] <= 1'b1;
		end
		7'h3c: begin
			fifo_data_out <= { 8'h05, adc_counter_id_4, 8'h04, adc_result_4 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[4] <= 1'b1;
		end
		7'h3d: begin
			fifo_data_out <= { 8'h05, adc_counter_id_5, 8'h05, adc_result_5 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[5] <= 1'b1;
		end
		7'h3e: begin
			fifo_data_out <= { 8'h05, adc_counter_id_6, 8'h06, adc_result_6 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[6] <= 1'b1;
		end
		7'h3f: begin
			fifo_data_out <= { 8'h05, adc_counter_id_7, 8'h07, adc_result_7 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[7] <= 1'b1;
		end
		7'h40: begin
			fifo_data_out <= { 8'h05, adc_counter_id_8, 8'h08, adc_result_8 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[8] <= 1'b1;
		end
		7'h41: begin
			fifo_data_out <= { 8'h05, adc_counter_id_9, 8'h09, adc_result_9 };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[9] <= 1'b1;
		end
		7'h42: begin
			fifo_data_out <= { 8'h05, adc_counter_id_a, 8'h0a, adc_result_a };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[10] <= 1'b1;
		end
		7'h43: begin
			fifo_data_out <= { 8'h05, adc_counter_id_b, 8'h0b, adc_result_b };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[11] <= 1'b1;
		end
		7'h44: begin
			fifo_data_out <= { 8'h05, adc_counter_id_c, 8'h0c, adc_result_c };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[12] <= 1'b1;
		end
		7'h45: begin
			fifo_data_out <= { 8'h05, adc_counter_id_d, 8'h0d, adc_result_d };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[13] <= 1'b1;
		end
		7'h46: begin
			fifo_data_out <= { 8'h05, adc_counter_id_e, 8'h0e, adc_result_e };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[14] <= 1'b1;
		end
		7'h47: begin
			fifo_data_out <= { 8'h05, adc_counter_id_f, 8'h0f, adc_result_f };
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			adc_result_ack[15] <= 1'b1;
		end
		7'h48: begin
			fifo_data_out <= { 16'h0600, send_timestamp_buffered };  // send timestamp
			fifo_data_ready <= 1'b1;
			state <= 7'h0;
			send_timestamp_ack <= 1'b1;;			
		end
		endcase
	end

endmodule