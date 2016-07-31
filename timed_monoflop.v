//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

// upon posedge <trigger> generates a pulse of length <pulselength> clockcycles at the output <q>

module timed_monoflop( 
	input wire clock, 
	input wire enable, 
	input wire [PulseLengthWidth-1:0] pulselength, 
	input wire trigger, 
	output wire q );
	
parameter PulseLengthWidth = 4;

reg load = 1'b0;
reg [PulseLengthWidth-1:0] Countdown = 0;
assign q = |Countdown;

always @ (posedge trigger or posedge q)
begin
  if (q)
    load <= 0;
  else if (enable)
    load <= 1;
end

always @ (posedge clock )
begin
  if (load)
	 Countdown[PulseLengthWidth-1:0] <= pulselength;
  else if (q)
    Countdown[PulseLengthWidth-1:0] <= Countdown[PulseLengthWidth-1:0] - 1'h1;
end

endmodule
