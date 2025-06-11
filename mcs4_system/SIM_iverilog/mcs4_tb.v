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
// Signals in TestBench
//-----------------------
wire        sync_n;
wire [ 3:0] data;
wire        cm_rom_n;
wire [ 3:0] cm_ram_n;
wire        test;
//
reg  [31:0] port_keyprt_cmd;
wire [31:0] port_keyprt_res;

//---------------------------------
// MCS-4 CPU Chip i4004
//---------------------------------
MCS4_CPU_CHIP U_MCS4_CPU_CHIP
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

//----------------------------
// Simulation Stop Condition
//----------------------------
wire [7:0] opropa0;
wire       multi_cycle;
wire       state_x3;
//
assign opropa0     = U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.opropa0;
assign multi_cycle = U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.multi_cycle;
assign state_x3    = U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.state[`X3];
//
always @*
begin
    if (state_x3 & ~multi_cycle & (opropa0 == 8'hff))
    begin
        $display("***** SIMULATION FINISHED ***** at %d", tb_cycle_counter);
        $finish;
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
assign state_a1 = U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.state[`A1];
assign pc       = U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.pc;
assign acc      = U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.acc;
assign cy       = U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.cy;
always @* for (i = 0; i < 16; i = i + 1) r[i] = U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.r[i];
assign dcl =  U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.dcl;
assign src =  U_MCS4_CPU_CHIP.U_MCS4_CPU_CORE.src;
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
        #(`TB_CYCLE * 50000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h8000009b; // 1
        #(`TB_CYCLE * 50000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 50000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h80000097; // 2
        #(`TB_CYCLE * 50000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 50000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h8000008e; // +
        #(`TB_CYCLE * 50000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 50000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h80000093; // 3
        #(`TB_CYCLE * 50000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 50000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h8000009a; // 4
        #(`TB_CYCLE * 50000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 50000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h8000008e; // +
  //port_keyprt_cmd = 32'h8000008d; // -
        #(`TB_CYCLE * 50000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 50000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h8000008c; // = 
        #(`TB_CYCLE * 50000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 50000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h80008000; // FIFO POP 
        #(`TB_CYCLE * 4);
    if (port_keyprt_res != 32'h80002c01) // col=...0000, row=11
    begin
        // Error
        $display("##### Unexpected port_keyprt_res ##### at %d", tb_cycle_counter);
        #(`TB_CYCLE * 10);
        $finish;
    end
        #(`TB_CYCLE * 10000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 10000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h80008000; // FIFO POP 
        #(`TB_CYCLE * 4);
    if (port_keyprt_res != 32'h80003001) // col=...0000, row=12
    begin
        // Error
        $display("##### Unexpected port_keyprt_res ##### at %d", tb_cycle_counter);
        #(`TB_CYCLE * 10);
        $finish;
    end
        #(`TB_CYCLE * 10000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 10000);
    //----------------------------------------------------------------
        port_keyprt_cmd = 32'h80008000; // FIFO POP 
        #(`TB_CYCLE * 4);
    if (port_keyprt_res != 32'h80000001) // col=...0000, row=0
    begin
        // Error
        $display("##### Unexpected port_keyprt_res ##### at %d", tb_cycle_counter);
        #(`TB_CYCLE * 10);
        $finish;
    end
        #(`TB_CYCLE * 10000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 10000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h80008000; // FIFO POP 
        #(`TB_CYCLE * 4);
    if (port_keyprt_res != 32'h80028401) // col=...1010, row=1 (...1__+)
    begin
        // Error
        $display("##### Unexpected port_keyprt_res ##### at %d", tb_cycle_counter);
        #(`TB_CYCLE * 10);
        $finish;
    end
        #(`TB_CYCLE * 10000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 10000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h80008000; // FIFO POP 
        #(`TB_CYCLE * 4);
    if (port_keyprt_res != 32'h80010801) // col=...0100, row=2 (..._2__)
    begin
        // Error
        $display("##### Unexpected port_keyprt_res ##### at %d", tb_cycle_counter);
        #(`TB_CYCLE * 10);
        $finish;
    end
        #(`TB_CYCLE * 10000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 10000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h80008000; // FIFO POP 
        #(`TB_CYCLE * 4);
    if (port_keyprt_res != 32'h80000c01) // col=...0000, row=3
    begin
        // Error
        $display("##### Unexpected port_keyprt_res ##### at %d", tb_cycle_counter);
        #(`TB_CYCLE * 10);
        $finish;
    end
        #(`TB_CYCLE * 10000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 10000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h80008000; // FIFO POP 
        #(`TB_CYCLE * 4);
    if (port_keyprt_res != 32'h80001001) // col=...0000, row=4
    begin
        // Error
        $display("##### Unexpected port_keyprt_res ##### at %d", tb_cycle_counter);
        #(`TB_CYCLE * 10);
        $finish;
    end
        #(`TB_CYCLE * 10000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 10000);
    //----------------------------------------------------------------
    port_keyprt_cmd = 32'h80008000; // FIFO POP 
        #(`TB_CYCLE * 4);
    if (port_keyprt_res != 32'h80001401) // col=...000, row=5
    begin
        // Error
        $display("##### Unexpected port_keyprt_res ##### at %d", tb_cycle_counter);
        #(`TB_CYCLE * 10);
        $finish;
    end
        #(`TB_CYCLE * 10000);
    port_keyprt_cmd = 32'h80000000; // OFF
        #(`TB_CYCLE * 10000);
    //----------------------------------------------------------------
    //
    // Finish
        #(`TB_CYCLE * 1000000);
    $display("***** STIMULAS FINISHED ***** at %d", tb_cycle_counter);
    $finish;
end

endmodule
//===========================================================
// End of File
//===========================================================
