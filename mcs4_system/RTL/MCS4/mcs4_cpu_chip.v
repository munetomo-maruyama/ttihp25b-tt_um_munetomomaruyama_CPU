//===========================================================
// MCS-4 Project
//-----------------------------------------------------------
// File Name   : mcs4_cpu_chip.v
// Description : MCS-4 CPU Chip (i4004)
//-----------------------------------------------------------
// History :
// Rev.01 2025.05.19 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

//======================================
// Module : CPU Chip i4004
//======================================
module MCS4_CPU_CHIP
(
    input  wire       CLK,      // clock
    input  wire       RES_N,    // reset_n
    //
    output wire       SYNC_N,   // Sync Signal
    inout  wire [3:0] DATA,     // Data Input/Output
    output wire       CM_ROM_N, // Memory Control for ROM
    output wire [3:0] CM_RAM_N, // Memory Control for RAM
    input  wire       TEST      // Test Input
);

//---------------------------
// Data I/O Buffers
//---------------------------
wire [3:0] data_i;
wire [3:0] data_o;
wire       data_oe;
//
assign data_i = DATA;
assign DATA   = (data_oe)? data_o : 4'bz;

//---------------------------------
// MCS-4 CPU Core
//---------------------------------
//
MCS4_CPU_CORE U_MCS4_CPU_CORE
(
    .CLK   (CLK),   // clock
    .RES_N (RES_N), // reset_n
    //
    .SYNC_N   (SYNC_N),   // Sync Signal
    .DATA_I   (data_i),   // Data Input
    .DATA_O   (data_o),   // Data Output
    .DATA_OE  (data_oe),  // Data Output Enable
    .CM_ROM_N (CM_ROM_N), // Memory Control for ROM
    .CM_RAM_N (CM_RAM_N), // Memory Control for RAM
    .TEST     (TEST)      // Test Input
);

endmodule
//===========================================================
// End of File
//===========================================================
