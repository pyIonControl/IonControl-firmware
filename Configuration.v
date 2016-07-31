`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


`ifndef configuration_definition
`define configuration_definition

`define ConfigurationMD1
//`define ConfigurationMD1_8Counters
//`define ConfigurationCavity
//`define ConfigurationE
//`define ConfigurationQGA
//`define ConfigurationWiggelyBox
//`define ConfigurationDuke1
//////////////////////////////////////////////////////////////////////////////////
// Conditionals are used for the different breakout boards. 
// In addition to enabling the correct definition, you have to add the correct ucf file to the project
// and remove the ucf file of the wrong breakout board
//
// Original Sandia breakpout board.
//`define BreakoutSandiaOrig
//`define InvertSma
// Second version of sandia Breakout board
//`define BreakoutSandia2
//`define WiggelyLineBox
//`define PILoops      // Implement PI loops
//`define SMA8IsClock  // Valid for BreakoutDuke, puts 50MHz clock on sma[8] 
//
//`define PDHAutoLock
// Duke Breakout board
//`define BreakoutDuke
//`define BreakoutDukeADCDAC
//`define Out6IsAD9912
//`define Out6IsMagiq
//`define Out7IsAD9910
//`define Out7IsShutters
//`define SerialOutputOut2_7
//`define ExternalClock
//
// Debug: in debug mode internal clock divided signals are fed to the counter inputs instead of the
// external inputs. This is convenient for debugging, but totally useless for production
// make sure this line is commented out for a functional firmware
// `define Debug
///////////////////////////////////////////////////////////////////////////////////

`ifdef ConfigurationSandiaOrig
// needs xem6010-Breakout1.ucf
	`define BreakoutSandia2
	`define InvertSma
	`define Out6IsAD9912
	`define SerialOutputOut2_7
	`define PILoops
	parameter HardwareConfigurationId = 16'h4201;
`endif

`ifdef ConfigurationQGA
// needs xem6010-BreakoutDuke-readyForExtClk.ucf
	`define BreakoutDuke
	`define BreakoutDukeADCDAC
//	`define ExternalClock
	`define InvertSma
	`define Out6IsAD9912
	`define SerialOutputOut2_7
	`define PILoops
	`define DACScanning
	parameter HardwareConfigurationId = 16'h4202;
`endif

`ifdef ConfigurationQGAExt
// needs xem6010-BreakoutDuke_externalClock.ucf
	`define BreakoutDuke
	`define BreakoutDukeADCDAC
	`define ExternalClock
	`define InvertSma
	`define Out6IsAD9912
	`define SerialOutputOut2_7
	`define PILoops
	`define DACScanning
	parameter HardwareConfigurationId = 16'h4204;
`endif

`ifdef ConfigurationWiggelyBox
// needs xem6010-Breakout1.ucf
	`define BreakoutSandiaOrig
   `define WiggelyLineBox
	`define InvertSma
	`define PILoops
	parameter HardwareConfigurationId = 16'h4203;
`endif

`ifdef ConfigurationMD1
// needs xem6010-BreakoutDuke.ucf
	`define BreakoutDuke
	`define BreakoutDukeADCDAC
	`define Out6IsAD9912
	`define SerialOutputOut2_7
	`define Out7IsShutters
	`define PILoops
	`define DACScanning
//	`define __DISABLE_DIV__
	parameter HardwareConfigurationId = 16'h7001;
`endif

`ifdef ConfigurationMD1_8Counters
// needs xem6010-BreakoutDuke.ucf
	`define BreakoutDuke
	`define BreakoutDukeADCDAC
	`define Out6IsAD9912
	`define SerialOutputOut2_7
	`define Out7IsShutters
	`define PILoops
	`define DACScanning
	`define __LX45__
	parameter HardwareConfigurationId = 16'h7001;
`endif

`ifdef ConfigurationDuke1
// needs xem6010-BreakoutDuke.ucf
	`define BreakoutDuke
	`define BreakoutDukeADCDAC
	`define Out6IsAD9912
	`define Out7IsAD9910
	`define PILoops
	`define SerialOutputOut2_7
	parameter HardwareConfigurationId = 16'h7701;
`endif

`ifdef ConfigurationCavity
	`define BreakoutDuke
	`define BreakoutDukeADCDAC
	`define Out6IsAD9912
	`define Out7IsShutters
	`define PILoops
	`define SerialOutputOut2_7
	`define PDHAutoLock
	parameter HardwareConfigurationId = 16'h4204;
`endif

`ifdef ConfigurationE
	`define BreakoutDuke
	`define BreakoutDukeADCDAC
	`define Out6IsAD9912
	`define Out7IsShutters
	`define PILoops
	`define ExternalClock
	parameter HardwareConfigurationId = 16'h4205;
`endif

`define SlowDDSClk
//`define __LX45__
//`define __DISABLE_DIV__

`endif
