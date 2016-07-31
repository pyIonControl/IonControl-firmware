////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2011 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: O.40d
//  \   \         Application: netgen
//  /   /         Filename: counter2b.v
// /___/   /\     Timestamp: Fri Sep  9 12:33:09 2011
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -w -sim -ofmt verilog /home/brownlab/Documents/Spencer/spiTest/tmp/_cg/counter2b.ngc /home/brownlab/Documents/Spencer/spiTest/tmp/_cg/counter2b.v 
// Device	: 3s1000fg320-4
// Input file	: /home/brownlab/Documents/Spencer/spiTest/tmp/_cg/counter2b.ngc
// Output file	: /home/brownlab/Documents/Spencer/spiTest/tmp/_cg/counter2b.v
// # of Modules	: 1
// Design Name	: counter2b
// Xilinx        : /opt/Xilinx/13.1/ISE_DS/ISE/
//             
// Purpose:    
//     This verilog netlist is a verification model and uses simulation 
//     primitives which may not represent the true implementation of the 
//     device, however the netlist is functionally correct and should not 
//     be modified. This file cannot be synthesized and should only be used 
//     with supported simulation tools.
//             
// Reference:  
//     Command Line Tools User Guide, Chapter 23 and Synthesis and Simulation Design Guide, Chapter 6
//             
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ps

module counter2b (
  clk, sclr, q
)/* synthesis syn_black_box syn_noprune=1 */;
  input clk;
  input sclr;
  output [1 : 0] q;
  
  // synthesis translate_off
  
  wire N0;
  wire N1;
  wire [0 : 0] \U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/carry_simple ;
  wire [0 : 0] \U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/halfsum ;
  wire [2 : 1] \NlwRenamedSig_OI_U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_q.i_simple.qreg/fd/output ;
  wire [1 : 0] \U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/s ;
  assign
    q[1] = 
\NlwRenamedSig_OI_U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_q.i_simple.qreg/fd/output [2],
    q[0] = 
\NlwRenamedSig_OI_U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_q.i_simple.qreg/fd/output [1];
  GND   XST_GND (
    .G(N0)
  );
  VCC   XST_VCC (
    .P(N1)
  );
  FDR #(
    .INIT ( 1'b0 ))
  \U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_q.i_simple.qreg/fd/output_1  (
    .C(clk),
    .D(\U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/s [0]),
    .R(sclr),
    .Q
(\NlwRenamedSig_OI_U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_q.i_simple.qreg/fd/output [1])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_q.i_simple.qreg/fd/output_2  (
    .C(clk),
    .D(\U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/s [1]),
    .R(sclr),
    .Q
(\NlwRenamedSig_OI_U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_q.i_simple.qreg/fd/output [2])
  );
  MUXCY   \U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_simple_model.i_need_mux.carrymux0  (
    .CI(N0),
    .DI(N1),
    .S(\U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/halfsum [0]),
    .O(\U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/carry_simple [0])
  );
  XORCY   \U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_simple_model.carryxor0  (
    .CI(N0),
    .LI(\U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/halfsum [0]),
    .O(\U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/s [0])
  );
  XORCY   \U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_simple_model.i_gt_1.carryxortop  (
    .CI(\U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/carry_simple [0]),
    .LI
(\NlwRenamedSig_OI_U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_q.i_simple.qreg/fd/output [2]),
    .O(\U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/s [1])
  );
  INV   \U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/halfsum_not00001_INV_0  (
    .I
(\NlwRenamedSig_OI_U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/i_q.i_simple.qreg/fd/output [1]),
    .O(\U0/i_synth/i_baseblox.i_baseblox_counter/the_addsub/no_pipelining.the_addsub/i_lut4.i_lut4_addsub/halfsum [0])
  );

// synthesis translate_on

endmodule

// synthesis translate_off

`ifndef GLBL
`define GLBL

`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;

    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (weak1, weak0) GSR = GSR_int;
    assign (weak1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule

`endif

// synthesis translate_on
