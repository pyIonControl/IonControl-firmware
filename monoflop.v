//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module monoflop( 
	input wire clock, 
	input wire enable, 
	input wire trigger, 
	output reg q=0 );

reg tmp;

always @ (posedge trigger or posedge q)
begin
  if (q)
    tmp <= 0;
  else if (enable)
    tmp <= 1;
end

always @ (posedge clock )
begin
  if (tmp)
    q <= 1;
  else
    q <= 0;
end

endmodule
