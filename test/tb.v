//===========================================================
// MCS-4 Project
//-----------------------------------------------------------
// File Name   : mcs4_tb.v
// Description : Testbench of MCS-4 System
//-----------------------------------------------------------
// History :
// Rev.01 2025.05.19 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

// This testbench just instantiates the module and makes some convenient wires
// that can be driven / tested by the cocotb test.py.

`default_nettype none
`timescale 1ns / 100ps

//-----------------------------
// Testbench
//-----------------------------
module tb ();

integer i;

//-----------------------------
// Generate Wave File to Check
//-----------------------------
initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
end

//------------------
// Initialize ROM
//------------------
initial
begin
    $readmemh("4001.code", U_MCS4_SYS.U_MCS4_ROM.rom);
end

//-------------------------
// Initialize RAM (so far)
//-------------------------
initial
begin
    for (i = 0; i < 2048; i = i + 1) U_MCS4_SYS.U_MCS4_RAM.ram_ch[i] = 4'b0000;
    for (i = 0; i <  512; i = i + 1) U_MCS4_SYS.U_MCS4_RAM.ram_st[i] = 4'b0000;    
end

//-----------------------
// Signals in TestBench
//-----------------------
wire        tb_res;
wire        tb_clk;
//
wire        sync_n;
wire [ 3:0] data;
wire        cm_rom_n;
wire [ 3:0] cm_ram_n;
wire        test;
//
wire [31:0] port_keyprt_cmd;
wire [31:0] port_keyprt_res;

//---------------------------------
// MCS-4 CPU Chip i4004
//---------------------------------
wire [7:0] ui_in;    // Dedicated inputs
wire [7:0] uo_out;   // Dedicated outputs
wire [7:0] uio_in;   // IOs: Input path
wire [7:0] uio_out;  // IOs: Output path
wire [7:0] uio_oe;   // IOs: Enable path (active high: 0=input, 1=output)
wire       ena;      // always 1 when the design is powered, so you can ignore it
wire       clk;      // clock
wire       rst_n;    // reset_n - low to reset
//
assign ui_in[0]    = test;
assign sync_n      = uo_out[0];
assign cm_rom_n    = uo_out[1];
assign cm_ram_n[0] = uo_out[4];
assign cm_ram_n[1] = uo_out[5];
assign cm_ram_n[2] = uo_out[6];
assign cm_ram_n[3] = uo_out[7];
assign uio_in[0]   = data[0];
assign uio_in[1]   = data[1];
assign uio_in[2]   = data[2];
assign uio_in[3]   = data[3];
assign data[0]     = (uio_oe[0])? uio_out[0] : 1'bz; // open drain
assign data[1]     = (uio_oe[1])? uio_out[1] : 1'bz; // open drain
assign data[2]     = (uio_oe[2])? uio_out[2] : 1'bz; // open drain
assign data[3]     = (uio_oe[3])? uio_out[3] : 1'bz; // open drain
assign ena         = 1'b1;
//
pullup(data[0]);
pullup(data[1]);
pullup(data[2]);
pullup(data[3]);
//
tt_um_munetomomaruyama_CPU U_CHIP
(
    .ui_in   (ui_in),    // Dedicated inputs
    .uo_out  (uo_out),   // Dedicated outputs
    .uio_in  (uio_in),   // IOs: Input path
    .uio_out (uio_out),  // IOs: Output path
    .uio_oe  (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
    .ena     (ena),      // always 1 when the design is powered, so you can ignore it
    .clk     (tb_clk),   // clock
    .rst_n   (~tb_res)   // reset_n - low to reset
);

//---------------------------------------------
// MCS-4 System ROM + RAM + Key&Printer I/F
//---------------------------------------------
MCS4_SYS U_MCS4_SYS
(
    // CPU Interfface (i4004)
    .CLK   (tb_clk),  // clock
    .RES_N (~tb_res), // reset_n
    //
    .SYNC_N   (sync_n),   // Sync Signal
    .DATA     (data),     // Data Input/Output
    .CM_ROM_N (cm_rom_n), // Memory Control for ROM
    .CM_RAM_N (cm_ram_n), // Memory Control for RAM
    .TEST     (test),     // Test Input
    //
    // Calculator Command : Host MCU (UI) --> MCS4_SYS
    .PORT_KEYPRT_CMD (port_keyprt_cmd),
    //
    // Calculator Response : MCS4_SYS --> Host MCU (UI)
    .PORT_KEYPRT_RES (port_keyprt_res)
);

endmodule
//===========================================================
// End of File
//===========================================================
