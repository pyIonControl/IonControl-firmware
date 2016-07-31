# IonControl-firmware
Sources of the firmware running on the Xilinx FPGA used in the IonControl project.

The FPGA verilog sources are designed for the Opal Kellly XEM-6010 boards with Xilinx Spartan-6 LX-45 
(use branch master-LX45) or LX-150 (use branch master).
For comilation the Xilinx ISE tool is necessary. Compilation can be done with the version freely available
from Xilinx for the LX-45 FPGA, the LX-150 requires a Vivado license.

To compile, first open the Core generator and regenerate all cores with current project settings, then
compile the project.
