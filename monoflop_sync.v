//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module monoflop_sync( 
	input wire clock, 
	input wire enable, 
	input wire trigger, 
	output reg q=0 );

reg tmp;
reg q0 = 0;
reg q1 = 0;

always @ (posedge trigger or posedge q0)
begin
  if (q0)
    tmp <= 0;
  else if (enable)
    tmp <= 1;
end

always @ (posedge clock )
begin
  if (tmp)
    q0 <= 1;
  else
    q0 <= 0;
end

always @(posedge clock)
begin
	q1 <= q0;
	q <= q1;
end

endmodule
