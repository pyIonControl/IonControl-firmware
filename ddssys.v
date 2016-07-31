//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

`include	 "counter4b.v"
`include  "counter2b.v"
`include  "ipcore_dir/counter7b.v"
`include  "dcm180.v"

module dds_9958(
	output wire ready_o, 
	output wire [5:0] amp_o, 
	output reg [31:0] freq_o, 
	output reg [13:0] phase_o, 
	output wire [7:0] dds_spi_o, 
	output wire [63:0] check_o,
	output wire [7:0] id,
	input wire clk_i, 
	input wire reset_i, 
	input wire dds_reset_i,
	input wire [31:0] data_i, 
	input wire [3:0] cmd_i, 
	input wire cmdtrig_i, 
	input wire [1:0] sel,
	output reg [7:0] test_o);
	
	//ad9959
	assign id = 8'h00;
	
	localparam			ACMD_FRQ	= 2'b00;
	localparam			ACMD_PHS	= 2'b01;
	localparam			ACMD_AMP	= 2'b10;
	localparam			ACMD_CHN	= 2'b11;

    //addressing stuffs
	parameter   MYADDR = 0;
	wire  new_cmd_trig = cmdtrig_i & (cmd_i[3:2] == MYADDR) & ready_o;
	assign dds_spi_o[4] = dds_reset_i & (cmd_i[3:2] == MYADDR);

    //fix up inputs
	reg [39:0] fixedData;
	reg [3:0] limit;

	//input fixing mux
	/*always @(data_i, cmd_i) 
	case(cmd_i[1:0])
		ACMD_FRQ: begin
						limit <= 4'h9;
						fixedData[39:0] <= {8'h04, data_i[31:0]};
				  end
		ACMD_PHS: begin
						limit <= 4'h5;
						fixedData [39:0] <= (sel[1]) ? {16'h0005, 2'b00, data_i[13:0]} : {data_i[23:0], 16'h0000};//{data_i[31:24], 2'b00, data_i[13:0], 16'h0000};
				  end
		ACMD_AMP: begin
						limit <= 4'h7;
						fixedData <= (sel[1]) ? {20'h06001, data_i[11:0]}  : {data_i[31:0], 8'h00};//{data_i[31:24], 12'h001, 2'b00, data_i[9:0], 8'h00};
				  end
		ACMD_CHN: begin
						limit <= 4'h3;
						fixedData <= {data_i[15:0], 24'h0000000};
						test_o <= data_i[7:0];
					end
		endcase*/
		  
	always @(negedge clk_i) begin
		if (new_cmd_trig) begin
			case(cmd_i[1:0])
            ACMD_FRQ: begin
                        limit <= 4'h9;
								fixedData[39:0] <= {8'h04, data_i[31:0]};
                    end
            ACMD_PHS: begin
								limit <= 4'h5;
								fixedData[39:0] <= (sel[1]) ? {8'h05, 2'b00, data_i[13:0], 16'h0000} : {data_i[23:0], 16'h0000};//{data_i[31:24], 2'b00, data_i[13:0], 16'h0000}; Changed for correct phase operation CWC 10252012
                    end
            ACMD_AMP: begin
								limit <= 4'h7;
								fixedData[39:0] <= (sel[1]) ? {20'h06001, 2'b0, data_i[9:0], 8'h00}  : {data_i[31:0], 8'h00};//{data_i[31:24], 12'h001, 2'b00, data_i[9:0], 8'h00};
                    end
            ACMD_CHN: begin
								limit <= 4'h3;
								fixedData[39:0] <= {data_i[15:0], 24'h0000000};
								test_o <= data_i[7:0];
                    end
			endcase
		end
	end
	//piso declaration
	multiplexedPISO_9959 ddsSend(.clk(clk_i),  .rset(reset_i), .trig(new_cmd_trig), .parIn(fixedData[39:0]), .sel(sel[0]), .sdio(dds_spi_o[3:0]), .ioUpdate(dds_spi_o[7]), .csb(dds_spi_o[6]), .sclk(dds_spi_o[5]), .limit(limit[3:0]), .ready(ready_o));

	//SPI_4 CHECKER
	supply0 lo;
	wire [63:0] checkedData;
	wire [63:0] shifted = {checkedData[59:0], dds_spi_o[3:0]};
	wire read = ~dds_spi_o[6];
	ramW64D2 shifterRam(.clka(dds_spi_o[5]), .wea(read), .addra(lo), .dina(shifted[63:0]), .douta(checkedData[63:0]));
	
	assign check_o = checkedData;

endmodule

module dds_9959(
	output wire ready_o, 
	output wire [5:0] amp_o, 
	output reg [31:0] freq_o, 
	output reg [13:0] phase_o, 
	output wire [7:0] dds_spi_o, 
	output wire [63:0] check_o,
	output wire [7:0] id,
	input wire clk_i, 
	input wire reset_i, 
	input wire dds_reset_i,
	input wire [31:0] data_i, 
	input wire [3:0] cmd_i, 
	input wire cmdtrig_i, 
	input wire [1:0] sel,
	output reg [7:0] test_o);
	
	//ad9959
	assign id = 8'h01;
	
	localparam			ACMD_FRQ	= 2'b00;
	localparam			ACMD_PHS	= 2'b01;
	localparam			ACMD_AMP	= 2'b10;
	localparam			ACMD_CHN	= 2'b11;

    //addressing stuffs
	parameter   MYADDR = 0;
	wire  new_cmd_trig = cmdtrig_i & (cmd_i[3:2] == MYADDR) & ready_o;
	assign dds_spi_o[4] = dds_reset_i & (cmd_i[3:2] == MYADDR);

    //fix up inputs
	reg [39:0] fixedData;
	reg [3:0] limit;

	//input fixing mux
	/*always @(data_i, cmd_i) 
	case(cmd_i[1:0])
		ACMD_FRQ: begin
						limit <= 4'h9;
						fixedData[39:0] <= {8'h04, data_i[31:0]};
				  end
		ACMD_PHS: begin
						limit <= 4'h5;
						fixedData [39:0] <= (sel[1]) ? {16'h0005, 2'b00, data_i[13:0]} : {data_i[23:0], 16'h0000};//{data_i[31:24], 2'b00, data_i[13:0], 16'h0000};
				  end
		ACMD_AMP: begin
						limit <= 4'h7;
						fixedData <= (sel[1]) ? {20'h06001, data_i[11:0]}  : {data_i[31:0], 8'h00};//{data_i[31:24], 12'h001, 2'b00, data_i[9:0], 8'h00};
				  end
		ACMD_CHN: begin
						limit <= 4'h3;
						fixedData <= {data_i[15:0], 24'h0000000};
						test_o <= data_i[7:0];
					end
		endcase*/
		  
	always @(negedge clk_i) begin
		if (new_cmd_trig) begin
			case(cmd_i[1:0])
            ACMD_FRQ: begin
                        limit <= 4'h9;
								fixedData[39:0] <= {8'h04, data_i[31:0]};
                    end
            ACMD_PHS: begin
								limit <= 4'h5;
								fixedData[39:0] <= (sel[1]) ? {8'h05, 2'b00, data_i[13:0], 16'h0000} : {data_i[23:0], 16'h0000};//{data_i[31:24], 2'b00, data_i[13:0], 16'h0000}; Changed for correct phase operation CWC 10252012
                    end
            ACMD_AMP: begin
								limit <= 4'h7;
								fixedData[39:0] <= (sel[1]) ? {20'h06001, 2'b0, data_i[9:0], 8'h00}  : {data_i[31:0], 8'h00};//{data_i[31:24], 12'h001, 2'b00, data_i[9:0], 8'h00};
                    end
            ACMD_CHN: begin
								limit <= 4'h3;
								fixedData[39:0] <= {data_i[15:0], 24'h0000000};
								test_o <= data_i[7:0];
                    end
			endcase
		end
	end
	//piso declaration
	multiplexedPISO_9959 ddsSend(.clk(clk_i),  .rset(reset_i), .trig(new_cmd_trig), .parIn(fixedData[39:0]), .sel(sel[0]), .sdio(dds_spi_o[3:0]), .ioUpdate(dds_spi_o[7]), .csb(dds_spi_o[6]), .sclk(dds_spi_o[5]), .limit(limit[3:0]), .ready(ready_o));

	//SPI_4 CHECKER
	supply0 lo;
	wire [63:0] checkedData;
	wire [63:0] shifted = {checkedData[59:0], dds_spi_o[3:0]};
	wire read = ~dds_spi_o[6];
	ramW64D2 shifterRam(.clka(dds_spi_o[5]), .wea(read), .addra(lo), .dina(shifted[63:0]), .douta(checkedData[63:0]));
	
	assign check_o = checkedData;

endmodule

//PISO *******************************************************************************
module multiplexedPISO_9959(clk, rset, trig, parIn, sel, sdio, ioUpdate, csb, sclk, limit, ready);
	input wire clk;
	input wire rset;
	input wire trig;
	input wire [39:0] parIn;
	input wire sel;
	output wire [3:0] sdio;
	output wire ioUpdate;
	output wire csb;
	output wire sclk;
	input wire [3:0] limit;
	output wire ready;
	
	//ioupdate counter
	wire ioSend;
	wire ioSend_ = ~ioSend;
	wire [1:0] ioCounts;
	counter2b ioCtr(.sclr(ioSend_), .clk(clk), .q(ioCounts));
	wire ioEqual = &ioCounts[1:0];
	
	//serial multiplexed circuits
	wire send;
	wire send_ = ~send;
	
	//INIT - sends single-wire SPI signal
	reg [15:0] initWord = 16'h00c6; //16'b0000000011000110 accessing CSR register (0x00), enabling both channels, set to 4-bit serial mode, and MSB first 
	wire [3:0] initCounts;
	wire initSend = send_ | ~sel | ioSend;
	counter4b initCtr(.sclr(initSend), .clk(clk), .q(initCounts[3:0]));
	
	wire initDone = &initCounts[3:0];
	wire initPart1, initPart2, initOut;
	mux_8x1 im0(.in(initWord[15:8]), .sel(initCounts[2:0]), .out(initPart1));
	mux_8x1 im1(.in(initWord[7:0]), .sel(initCounts[2:0]), .out(initPart2));
	MUXF7 muxf7_i(.I0(initPart1), .I1(initPart2), .S(initCounts[3]), .O(initOut));
	
	//AD-32 - sends 4-wire SPI signal
	wire [3:0] adCounts;
	wire adSend = send_ | sel | ioSend;
	counter4b adCtr(.sclr(adSend), .clk(clk), .q(adCounts[3:0]));
	
	wire adDone = adCounts == limit; //4'h9;
	wire [3:0] adPart1, adPart2, adPart3, adPart4, adOut;
	mux_16x4 ad1(.in(parIn[39:24]), .sel(adCounts[1:0]), .out(adPart1[3:0]));
	mux_16x4 ad2(.in(parIn[23:8]), .sel(adCounts[1:0]), .out(adPart2[3:0]));
	
	MUXF6 muxf6_1(.I0(adPart1[3]), .I1(adPart2[3]), .S(adCounts[2]), .O(adPart3[3]));
	MUXF6 muxf6_2(.I0(adPart1[2]), .I1(adPart2[2]), .S(adCounts[2]), .O(adPart3[2]));
	MUXF6 muxf6_3(.I0(adPart1[1]), .I1(adPart2[1]), .S(adCounts[2]), .O(adPart3[1]));
	MUXF6 muxf6_4(.I0(adPart1[0]), .I1(adPart2[0]), .S(adCounts[2]), .O(adPart3[0]));
	
	MUXCY mxcy_1(.DI(parIn[7]), .CI(parIn[3]), .S(adCounts[0]), .O(adPart4[3]));
	MUXCY mxcy_2(.DI(parIn[6]), .CI(parIn[2]), .S(adCounts[0]), .O(adPart4[2]));
	MUXCY mxcy_3(.DI(parIn[5]), .CI(parIn[1]), .S(adCounts[0]), .O(adPart4[1]));
	MUXCY mxcy_4(.DI(parIn[4]), .CI(parIn[0]), .S(adCounts[0]), .O(adPart4[0]));
	
	MUXF7 muxf7_1(.I0(adPart3[3]), .I1(adPart4[3]), .S(adCounts[3]), .O(adOut[3]));
	MUXF7 muxf7_2(.I0(adPart3[2]), .I1(adPart4[2]), .S(adCounts[3]), .O(adOut[2]));
	MUXF7 muxf7_3(.I0(adPart3[1]), .I1(adPart4[1]), .S(adCounts[3]), .O(adOut[1]));
	MUXF7 muxf7_4(.I0(adPart3[0]), .I1(adPart4[0]), .S(adCounts[3]), .O(adOut[0]));

	//state machine
	wire serCtrRset = send_ | ioSend;
	wire serDone = initDone | adDone;
	wire done;
	wire done_ = ~done;
	wire toggle = (trig & send_) | done;
	FDCE_1 FDCE_1_1 (.Q(send), .C(clk), .CE(toggle), .CLR(rset), .D(send_));
	
	wire toggle2 = (send & serDone & ioSend_) | done;
	FDCE_1 FDCE_n_1(.Q(ioSend), .C(clk), .CE(toggle2), .CLR(rset), .D(ioSend_));
	
	wire toggle3 = (ioSend & ioEqual) | done;
	FDCE FDCE_n_2 (.Q(done), .C(clk), .CE(toggle3), .CLR(rset), .D(done_));
	
	//final assignments
	assign sdio[0] = (adOut[0] & ~sel) | (initOut & sel);
	assign sdio[3:1] = adOut[3:1];
	
	dcm180 dcm2(.CLKIN_IN(clk), .CLK180_OUT(sclk));
	
	//ire notDelayedUpdate = ioSend & ~sel;
	FDC FDC_n_1 (.Q(ioUpdate), .C(clk), .CLR(rset), .D(ioSend));
	
	wire csb1, csb2;
	assign csb1 = (~trig & send_) | ioSend;
	wire notDelayedCsb = (~trig & send_) | ioSend;
	FDC FDC_n_2 (.Q(csb2), .C(clk), .CLR(rset), .D(notDelayedCsb));
	assign csb = csb1 & csb2;
	
	assign ready = send_ & ~ioUpdate;
endmodule

//MUX STACK *******************************************************************************

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

module mux_8x1(in, sel, out);
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
endmodule


//*****************************************************************************************
/*module dds_9910(
	output wire ready_o,
	output wire [5:0] amp_o,
	output reg [31:0] freq_o,
	output reg [13:0] phase_o,
	output wire [12:0] dds_spi_o,
	output wire [63:0] check_o,
	output wire [7:0] id,
	input wire clk_i,
	input wire reset_i,
	input wire dds_reset_i,
	input wire [39:0] data_i, 
	input wire [3:0] cmd_i,
	input wire cmdtrig_i, 
	input wire sel);
	
	//ad9910
	assign id = 8'h02;
	
	localparam			ACMD_FRQ	= 2'b00;
	localparam			ACMD_PHS	= 2'b01;
	localparam			ACMD_AMP	= 2'b10;
	localparam			ACMD_INIT	= 2'b11;

    //addressing stuffs
	parameter   MYADDR = 0;
	wire  new_cmd_trig = cmdtrig_i & (cmd_i[3:2] == MYADDR);
	assign dds_spi_o[9] = dds_reset_i & (cmd_i[3:2] == MYADDR);
    
    //fix up inputs
	 reg [31:0] freq;
	 reg [15:0] amp, phs;
	 reg [7:0] addr;
    reg [6:0] limit;
	 wire [71:0] fixedData = {addr[7:0], amp[15:0], phs[15:0], freq[31:0]};
    
	//input fixing mux
	always @(negedge clk_i) begin
		if (new_cmd_trig) begin
			case(cmd_i[1:0])
            ACMD_FRQ: begin
                        limit <= 7'b1000111;//71 => 7'b1000111
                        //fixedData[71:0] <= 72'h0e08b5000020000000;
								addr <= 8'h0e;
								freq[31:0] <= data_i[31:0];
                    end
            ACMD_PHS: begin
								limit <= 7'b1000111;//71 => 7'b1000111
                        addr <= 8'h0e;
								phs[15:0] <= data_i[15:0];
                    end
            ACMD_AMP: begin
								limit <= 7'b1000111;//71 => 7'b1000111
                        addr <= 8'h0e;
								amp[15:0] <= {2'b0, data_i[13:0]};
                    end
            ACMD_INIT: begin
							limit <= 7'b0100111;//39 => 7'b0100111
							addr <= data_i[39:32];
							amp <= data_i[31:16];
							phs <= data_i[15:0];
//								1'b0: begin
//										limit <= 7'b0100111;//39 => 7'b0100111
//										addr <= 8'h02;
//										amp <= 16'h1d1f;
//										phs <= 16'h41c8;
//									end
//								1'b1: begin
//										limit <= 7'b0100111;//39 => 7'b0100111
//										addr <= 8'h01;
//										amp <= 16'h0100;
//										phs <= 16'h0820;
//									end
                    end
			endcase
		end
	end
	//piso declaration
	multiplexedPISO_9910 ddsSend(.clk(clk_i),  .rset(reset_i), .trig(new_cmd_trig), .parIn(fixedData[71:0]), .sel(sel), .sout(dds_spi_o[8]), .pout(dds_spi_o[7:0]), .ioUpdate(dds_spi_o[12]), .csb(dds_spi_o[11]), .sclk(dds_spi_o[10]), .limit(limit[6:0]), .ready(ready_o));

	//SPI_1 CHECKER
	supply0 lo;
	wire [63:0] checkedData;
	wire [63:0] shifted = {checkedData[62:0], dds_spi_o[8]};
	wire read = ~dds_spi_o[11];
	ramW64D2 shifterRam(.clka(dds_spi_o[10]), .wea(read), .addra(lo), .dina(shifted[63:0]), .douta(checkedData[63:0]));
	
	assign check_o = checkedData;
	
endmodule // ddssys

//PISO *******************************************************************************
module multiplexedPISO_9910(clk, rset, trig, parIn, sel, sout, pout, ioUpdate, csb, sclk, limit, ready);
	input wire clk;
	input wire rset;
	input wire trig;
	input wire [71:0] parIn;
	input wire sel;
	output wire sout; //7:0 == parallel wires, 8 == SPI wire
	output wire [7:0] pout;
	output wire ioUpdate;
	output wire csb;
	output wire sclk;
	input wire [6:0] limit;
	output wire ready;

	//ioupdate counter
	wire ioSend;
	wire ioSend_ = ~ioSend;
	wire [1:0] ioCounts;
	counter2b ioCtr(.sclr(ioSend_), .clk(clk), .q(ioCounts));
	wire ioEqual = &ioCounts[1:0];
	
	//serial multiplexed circuits
	wire send;
	wire send_ = ~send;
	
	//SPI - sends single-wire SPI signal
	//reg [71:0] initWord = 72'h021D1F41C8bcef0123;//72'h021D1F41C800000000;
	wire [6:0] initCounts;
	wire initSend = send_ | ~sel | ioSend;
	counter7b initCtr(.sclr(initSend), .clk(clk), .q(initCounts[6:0]));
	
	wire initDone = initCounts[6:0] == limit[6:0];  //71 => 7'b1000111, 39 => 7'b0100111
	wire [8:0] initPart1;
	wire initOut, initPart2;
	mux_8x1 m0(.in(parIn[7:0]), .sel(initCounts[2:0]), .out(initPart1[8]));
	mux_8x1 m1(.in(parIn[15:8]), .sel(initCounts[2:0]), .out(initPart1[0]));
	mux_8x1 m2(.in(parIn[23:16]), .sel(initCounts[2:0]), .out(initPart1[1]));
	mux_8x1 m4(.in(parIn[31:24]), .sel(initCounts[2:0]), .out(initPart1[2]));
	mux_8x1 m5(.in(parIn[39:32]), .sel(initCounts[2:0]), .out(initPart1[3]));
	mux_8x1 m6(.in(parIn[47:40]), .sel(initCounts[2:0]), .out(initPart1[4]));
	mux_8x1 m7(.in(parIn[55:48]), .sel(initCounts[2:0]), .out(initPart1[5]));
	mux_8x1 m8(.in(parIn[63:56]), .sel(initCounts[2:0]), .out(initPart1[6]));
	mux_8x1 m9(.in(parIn[71:64]), .sel(initCounts[2:0]), .out(initPart1[7]));
	
	//wire [7:0] initPart2 = {initPart1, 3'b0};
	mux_8x1 m10(.in(initPart1[7:0]), .sel(initCounts[5:3]), .out(initPart2));
	MUXCY m11(.O(initOut), .DI(initPart2), .CI(initPart1[8]), .S(initCounts[6]));
	
	//Parallel - sends 8-wire parallel signal
	//wire [3:0] adCounts;
	//wire adSend = send_ | sel | ioSend;
	//counter4b adCtr(.sclr(adSend), .clk(clk), .q(adCounts[3:0]));
	
	//wire adDone = adCounts == limit;
	//wire [7:0] adPart1, adPart2, adPart3, adPart4, adOut;


	//state machine
	wire serCtrRset = send_ | ioSend;
	wire serDone = initDone;// | adDone;
	wire done;
	wire done_ = ~done;
	wire toggle = (trig & send_) | done;
	FDCE_1 FDCE_1_1 (.Q(send), .C(clk), .CE(toggle), .CLR(rset), .D(send_));
	
	wire toggle2 = (send & serDone & ioSend_) | done;
	FDCE_1 FDCE_n_1(.Q(ioSend), .C(clk), .CE(toggle2), .CLR(rset), .D(ioSend_));
	
	wire toggle3 = (ioSend & ioEqual) | done;
	FDCE FDCE_n_2 (.Q(done), .C(clk), .CE(toggle3), .CLR(rset), .D(done_));
	
	//final assignments
	assign sout = initOut;
	assign pout[7:0] = {initCounts[5:0], send};
	
	dcm180 dcm2(.CLKIN_IN(clk), .CLK180_OUT(sclk));
	//assign sclk = ~clk;
	
	//ire notDelayedUpdate = ioSend & ~sel;
	FDC FDC_n_1 (.Q(ioUpdate), .C(clk), .CLR(rset), .D(ioSend));
	
	wire csb1, csb2;
	assign csb1 = (~trig & send_) | ioSend;
	wire notDelayedCsb = (~trig & send_) | ioSend;
	FDC FDC_n_2 (.Q(csb2), .C(clk), .CLR(rset), .D(notDelayedCsb));
	assign csb = csb1 & csb2;
	
	assign ready = send_ & ~ioUpdate;
endmodule*/
