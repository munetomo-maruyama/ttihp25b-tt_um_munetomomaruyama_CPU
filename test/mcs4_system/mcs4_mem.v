//===========================================================
// MCS-4 Project
//-----------------------------------------------------------
// File Name   : mcs4_mem.v
// Description : MCS-4 ROM(i4001 x 16chips)
//                     RAM(i4002 x 8banks x 4chips)
//-----------------------------------------------------------
// History :
// Rev.01 2025.05.19 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

module MCS4_MEM
(
    input  wire CLK,   // Clock
    input  wire RES_N, // Reset
    //
    input  wire        SYNC_N,   // CPU Sync Signal
    inout  wire [ 3:0] DATA,     // CPU Data Input/Output
    input  wire        CM_ROM_N, // CPU Memory Control for ROM
    input  wire [ 3:0] CM_RAM_N, // CPU Memory Control for RAM
    //
    input  wire [31:0] PORT_IN_ROM_CHIP7_CHIP0,  // ROM Port In,  Chip7 - Chip0, each 4bits
    input  wire [31:0] PORT_IN_ROM_CHIPF_CHIP8,  // ROM Port In,  ChipF - Chip8, each 4bits
    output wire [31:0] PORT_OUT_ROM_CHIP7_CHIP0, // ROM Port Out, Chip7 - Chip0, each 4bits
    output wire [31:0] PORT_OUT_ROM_CHIPF_CHIP8, // ROM Port Out, ChipF - Chip8, each 4bits
    output wire [31:0] PORT_OUT_RAM_BANK1_BANK0, // RAM Port Out, Bank1 - Bank0, Chip3 - Chip0, each 4bits
    output wire [31:0] PORT_OUT_RAM_BANK3_BANK2, // RAM Port Out, Bank3 - Bank2, Chip3 - Chip0, each 4bits
    output wire [31:0] PORT_OUT_RAM_BANK5_BANK4, // RAM Port Out, Bank5 - Bank4, Chip3 - Chip0, each 4bits
    output wire [31:0] PORT_OUT_RAM_BANK7_BANK6  // RAM Port Out, Bank7 - Bank6, Chip3 - Chip0, each 4bits
);

//---------------------
// Data Interface
//---------------------
wire [3:0] data_i_rom;
wire [3:0] data_o_rom;
wire       data_o_rom_oe;
wire [3:0] data_i_ram;
wire [3:0] data_o_ram;
wire       data_o_ram_oe;
//
assign data_i_rom = DATA;
assign data_i_ram = DATA;
assign DATA = (data_o_rom_oe)? data_o_rom
            : (data_o_ram_oe)? data_o_ram
            : 4'bzzzz;

//----------------
// Decode CM_RAM 
//----------------
wire [7:0] cm_ram_n_decoded;
//
assign cm_ram_n_decoded
    = (CM_RAM_N == 4'b1110)? 8'b11111110 // bank0
    : (CM_RAM_N == 4'b1101)? 8'b11111101 // bank1
    : (CM_RAM_N == 4'b1011)? 8'b11111011 // bank2
    : (CM_RAM_N == 4'b1001)? 8'b11110111 // bank3
    : (CM_RAM_N == 4'b0111)? 8'b11101111 // bank4
    : (CM_RAM_N == 4'b0101)? 8'b11011111 // bank5
    : (CM_RAM_N == 4'b0011)? 8'b10111111 // bank6
    : (CM_RAM_N == 4'b0001)? 8'b01111111 // bank7
    : 8'b11111111;
                
//-----------------------------
// ROM Chips (i4001 x 16chips)
//-----------------------------
MCS4_ROM U_MCS4_ROM
(
    .CLK     (CLK),
    .RES_N   (RES_N),
    .SYNC_N  (SYNC_N),
    .DATA_I  (data_i_rom),
    .DATA_O  (data_o_rom),
    .DATA_OE (data_o_rom_oe),
    .CM_N    (CM_ROM_N),
    .CL_N    ({16{RES_N}}),
    //
    .PORT_IN_ROM_CHIP7_CHIP0  (PORT_IN_ROM_CHIP7_CHIP0),
    .PORT_IN_ROM_CHIPF_CHIP8  (PORT_IN_ROM_CHIPF_CHIP8),
    .PORT_OUT_ROM_CHIP7_CHIP0 (PORT_OUT_ROM_CHIP7_CHIP0),
    .PORT_OUT_ROM_CHIPF_CHIP8 (PORT_OUT_ROM_CHIPF_CHIP8)
);

//---------------------------------------
// RAM Chips (i4002 x 8banks x 4chips)
//---------------------------------------
MCS4_RAM U_MCS4_RAM
(
    .CLK     (CLK),
    .RES_N   (RES_N),
    .SYNC_N  (SYNC_N),
    .DATA_I  (data_i_ram),
    .DATA_O  (data_o_ram),
    .DATA_OE (data_o_ram_oe),
    .CM_N    (cm_ram_n_decoded),
    //
    .PORT_OUT_RAM_BANK1_BANK0 (PORT_OUT_RAM_BANK1_BANK0),
    .PORT_OUT_RAM_BANK3_BANK2 (PORT_OUT_RAM_BANK3_BANK2),
    .PORT_OUT_RAM_BANK5_BANK4 (PORT_OUT_RAM_BANK5_BANK4),
    .PORT_OUT_RAM_BANK7_BANK6 (PORT_OUT_RAM_BANK7_BANK6)
);

//===========================================================
endmodule
//===========================================================
