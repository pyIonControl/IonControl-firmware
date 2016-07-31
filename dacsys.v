//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

/*`include	 "counter4b.v"
`include  "counter2b.v"
`include  "counter7b.v"
`include  "dcm180.v"
`include  "dcm90180.v"*/


/*//MUX STACK *******************************************************************************

module mux_16x4(in, sel, out);
	input wire [15:0] in;
	input wire [1:0] sel;
	output wire [3:0] out;
	
	wire [3:0] w0 = {in[15], in[11], in[7], in[3]}; 
	mux_4x1 m0(.in(w0[3:0]), .sel(sel[1:0]), .out(out[3]));
	
	wire [3:0] w1 = {in[14], in[10], in[6], in[2]}; 
	mux_4x1 m1(.in(w1[3:0]), .sel(sel[1:0]), .out(out[2]));
	
	wire [3:0] w2 = {in[13], in[9], in[5], in[1]}; 
	mux_4x1 m2(.in(w2[3:0]), .sel(sel[1:0]), .out(out[1]));
	
	wire [3:0] w3 = {in[12], in[8], in[4], in[0]}; 
	mux_4x1 m3(.in(w3[3:0]), .sel(sel[1:0]), .out(out[0]));
endmodule
*/

/*module mux_8x1(in, sel, out);
	input wire [7:0] in;
	input wire [2:0] sel;
	output wire out;
	wire [1:0] bus;

	mux_4x1 m1(.in(in[7:4]), .sel(sel[1:0]), .out(bus[1]));
	mux_4x1 m2(.in(in[3:0]), .sel(sel[1:0]), .out(bus[0]));

	//the input wires must be parsed backwards
	MUXF6 muxf6_2(.I0(bus[1]), .I1(bus[0]), .S(sel[2]), .O(out));
endmodule

module mux_4x1(in, sel, out);
	input wire [3:0] in;
	input wire [1:0] sel;
	output reg out;
	always @(in or sel)
		case(sel)
			2'b00: out <= in[3];	//the input wires must be parsed backwards
			2'b01: out <= in[2];
			2'b10: out <= in[1];
			2'b11: out <= in[0];
			default: out <= 1'bx;
		endcase
endmodule*/


//*****************************************************************************************
module dac_5390(
	output wire ready_o,
	output wire [4:0] dac_spi_o,
	//output wire [63:0] check_o,
	//output wire [7:0] id,
	input wire busy_i,
	input wire clk_i,
	input wire reset_i,
	input wire dac_reset_i,
	input wire [23:0] data_i, 
	//input wire [3:0] cmd_i,
	input wire cmdtrig_i, 
	input wire LDAC_trig_i,
	input wire init,
	output wire [1:0] test_o);
	
	//assign id = 8'h02;

   //addressing stuffs
	//parameter   MYADDR = 0;
	wire  new_cmd_trig = cmdtrig_i;// & (cmd_i[3:2] == MYADDR);
	assign dac_spi_o[4] = dac_reset_i;// & (cmd_i[3:2] == MYADDR);
    
   reg [5:0] limit = 5'b10111;  
	wire send_status;
	assign ready_o = send_status;// & busy_i; Commented so the FPGA does not wait for the DAC
	
	//piso declaration
	multiplexedPISO_5390 dacSend(.clk(clk_i),  .rset(reset_i), .trig(new_cmd_trig), .ParIn(data_i[23:0]), .init(init), .sclk(dac_spi_o[0]), .SYNC_(dac_spi_o[1]), .LDAC_trig(LDAC_trig_i), .LDAC_(dac_spi_o[3]), .sout(dac_spi_o[2]), .limit(limit[5:0]), .ready(send_status), .test(test_o[1:0]));// ,

	//SPI_1 CHECKER
	/*supply0 lo;
	wire [63:0] checkedData;
	wire [63:0] shifted = {checkedData[62:0], dds_spi_o[8]};
	wire read = ~dds_spi_o[11];
	ramW64D2 shifterRamDac(.clka(dac_spi_o[10]), .wea(read), .addra(lo), .dina(shifted[63:0]), .douta(checkedData[63:0]));
	
	assign check_o = checkedData;*/
	
endmodule // dacsys

//PISO *******************************************************************************
module multiplexedPISO_5390(clk, rset, trig, ParIn, init, sclk, SYNC_, LDAC_trig, sout, limit, ready, test, LDAC_);//,  
	input wire clk;
	input wire rset;
	input wire trig;
	input wire [23:0] ParIn;
	input wire init;
	//output wire [7:0] pout;
	output wire sclk;
	output wire SYNC_;
	input wire LDAC_trig;
	output wire sout; //7:0 == parallel wires, 8 == SPI wire
	output wire LDAC_;
	input wire [5:0] limit;
	output wire ready;
	output wire [2:0] test;
	wire dacclk;
	
	wire clk_2, clk_buf;

	dcm90180 dcm2(.CLKIN_IN(clk), .CLKDV_OUT(clk_2)); // Get a dacclk to be the divided DCM CLK out (CLKDV_DIVIDE), divide by 2 to get sclk below 30 MHz; CWC 08142012
	dcm90180 dcm3(.CLKIN_IN(clk_2), .CLK90_OUT(dacclk), .CLK180_OUT(clk_buff));
	//Extend the trig pulses with Trig counter 
	wire trigd;
	wire trigd_ = ~trigd;
	wire trigEqual;
	/*FDC FDC_trig (.Q(trigd), .C(trig), .CLR(rset|trigEqual), .D(trigd_));
	wire [3:0] trigCounts; //specify the length of the extended trig pulses
	counter4b trigCtr(.sclr(trigd_), .clk(clk), .q(trigCounts));
	assign trigEqual = trigCounts[2:0]==3'b100;*/
	
	FDC FDC_trig (.Q(trigd), .C(trig), .CLR(rset|trigEqual), .D(trigd_));
	wire [1:0] trigCounts; //specify the length of the extended trig pulses
	counter2b trigCtr(.sclr(trigd_), .clk(dacclk), .q(trigCounts));
	assign trigEqual = trigCounts[1:0]==2'b10;
	
	wire sync_trig;
	wire sync_trig_ = ~sync_trig;
	FDCE FDCE_sync_trig (.Q(sync_trig), .C(dacclk), .CE(trigd | sync_trig), .CLR(rset), .D(sync_trig_));
	

	wire ioSend;
	wire ioSend_ = ~ioSend;
	wire [3:0] ioCounts; //specify the length of the LDAC_ pulses
	counter4b ioCtrDAC(.sclr(ioSend_), .clk(dacclk), .q(ioCounts));
	wire ioEqual = ioCounts[3:0]==4'b1000;
	
	//serial multiplexed circuits
	wire send;
	wire send_ = ~send;
	
	//SPI - sends single-wire SPI signal
	reg [23:0] initWord = 24'h0c3e00;//24'b000011000011111000000000; See AD5390 datasheet p.33, control register write CWC 08142012
	wire [6:0] initCounts;
	wire initSend = send_ | ~init | ioSend;
	counter7b initCtr(.sclr(initSend), .clk(dacclk), .q(initCounts[6:0]));
	
	wire initDone = initCounts[4:0] == 5'b10111;  //71 => 7'b1000111, 39 => 7'b0100111, 23=>5'b10111
	wire [2:0] initPart1;
	wire initOut, initPart2;
	mux_8x1 m0(.in(initWord[7:0]), .sel(initCounts[2:0]), .out(initPart1[2]));
	mux_8x1 m1(.in(initWord[15:8]), .sel(initCounts[2:0]), .out(initPart1[0]));
	mux_8x1 m2(.in(initWord[23:16]), .sel(initCounts[2:0]), .out(initPart1[1]));
	
	MUXCY m3(.O(initPart2), .DI(initPart1[1]), .CI(initPart1[0]), .S(initCounts[3]));
	MUXCY m4(.O(initOut), .DI(initPart2), .CI(initPart1[2]), .S(initCounts[4]));
	
	//Parallel - sends 8-wire parallel signal
	wire [6:0] adCounts;
	wire adSend = send_ | init | ioSend;
	counter7b adCtr(.sclr(adSend), .clk(dacclk), .q(adCounts[6:0]));
	
	wire adDone = adCounts[4:0] == limit;
	wire [2:0] adPart1; 
	wire adPart2, adOut;
	mux_8x1 m5(.in(ParIn[7:0]), .sel(adCounts[2:0]), .out(adPart1[2]));//ParIn
	mux_8x1 m6(.in(ParIn[15:8]), .sel(adCounts[2:0]), .out(adPart1[0]));
	mux_8x1 m7(.in(ParIn[23:16]), .sel(adCounts[2:0]), .out(adPart1[1]));
	
	MUXCY m8(.O(adPart2), .DI(adPart1[1]), .CI(adPart1[0]), .S(adCounts[3]));
	MUXCY m9(.O(adOut), .DI(adPart2), .CI(adPart1[2]), .S(adCounts[4]));

	//state machine
	wire serCtrRset = send_ | ioSend;
	wire serDone = initDone | adDone;
	wire done;
	wire done_ = ~done;
	wire toggle = (sync_trig & send_) | done;
	FDCE_1 FDCE_1_1 (.Q(send), .C(dacclk), .CE(toggle), .CLR(rset), .D(send_));
	
	wire toggle2 = (send & serDone & ioSend_) | done;
	FDCE_1 FDCE_n_1(.Q(ioSend), .C(dacclk), .CE(toggle2), .CLR(rset), .D(ioSend_));
	
	wire toggle3 = (ioSend & ioEqual) | done;
	FDCE FDCE_n_2 (.Q(done), .C(dacclk), .CE(toggle3), .CLR(rset), .D(done_));
	
	//final assignments
	assign sout = (adOut & ~init) | (initOut & init);
	
	//dcm180 dcm2(.CLKIN_IN(clk), .CLK90_OUT(sclk));
	//assign sclk = clk;
	
	/*wire LDAC;
	//wire notDelayedUpdate = ioSend & ~init;
	FDC FDC_n_1 (.Q(LDAC), .C(sclk), .CLR(rset), .D(ioSend));*/
	//assign LDAC_ = ~toggle3;
	//assign LDAC_ = 1'b0; 
	wire LDAC_trigd;
	wire LDAC_trigd_ = ~LDAC_trigd;
	wire LDAC_trigEqual;
	
	FDC FDC_LDAC_trig (.Q(LDAC_trigd), .C(LDAC_trig), .CLR(rset|LDAC_trigEqual), .D(LDAC_trigd_));
	wire [1:0] LDAC_trigCounts; //specify the length of the extended trig pulses
	counter2b LDAC_trigCtr(.sclr(LDAC_trigd_), .clk(dacclk), .q(LDAC_trigCounts));
	assign LDAC_trigEqual = LDAC_trigCounts[1:0]==2'b10;
	
	wire sync_LDAC_trig;
	wire sync_LDAC_trig_ = ~sync_LDAC_trig;
	FDCE FDCE_sync_LDAC_trig (.Q(sync_LDAC_trig), .C(dacclk), .CE(LDAC_trigd | sync_LDAC_trig), .CLR(rset), .D(sync_LDAC_trig_));

	assign LDAC_ = sync_LDAC_trig_;
	
	wire SYNC_1, SYNC_2;
	assign SYNC_1 = (~sync_trig & send_) | ioSend;
	wire notDelayedSYNC_ = (~sync_trig & send_) | ioSend;
	FDC FDC_n_2 (.Q(SYNC_2), .C(dacclk), .CLR(rset), .D(notDelayedSYNC_));
	assign SYNC_ = SYNC_1 & SYNC_2;
	assign sclk = (SYNC_ == 1'b1)? 1'b0:clk_buff;
	
	assign ready = trigd_ & send_; //& LDAC_;	
	
	assign test[0] = sync_trig; //XBus-54
	assign test[1] = trig; //XBus-55
	//assign test[2] = trigd; //XBus-56
	
endmodule
