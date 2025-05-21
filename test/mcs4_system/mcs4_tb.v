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

`timescale 1ns/100ps
`define TB_CYCLE 1000 //ns (1MHz)
`define TB_FINISH_COUNT 2000000 //cyc

//---------------
// State Number
//---------------
`define A1 0
`define A2 1
`define A3 2
`define M1 3
`define M2 4
`define X1 5
`define X2 6
`define X3 7

//------------------
// Top of Test Bench
//------------------
module MCS4_TB();

integer i;

//-----------------------------
// Generate Wave File to Check
//-----------------------------
initial
begin
    $dumpfile("tb.vcd");
    $dumpvars(0, MCS4_TB);
end

//------------------
// Initialize ROM
//------------------
initial
begin
    $readmemh("4001.code", U_MCS4_MEM.U_MCS4_ROM.rom);
end

//-------------------------
// Initialize RAM (so far)
//-------------------------
initial
begin
    for (i = 0; i < 2048; i = i + 1) U_MCS4_MEM.U_MCS4_RAM.ram_ch[i] = 4'b0000;
    for (i = 0; i <  512; i = i + 1) U_MCS4_MEM.U_MCS4_RAM.ram_st[i] = 4'b0000;    
end

//-------------------------------
// Generate Clock
//-------------------------------
reg tb_clk;
//
initial tb_clk = 1'b0;
always #(`TB_CYCLE / 2) tb_clk = ~tb_clk;

//--------------------------
// Generate Reset
//--------------------------
reg tb_res;
//
initial
begin
    tb_res = 1'b1;
	# (`TB_CYCLE * 2)
    tb_res = 1'b0;	
end

//----------------------
// Cycle Counter
//----------------------
reg [31:0] tb_cycle_counter;
//
always @(posedge tb_clk, posedge tb_res)
begin
    if (tb_res)
        tb_cycle_counter <= 32'h0;
    else
        tb_cycle_counter <= tb_cycle_counter + 32'h1;
end
//
always @*
begin
    if (tb_cycle_counter == `TB_FINISH_COUNT)
    begin
        $display("***** SIMULATION TIMEOUT ***** at %d", tb_cycle_counter);
        $finish;
    end
end

//-----------------------
// Module Under Test
//-----------------------
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

//----------------------------
// Simulation Stop Condition
//----------------------------
wire [7:0] opropa0;
wire       multi_cycle;
wire       state_x3;
//
assign opropa0     = U_MCS4_CPU.U_CPU.opropa0;
assign multi_cycle = U_MCS4_CPU.U_CPU.multi_cycle;
assign state_x3    = U_MCS4_CPU.U_CPU.state[`X3];
//
always @*
begin
    if (state_x3 & ~multi_cycle & (opropa0 == 8'hff))
    begin
        $display("***** SIMULATION FINISHED ***** at %d", tb_cycle_counter);
        $stop;
    end
end

//------------------------
// Dump CPU Resource
//------------------------
integer handle_dump;
//
wire        state_a1;
wire [11:0] pc;
wire [ 3:0] acc;
wire        cy;
reg  [ 3:0] r[0:15];
wire [ 2:0] dcl;
wire [ 7:0] src;
//
initial handle_dump = $fopen("dump.sim");
//
assign state_a1 = U_MCS4_CPU.U_CPU.state[`A1];
assign pc       = U_MCS4_CPU.U_CPU.pc;
assign acc      = U_MCS4_CPU.U_CPU.acc;
assign cy       = U_MCS4_CPU.U_CPU.cy;
always @* for (i = 0; i < 16; i = i + 1) r[i] = U_MCS4_CPU.U_CPU.r[i];
assign dcl =  U_MCS4_CPU.U_CPU.dcl;
assign src =  U_MCS4_CPU.U_CPU.src;
//
always @(posedge tb_clk)
begin
    if (state_a1 & ~multi_cycle)
    begin
        $fwrite(handle_dump, "  PC=%03H ACC=%01X CY=%01X", pc, acc, cy);
        $fwrite(handle_dump, " R0-15=");
        for (i = 0; i < 16; i = i + 1) $fwrite(handle_dump, "%01X", r[i]);
        $fwrite(handle_dump, " DCL=%01X SRC=%02X\n", dcl, src);
    end
end

//--------------------------------
// Test Pattern (Stimulus)
//--------------------------------
reg [15:0] rdata;
//
initial
begin
    //
    // Verify What?
    enable_keyprt = 1'b0;
    enable_keyprt = 1'b1; // activate this line when you verify Key and Printer
    //
    // Initialize
    port_keyprt_cmd = 32'h00000000;
    //
    // Wait for Reset Done
    while(tb_res != 1'b0)
    begin
        #(`TB_CYCLE);
    end
    #(`TB_CYCLE);
    //
    // Key and Printer
    if (enable_keyprt)
    begin
            #(`TB_CYCLE * 50000);
        //
        port_keyprt_cmd = 32'h9b; // 1
            #(`TB_CYCLE * 50000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 50000);
        port_keyprt_cmd = 32'h97; // 2
            #(`TB_CYCLE * 50000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 50000);
        //
        port_keyprt_cmd = 32'h8e; // +
            #(`TB_CYCLE * 50000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 50000);
        //
        port_keyprt_cmd = 32'h93; // 3
            #(`TB_CYCLE * 50000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 50000);
        port_keyprt_cmd = 32'h9a; // 4
            #(`TB_CYCLE * 50000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 50000);
        //
        port_keyprt_cmd = 32'h8e; // +
      //port_keyprt_cmd = 32'h8d; // -
            #(`TB_CYCLE * 50000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 50000);
        //
        port_keyprt_cmd = 32'h8c; // = 
            #(`TB_CYCLE * 50000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 50000);
        //
        port_keyprt_cmd = 32'h8000; // FIFO POP 
            #(`TB_CYCLE * 10000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 10000);
        //
        port_keyprt_cmd = 32'h8000; // FIFO POP 
            #(`TB_CYCLE * 10000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 10000);
        //
        port_keyprt_cmd = 32'h8000; // FIFO POP 
            #(`TB_CYCLE * 10000);
        port_keyprt_cmd = 32'h00; // OFF
            #(`TB_CYCLE * 10000);
        //
        // Finish
        $display("***** STIMULAS FINISHED ***** at %d", tb_cycle_counter);
    end
end

//===========================================================
endmodule
//===========================================================
