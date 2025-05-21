//===========================================================
// MCS-4 Project
//-----------------------------------------------------------
// File Name   : mcs4_cpu.v
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
module MCS4_CPU
(
    input  wire        CLK,      // clock
    input  wire        RES_N,    // reset_n
    //
    output wire        SYNC_N,   // Sync Signal
    inout  wire [ 3:0] DATA,     // Data Input/Output
    output wire        CM_ROM_N, // Memory Control for ROM
    output wire [ 3:0] CM_RAM_N, // Memory Control for RAM
    input  wire        TEST      // Test Input
);

//------------------------
// Internal Signals
//------------------------
wire [7:0] ui_in;    // Dedicated inputs
wire [7:0] uo_out;   // Dedicated outputs
wire [7:0] uio_in;   // IOs: Input path
wire [7:0] uio_out;  // IOs: Output path
wire [7:0] uio_oe;   // IOs: Enable path (active high: 0=input, 1=output)
wire       ena;      // always 1 when the design is powered, so you can ignore it
wire       clk;      // clock
wire       rst_n;    // reset_n - low to reset

//----------------------
// Connections
//----------------------
assign clk   = CLK;
assign rst_n = RES_N;
assign ui_in[0] = TEST;
assign SYNC_N   = uo_out[0];
assign CM_ROM_N = uo_out[1];
assign CM_RAM_N = uo_out[7:4];
assign DATA[0]   = (uio_oe[0])? uio_out[0] : 1'bz;
assign DATA[1]   = (uio_oe[1])? uio_out[1] : 1'bz;
assign DATA[2]   = (uio_oe[2])? uio_out[2] : 1'bz;
assign DATA[3]   = (uio_oe[3])? uio_out[3] : 1'bz;
assign uio_in[0] = DATA[0];
assign uio_in[1] = DATA[1];
assign uio_in[2] = DATA[2];
assign uio_in[3] = DATA[3];
assign ena = 1'b1;

//-------------------------------
// MCS4_CPU as a Silicon Version
//-------------------------------
tt_um_munetomomaruyama_CPU U_CPU
(
    .ui_in,    // Dedicated inputs
    .uo_out,   // Dedicated outputs
    .uio_in,   // IOs: Input path
    .uio_out,  // IOs: Output path
    .uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    .ena,      // always 1 when the design is powered, so you can ignore it
    .clk,      // clock
    .rst_n     // reset_n - low to reset
);

endmodule
//===========================================================
// End of File
//===========================================================
