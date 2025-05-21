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
    $readmemh("./mcs4_system/4001.code", U_MCS4_MEM.U_MCS4_ROM.rom);
end

//-------------------------
// Initialize RAM (so far)
//-------------------------
initial
begin
    for (i = 0; i < 2048; i = i + 1) U_MCS4_MEM.U_MCS4_RAM.ram_ch[i] = 4'b0000;
    for (i = 0; i <  512; i = i + 1) U_MCS4_MEM.U_MCS4_RAM.ram_st[i] = 4'b0000;    
end

//-----------------------
// Module Under Test
//-----------------------
wire        tb_res;
wire        tb_clk;
wire        sync_n;
wire [ 3:0] data;
wire        cm_rom_n;
wire [ 3:0] cm_ram_n;
wire        test;
//
wire [31:0] port_in_rom_chip7_chip0;
wire [31:0] port_in_rom_chipF_chip8;
wire [31:0] port_out_rom_chip7_chip0;
wire [31:0] port_out_rom_chipF_chip8;
wire [31:0] port_out_ram_bank1_bank0;
wire [31:0] port_out_ram_bank3_bank2;
wire [31:0] port_out_ram_bank5_bank4;
wire [31:0] port_out_ram_bank7_bank6;
//
reg  enable_keyprt;
wire test_keyprt;
wire [31:0] port_in_rom_chip7_chip0_keyprt;
wire [31:0] port_in_rom_chipF_chip8_keyprt;
reg  [31:0] port_keyprt_cmd;
wire [31:0] port_keyprt_res;
//
MCS4_CPU U_MCS4_CPU
(
    .CLK   (tb_clk),  // clock
    .RES_N (~tb_res), // reset_n
    //
    .SYNC_N   (sync_n),   // Sync Signal
    .DATA     (data),     // Data Input/Output
    .CM_ROM_N (cm_rom_n), // Memory Control for ROM
    .CM_RAM_N (cm_ram_n), // Memory Control for RAM
    .TEST     (test)      // Test Input
);
//
MCS4_MEM U_MCS4_MEM
(
    .CLK   (tb_clk),
    .RES_N (~tb_res),
    //
    .SYNC_N   (sync_n),   // Sync Signal
    .DATA     (data),     // Data Input/Output
    .CM_ROM_N (cm_rom_n), // Memory Control for ROM
    .CM_RAM_N (cm_ram_n), // Memory Control for RAM
    //
    .PORT_IN_ROM_CHIP7_CHIP0  (port_in_rom_chip7_chip0),
    .PORT_IN_ROM_CHIPF_CHIP8  (port_in_rom_chipF_chip8),
    .PORT_OUT_ROM_CHIP7_CHIP0 (port_out_rom_chip7_chip0),
    .PORT_OUT_ROM_CHIPF_CHIP8 (port_out_rom_chipF_chip8),
    .PORT_OUT_RAM_BANK1_BANK0 (port_out_ram_bank1_bank0),
    .PORT_OUT_RAM_BANK3_BANK2 (port_out_ram_bank3_bank2),
    .PORT_OUT_RAM_BANK5_BANK4 (port_out_ram_bank5_bank4),
    .PORT_OUT_RAM_BANK7_BANK6 (port_out_ram_bank7_bank6)
);
//
KEY_PRINTER KEY_PRINTER
(
    .CLK     (tb_clk),
    .RES_N   (~tb_res),
    .ENABLE  (enable_keyprt),
    .TEST    (test_keyprt),
    //
    .PORT_IN_ROM_CHIP7_CHIP0  (port_in_rom_chip7_chip0_keyprt),
    .PORT_IN_ROM_CHIPF_CHIP8  (port_in_rom_chipF_chip8_keyprt),
    .PORT_OUT_ROM_CHIP7_CHIP0 (port_out_rom_chip7_chip0),
    .PORT_OUT_ROM_CHIPF_CHIP8 (port_out_rom_chipF_chip8),
    .PORT_OUT_RAM_BANK1_BANK0 (port_out_ram_bank1_bank0),
    .PORT_OUT_RAM_BANK3_BANK2 (port_out_ram_bank3_bank2),
    .PORT_OUT_RAM_BANK5_BANK4 (port_out_ram_bank5_bank4),
    .PORT_OUT_RAM_BANK7_BANK6 (port_out_ram_bank7_bank6),
    //
    .PORT_KEYPRT_CMD (port_keyprt_cmd),
    .PORT_KEYPRT_RES (port_keyprt_res)
);

//--------------
// Port In
//--------------
assign test = (enable_keyprt)? test_keyprt : 1'b0;
assign port_in_rom_chip7_chip0 = (enable_keyprt)? port_in_rom_chip7_chip0_keyprt : 32'h76543210;
assign port_in_rom_chipF_chip8 = (enable_keyprt)? port_in_rom_chipF_chip8_keyprt : 32'hfedcba98;

//===========================================================
endmodule
//===========================================================
