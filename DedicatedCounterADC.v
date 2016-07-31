`timescale 1ns / 1ps
`include "Configuration.v"
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module DedicatedCounterADC(
		input wire clk,
		input wire [15:0] count_input,
		input wire [15:0] count_enable,
		input wire [15:0] adc_enable,
		output reg [63:0] data_out = 0,
		output reg data_available = 0,
		input wire fifo_full,
		input wire [47:0] update_time,
		
		input wire [16*16-1:0] adcdata,
		input wire [15:0] adcready,
		input wire [39:0] tdc_count,
		input wire integration_update
    );


wire counts_ready;

wire [47:0] adc0data, adc1data, adc2data, adc3data, adc4data, adc5data, adc6data, adc7data;
wire [47:0] adc8data, adc9data, adcadata, adcbdata, adccdata, adcddata, adcedata, adcfdata;

ADCControl myadc( .clk(clk), .sclr(counts_ready),
						.adcdata(adcdata), .adcready(adcready),
						.adc0data(adc0data), .adc1data(adc1data), .adc2data(adc2data), .adc3data(adc3data), 
						.adc4data(adc4data), .adc5data(adc5data), .adc6data(adc6data),	.adc7data(adc7data), 
						.adc8data(adc8data), .adc9data(adc9data), .adcadata(adcadata),	.adcbdata(adcbdata), 
						.adccdata(adccdata), .adcddata(adcddata), .adcedata(adcedata),	.adcfdata(adcfdata) );
					  
////////////////////////////////////////////////////////////////////
// buffers for storage of adc results
reg [15:0] adc_ack = 0;
wire [15:0] adc_avail;
wire [47:0] adc_data_0, adc_data_1, adc_data_2, adc_data_3, adc_data_4, adc_data_5, adc_data_6, adc_data_7;
wire [47:0] adc_data_8, adc_data_9, adc_data_a, adc_data_b, adc_data_c, adc_data_d, adc_data_e, adc_data_f;

buffer #(48) adc_buffer_0( .clock(clk), .set(counts_ready), .reset(adc_ack[0]), .enable(adc_enable[0]), .data(adc0data), .q(adc_data_0), .avail(adc_avail[0]) );				  
buffer #(48) adc_buffer_1( .clock(clk), .set(counts_ready), .reset(adc_ack[1]), .enable(adc_enable[1]), .data(adc1data), .q(adc_data_1), .avail(adc_avail[1]) );				  
buffer #(48) adc_buffer_2( .clock(clk), .set(counts_ready), .reset(adc_ack[2]), .enable(adc_enable[2]), .data(adc2data), .q(adc_data_2), .avail(adc_avail[2]) );				  
buffer #(48) adc_buffer_3( .clock(clk), .set(counts_ready), .reset(adc_ack[3]), .enable(adc_enable[3]), .data(adc3data), .q(adc_data_3), .avail(adc_avail[3]) );				  
buffer #(48) adc_buffer_4( .clock(clk), .set(counts_ready), .reset(adc_ack[4]), .enable(adc_enable[4]), .data(adc4data), .q(adc_data_4), .avail(adc_avail[4]) );				  
buffer #(48) adc_buffer_5( .clock(clk), .set(counts_ready), .reset(adc_ack[5]), .enable(adc_enable[5]), .data(adc5data), .q(adc_data_5), .avail(adc_avail[5]) );				  
buffer #(48) adc_buffer_6( .clock(clk), .set(counts_ready), .reset(adc_ack[6]), .enable(adc_enable[6]), .data(adc6data), .q(adc_data_6), .avail(adc_avail[6]) );				  
buffer #(48) adc_buffer_7( .clock(clk), .set(counts_ready), .reset(adc_ack[7]), .enable(adc_enable[7]), .data(adc7data), .q(adc_data_7), .avail(adc_avail[7]) );				  
buffer #(48) adc_buffer_8( .clock(clk), .set(counts_ready), .reset(adc_ack[8]), .enable(adc_enable[8]), .data(adc8data), .q(adc_data_8), .avail(adc_avail[8]) );				  
buffer #(48) adc_buffer_9( .clock(clk), .set(counts_ready), .reset(adc_ack[9]), .enable(adc_enable[9]), .data(adc9data), .q(adc_data_9), .avail(adc_avail[9]) );				  
buffer #(48) adc_buffer_a( .clock(clk), .set(counts_ready), .reset(adc_ack[10]), .enable(adc_enable[10]), .data(adcadata), .q(adc_data_a), .avail(adc_avail[10]) );				  
buffer #(48) adc_buffer_b( .clock(clk), .set(counts_ready), .reset(adc_ack[11]), .enable(adc_enable[11]), .data(adcbdata), .q(adc_data_b), .avail(adc_avail[11]) );				  
buffer #(48) adc_buffer_c( .clock(clk), .set(counts_ready), .reset(adc_ack[12]), .enable(adc_enable[12]), .data(adccdata), .q(adc_data_c), .avail(adc_avail[12]) );				  
buffer #(48) adc_buffer_d( .clock(clk), .set(counts_ready), .reset(adc_ack[13]), .enable(adc_enable[13]), .data(adcddata), .q(adc_data_d), .avail(adc_avail[13]) );				  
buffer #(48) adc_buffer_e( .clock(clk), .set(counts_ready), .reset(adc_ack[14]), .enable(adc_enable[14]), .data(adcedata), .q(adc_data_e), .avail(adc_avail[14]) );				  
buffer #(48) adc_buffer_f( .clock(clk), .set(counts_ready), .reset(adc_ack[15]), .enable(adc_enable[15]), .data(adcfdata), .q(adc_data_f), .avail(adc_avail[15]) );				  

reg tdc_ack;
wire tdc_count_avail;
wire [39:0] tdc_count_buf;
buffer #(40) tdc_count_buffer( .clock(clk), .set(counts_ready), .reset(tdc_ack), .enable(1'b1), .data(tdc_count), .q(tdc_count_buf), .avail(tdc_count_avail) );				  

/////////////////////////////////////////////////////////////////////
// delay counter
wire thresh;
wire [47:0] master_count;
assign counts_ready = thresh; //(master_count == 48'h2); 
delay_counter my_delay_counter( .clk(clk), .load(integration_update | thresh), .l(update_time), .q(master_count), .thresh0(thresh) );

wire [23:0] count_0, count_1, count_2, count_3, count_4, count_5, count_6, count_7;
`ifndef __LX45__
wire [23:0] count_8, count_9, count_a, count_b, count_c, count_d, count_e, count_f;
`endif
wire sclr;
assign sclr = thresh | integration_update;
reg [15:0] count_ack = 0;
wire [15:0] count_avail;
reg delay_ack = 0;
click_counter counter_0(.clk(clk), .ce(count_input[0]), .sclr(sclr), .q(count_0) );
click_counter counter_1(.clk(clk), .ce(count_input[1]), .sclr(sclr), .q(count_1) );
click_counter counter_2(.clk(clk), .ce(count_input[2]), .sclr(sclr), .q(count_2) );
click_counter counter_3(.clk(clk), .ce(count_input[3]), .sclr(sclr), .q(count_3) );
click_counter counter_4(.clk(clk), .ce(count_input[4]), .sclr(sclr), .q(count_4) );
click_counter counter_5(.clk(clk), .ce(count_input[5]), .sclr(sclr), .q(count_5) );
click_counter counter_6(.clk(clk), .ce(count_input[6]), .sclr(sclr), .q(count_6) );
click_counter counter_7(.clk(clk), .ce(count_input[7]), .sclr(sclr), .q(count_7) );
`ifndef __LX45__
click_counter counter_8(.clk(clk), .ce(count_input[8]), .sclr(sclr), .q(count_8) );
click_counter counter_9(.clk(clk), .ce(count_input[9]), .sclr(sclr), .q(count_9) );
click_counter counter_a(.clk(clk), .ce(count_input[10]), .sclr(sclr), .q(count_a) );
click_counter counter_b(.clk(clk), .ce(count_input[11]), .sclr(sclr), .q(count_b) );
click_counter counter_c(.clk(clk), .ce(count_input[12]), .sclr(sclr), .q(count_c) );
click_counter counter_d(.clk(clk), .ce(count_input[13]), .sclr(sclr), .q(count_d) );
click_counter counter_e(.clk(clk), .ce(count_input[14]), .sclr(sclr), .q(count_e) );
click_counter counter_f(.clk(clk), .ce(count_input[15]), .sclr(sclr), .q(count_f) );
`endif
wire [23:0] b_count_0, b_count_1, b_count_2, b_count_3, b_count_4, b_count_5, b_count_6, b_count_7;
wire [47:0] delay_tosend;
`ifndef __LX45__
wire [23:0] b_count_8, b_count_9, b_count_a, b_count_b, b_count_c, b_count_d, b_count_e, b_count_f;
`endif
buffer count_buff_0( .clock(clk), .set(counts_ready), .reset(count_ack[0]), .enable(count_enable[0]), .data(count_0), .q(b_count_0), .avail(count_avail[0]) );	
buffer count_buff_1( .clock(clk), .set(counts_ready), .reset(count_ack[1]), .enable(count_enable[1]), .data(count_1), .q(b_count_1), .avail(count_avail[1]) );	
buffer count_buff_2( .clock(clk), .set(counts_ready), .reset(count_ack[2]), .enable(count_enable[2]), .data(count_2), .q(b_count_2), .avail(count_avail[2]) );	
buffer count_buff_3( .clock(clk), .set(counts_ready), .reset(count_ack[3]), .enable(count_enable[3]), .data(count_3), .q(b_count_3), .avail(count_avail[3]) );	
buffer count_buff_4( .clock(clk), .set(counts_ready), .reset(count_ack[4]), .enable(count_enable[4]), .data(count_4), .q(b_count_4), .avail(count_avail[4]) );	
buffer count_buff_5( .clock(clk), .set(counts_ready), .reset(count_ack[5]), .enable(count_enable[5]), .data(count_5), .q(b_count_5), .avail(count_avail[5]) );	
buffer count_buff_6( .clock(clk), .set(counts_ready), .reset(count_ack[6]), .enable(count_enable[6]), .data(count_6), .q(b_count_6), .avail(count_avail[6]) );	
buffer count_buff_7( .clock(clk), .set(counts_ready), .reset(count_ack[7]), .enable(count_enable[7]), .data(count_7), .q(b_count_7), .avail(count_avail[7]) );
`ifndef __LX45__
buffer count_buff_8( .clock(clk), .set(counts_ready), .reset(count_ack[8]), .enable(count_enable[8]), .data(count_8), .q(b_count_8), .avail(count_avail[8]) );	
buffer count_buff_9( .clock(clk), .set(counts_ready), .reset(count_ack[9]), .enable(count_enable[9]), .data(count_9), .q(b_count_9), .avail(count_avail[9]) );	
buffer count_buff_a( .clock(clk), .set(counts_ready), .reset(count_ack[10]), .enable(count_enable[10]), .data(count_a), .q(b_count_a), .avail(count_avail[10]) );	
buffer count_buff_b( .clock(clk), .set(counts_ready), .reset(count_ack[11]), .enable(count_enable[11]), .data(count_b), .q(b_count_b), .avail(count_avail[11]) );	
buffer count_buff_c( .clock(clk), .set(counts_ready), .reset(count_ack[12]), .enable(count_enable[12]), .data(count_c), .q(b_count_c), .avail(count_avail[12]) );	
buffer count_buff_d( .clock(clk), .set(counts_ready), .reset(count_ack[13]), .enable(count_enable[13]), .data(count_d), .q(b_count_d), .avail(count_avail[13]) );	
buffer count_buff_e( .clock(clk), .set(counts_ready), .reset(count_ack[14]), .enable(count_enable[14]), .data(count_e), .q(b_count_e), .avail(count_avail[14]) );	
buffer count_buff_f( .clock(clk), .set(counts_ready), .reset(count_ack[15]), .enable(count_enable[15]), .data(count_f), .q(b_count_f), .avail(count_avail[15]) );
`endif
buffer #(48) delay_buffer( .clock(clk), .set(integration_update), .reset(delay_ack), .enable(1'b1), .data(update_time), .q(delay_tosend), .avail(delay_avail) );



////////////////////////////////////////////////////////////////////////////////
// state machine feeding accumulated data into fifo
// statemachine reading from the counters and writing to the fifo
reg [5:0] state = 6'h0;
always @(posedge clk) begin
	case (state) 
	6'h0: begin
		state <= 6'h1;
		data_available <= 1'b0;
		count_ack <= 8'h0;
		adc_ack <= 4'h0;
		delay_ack <= 8'h0;
		tdc_ack <= 1'b0;
	end
	6'h1: 
		if (~fifo_full) begin
			if (delay_avail) begin
				data_out <= {16'hee20, delay_tosend };
				data_available <= 1'b1;
				delay_ack <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[0]) begin
				data_out <= {16'hee00, 24'h0, b_count_0 };
				data_available <= 1'b1;
				count_ack[0] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[1]) begin
				data_out <= {16'hee01, 24'h0, b_count_1 };
				data_available <= 1'b1;
				count_ack[1] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[2]) begin
				data_out <= {16'hee02, 24'h0, b_count_2 };
				data_available <= 1'b1;
				count_ack[2] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[3]) begin
				data_out <= {16'hee03, 24'h0, b_count_3 };
				data_available <= 1'b1;
				count_ack[3] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[4]) begin
				data_out <= {16'hee04, 24'h0, b_count_4 };
				data_available <= 1'b1;
				count_ack[4] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[5]) begin
				data_out <= { 16'hee05, 24'h0, b_count_5 };
				data_available <= 1'b1;
				count_ack[5] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[6]) begin
				data_out <= {16'hee06, 24'h0, b_count_6 };
				data_available <= 1'b1;
				count_ack[6] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[7]) begin
				data_out <= {16'hee07, 24'h0, b_count_7 };
				data_available <= 1'b1;
				count_ack[7] <= 1'b1;
				state <= 6'h0;
			end
`ifndef __LX45__			
			else if (count_avail[8]) begin
				data_out <= {16'hee08, 24'h0, b_count_8 };
				data_available <= 1'b1;
				count_ack[8] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[9]) begin
				data_out <= {16'hee09, 24'h0, b_count_9 };
				data_available <= 1'b1;
				count_ack[9] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[10]) begin
				data_out <= {16'hee0a, 24'h0, b_count_a };
				data_available <= 1'b1;
				count_ack[10] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[11]) begin
				data_out <= {16'hee0b, 24'h0, b_count_b };
				data_available <= 1'b1;
				count_ack[11] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[12]) begin
				data_out <= {16'hee0c, 24'h0, b_count_c };
				data_available <= 1'b1;
				count_ack[12] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[13]) begin
				data_out <= { 16'hee0d, 24'h0, b_count_d };
				data_available <= 1'b1;
				count_ack[13] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[14]) begin
				data_out <= {16'hee0e, 24'h0, b_count_e };
				data_available <= 1'b1;
				count_ack[14] <= 1'b1;
				state <= 6'h0;
			end
			else if (count_avail[15]) begin
				data_out <= {16'hee0f, 24'h0, b_count_f };
				data_available <= 1'b1;
				count_ack[15] <= 1'b1;
				state <= 6'h0;
			end
`endif			
			else if (adc_avail[0]) begin
				data_out <= {16'hee10, adc_data_0 };
				data_available <= 1'b1;
				adc_ack[0] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[1]) begin
				data_out <= {16'hee11, adc_data_1 };
				data_available <= 1'b1;
				adc_ack[1] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[2]) begin
				data_out <= {16'hee12, adc_data_2 };
				data_available <= 1'b1;
				adc_ack[2] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[3]) begin
				data_out <= {16'hee13, adc_data_3 };
				data_available <= 1'b1;
				adc_ack[3] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[4]) begin
				data_out <= {16'hee14, adc_data_4 };
				data_available <= 1'b1;
				adc_ack[4] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[5]) begin
				data_out <= {16'hee15, adc_data_5 };
				data_available <= 1'b1;
				adc_ack[5] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[6]) begin
				data_out <= {16'hee16, adc_data_6 };
				data_available <= 1'b1;
				adc_ack[6] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[7]) begin
				data_out <= {16'hee17, adc_data_7 };
				data_available <= 1'b1;
				adc_ack[7] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[8]) begin
				data_out <= {16'hee18, adc_data_8 };
				data_available <= 1'b1;
				adc_ack[8] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[9]) begin
				data_out <= {16'hee19, adc_data_9 };
				data_available <= 1'b1;
				adc_ack[9] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[10]) begin
				data_out <= {16'hee1a, adc_data_a };
				data_available <= 1'b1;
				adc_ack[10] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[11]) begin
				data_out <= {16'hee1b, adc_data_b };
				data_available <= 1'b1;
				adc_ack[11] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[12]) begin
				data_out <= {16'hee1c, adc_data_c };
				data_available <= 1'b1;
				adc_ack[12] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[13]) begin
				data_out <= {16'hee1d, adc_data_d };
				data_available <= 1'b1;
				adc_ack[13] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[14]) begin
				data_out <= {16'hee1e, adc_data_e };
				data_available <= 1'b1;
				adc_ack[14] <= 1'b1;
				state <= 6'h0;
			end
			else if (adc_avail[15]) begin
				data_out <= {16'hee1f, adc_data_f };
				data_available <= 1'b1;
				adc_ack[15] <= 1'b1;
				state <= 6'h0;
			end
			else if (tdc_count_avail) begin
				data_out <= {16'hee21, 8'h0, tdc_count_buf };
				data_available <= 1'b1;
				tdc_ack <= 1'b1;
				state <= 6'h0;
			end
		end
	endcase
end

endmodule
