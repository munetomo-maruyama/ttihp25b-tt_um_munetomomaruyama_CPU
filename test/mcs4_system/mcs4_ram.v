//===========================================================
// MCS-4 Project
//-----------------------------------------------------------
// File Name   : mcs4_ram.v
// Description : MCS-4 RAM Chip (i4002 x 8banks x 4chips)
//-----------------------------------------------------------
// History :
// Rev.01 2025.05.19 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

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

//------------------------------------------------------------
// Notes on Chip Number if i4002
//------------------------------------------------------------
// As for real chip, the chip number is specified as follows.
//    Chip_#  4002_Option  P0_Input  {D3,D2}@X2
//         0    4002-1       GND       0  0
//         1    4002-1       VDD       0  1
//         2    4002-2       GND       1  0
//         3    4002-2       VDD       1  1
// In this module, full chips are included (8banks x 4chips),
// so there is no P0 input signal. 
//------------------------------------------------------------
module MCS4_RAM
(
    input  wire        CLK,     // Clock
    input  wire        RES_N,   // Reset
    //
    input  wire        SYNC_N,  // Sync Signal
    input  wire [ 3:0] DATA_I,  // Data Input
    output wire [ 3:0] DATA_O,  // Data Output
    output wire        DATA_OE, // Data Output Enable
    input  wire [ 7:0] CM_N,    // Memory Control
    //
    output wire [31:0] PORT_OUT_RAM_BANK1_BANK0, // RAM Port Out, Bank1 - Bank0, Chip3 - Chip0, each 4bits
    output wire [31:0] PORT_OUT_RAM_BANK3_BANK2, // RAM Port Out, Bank3 - Bank2, Chip3 - Chip0, each 4bits
    output wire [31:0] PORT_OUT_RAM_BANK5_BANK4, // RAM Port Out, Bank5 - Bank4, Chip3 - Chip0, each 4bits
    output wire [31:0] PORT_OUT_RAM_BANK7_BANK6  // RAM Port Out, Bank7 - Bank6, Chip3 - Chip0, each 4bits
);

//-----------------------------
// RAM MAT
//-----------------------------
reg  [3:0] ram_ch[0:2047]; // 8banks x 4chips x 64nibbles
reg  [3:0] ram_st[0: 511]; // 8banks x 4chips x 16nibbles

//---------------------------------
// Synchronization and State Count
//---------------------------------
reg [7:0] state;
//
always @(posedge CLK, negedge RES_N)
begin
    if (~RES_N)
        state <= 8'b00000000;
    else if (~SYNC_N)
        state <= 8'b00000001;    
    else if (SYNC_N & state[`X3]) // if no sync at X3,
        state <= 8'b00000000;     // it must be stop state
    else
        state <= {state[6:0], state[7]}; // rotate left
end

//------------------------
// SRC Address Latch
//------------------------
reg  [ 7:0] src;
reg         src_get;
//
always @(posedge CLK, negedge RES_N)
begin
    if (~RES_N)
    begin
        src     <= 8'h00;
        src_get <= 1'b0;
    end
    else if (state[`X2] & (~&CM_N)) // if at least one cm asserted
    begin
        src[7:4] <= DATA_I;
        src_get <= 1'b1;
    end
    else if (state[`X3] & src_get)
    begin
        src[3:0] <= DATA_I;
        src_get <= 1'b0;
    end
end

//----------------------------------------------
// Snatch OPA during CPU's Instruction Fetch
//----------------------------------------------
reg [4:0] opa; // MSB means I/O instruction is executing.
//
always @(posedge CLK, negedge RES_N)
begin
    if (~RES_N)
        opa <= 5'b00000;
    else if (state[`M2] & (~&CM_N))
        opa <= {1'b1, DATA_I};
    else if (state[`X3])
        opa <= 5'b00000;
end

//---------------------------
// Get Bank Number
//---------------------------
reg [ 2:0] bank;
//
always @(posedge CLK, negedge RES_N)
begin
    if (~RES_N) bank <= 3'b000;
    else if (~CM_N[0]) bank <= 3'b000;    
    else if (~CM_N[1]) bank <= 3'b001;    
    else if (~CM_N[2]) bank <= 3'b010;    
    else if (~CM_N[3]) bank <= 3'b011;    
    else if (~CM_N[4]) bank <= 3'b100;    
    else if (~CM_N[5]) bank <= 3'b101;    
    else if (~CM_N[6]) bank <= 3'b110;    
    else if (~CM_N[7]) bank <= 3'b111;    
end

//---------------------------
// Access RAM_CH
//---------------------------
wire [10:0] ram_ch_addr;
wire        ram_ch_re, ram_ch_we;
reg  [ 3:0] ram_ch_rdata;
wire [ 3:0] data_o_ram_ch;
wire        data_o_ram_ch_oe;
//
assign ram_ch_addr = {bank, src};
assign ram_ch_re = state[`X1] & (opa == 5'b11001)  // RDM
                 | state[`X1] & (opa == 5'b11000)  // SBM
                 | state[`X1] & (opa == 5'b11011); // ADM
assign ram_ch_we = state[`X2] & (opa == 5'b10000); // WRM
//
always @(posedge CLK)
begin
    ram_ch_rdata <= ram_ch[ram_ch_addr];
    if (ram_ch_we) ram_ch[ram_ch_addr] <= DATA_I;
end
//
assign data_o_ram_ch_oe = state[`X2] & (opa == 5'b11001)  // RDM
                        | state[`X2] & (opa == 5'b11000)  // SBM
                        | state[`X2] & (opa == 5'b11011); // ADM
assign data_o_ram_ch = (data_o_ram_ch_oe)? ram_ch_rdata : 4'b0000;

//---------------------------
// Access RAM_ST
//---------------------------
wire [ 8:0] ram_st_addr;
wire        ram_st_re, ram_st_we;
reg  [ 3:0] ram_st_rdata;
wire [ 3:0] data_o_ram_st;
wire        data_o_ram_st_oe;
//
assign ram_st_addr = {bank, src[7:4], opa[1:0]};
assign ram_st_re = state[`X1] & (opa[4:2] == 3'b111); // RD0-RD3
assign ram_st_we = state[`X2] & (opa[4:2] == 3'b101); // WR0-WR3
//
always @(posedge CLK)
begin
    ram_st_rdata <= ram_st[ram_st_addr];
    if (ram_st_we) ram_st[ram_st_addr] <= DATA_I;
end
//
assign data_o_ram_st_oe = state[`X2] & (opa[4:2] == 3'b111); // RD0-RD3
assign data_o_ram_st = (data_o_ram_st_oe)? ram_st_rdata : 4'b0000;

//--------------------
// Data Bus Output
//--------------------
assign DATA_O  = data_o_ram_ch    | data_o_ram_st;
assign DATA_OE = data_o_ram_ch_oe | data_o_ram_st_oe;

//-----------------
// Output Port
//-----------------
reg [3:0] port_out[0:7][0:3]; // 8banks x 4chips
//
generate 
    genvar b;
    for (b = 0; b < 8; b = b + 1)
    begin : PO_BANK
        genvar c;
        for (c = 0; c < 4; c = c + 1)
        begin : PO_CHIP
            always @(posedge CLK, negedge RES_N)
            begin
                if (~RES_N)
                    port_out[b][c] <= 4'b0000;
                else if (state[`X2] & (b == bank) & (c == src[7:6]) & (opa == 5'b10001)) // WMP
                    port_out[b][c] <= DATA_I;
            end
        end
    end
endgenerate
//
assign PORT_OUT_RAM_BANK7_BANK6 = {port_out[7][3], port_out[7][2], port_out[7][1], port_out[7][0],
                                   port_out[6][3], port_out[6][2], port_out[6][1], port_out[6][0]};
assign PORT_OUT_RAM_BANK5_BANK4 = {port_out[5][3], port_out[5][2], port_out[5][1], port_out[5][0],
                                   port_out[4][3], port_out[4][2], port_out[4][1], port_out[4][0]};
assign PORT_OUT_RAM_BANK3_BANK2 = {port_out[3][3], port_out[3][2], port_out[3][1], port_out[3][0],
                                   port_out[2][3], port_out[2][2], port_out[2][1], port_out[2][0]};
assign PORT_OUT_RAM_BANK1_BANK0 = {port_out[1][3], port_out[1][2], port_out[1][1], port_out[1][0],
                                   port_out[0][3], port_out[0][2], port_out[0][1], port_out[0][0]};

//===========================================================
endmodule
//===========================================================
