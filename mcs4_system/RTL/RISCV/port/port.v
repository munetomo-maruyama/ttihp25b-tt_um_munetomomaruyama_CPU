//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : port.v
// Description : In/Out Port (GPIO)
//-----------------------------------------------------------
// S_History :
// Rev.01 2021.02.22 M.Maruyama First Release
// Rev.02 2025.05.27 M.Maruyama Add GPIO3 amd GPIO4
//-----------------------------------------------------------
// Copyright (C) 2017-2025 M.Maruyama
//===========================================================

//======================================================
// GPIO Register
//------------------------------------------------------
// Offset Name Description
// 0x00   PDR0 Port Data Register 0
// 0x04   PDR1 Port Data Register 1
// 0x08   PDR2 Port Data Register 2
// 0x0c   PDR3 Port Data Register 3
// 0x10   PDR4 Port Data Register 4
//                 Each bit corresponds to each pin
//                 Input  Port : Read  Pin Level
//                               Write PDR F/F
//                 Output Port : Read  PDR F/F
//                               Write PDR F/F
// 0x20   PDD0 Port Data Direction 0
// 0x24   PDD1 Port Data Direction 1
// 0x28   PDD2 Port Data Direction 2
// 0x2c   PDD3 Port Data Direction 2
// 0x30   PDD4 Port Data Direction 2
//                 0 : Input 
//                 1 : Output
//======================================================

//*************************************************
// Module Definition
//*************************************************
module PORT
(
    // System
    input  wire CLK, // clock
    input  wire RES, // reset
    //
    // AHB Lite Slave port
    input  wire        S_HSEL,
    input  wire [ 1:0] S_HTRANS,
    input  wire        S_HWRITE,
    input  wire        S_HMASTLOCK,
    input  wire [ 2:0] S_HSIZE,
    input  wire [ 2:0] S_HBURST,
    input  wire [ 3:0] S_HPROT,
    input  wire [31:0] S_HADDR,
    input  wire [31:0] S_HWDATA,
    input  wire        S_HREADY,
    output wire        S_HREADYOUT,
    output reg  [31:0] S_HRDATA,
    output wire        S_HRESP,
    //
    // GPIO
    input  wire [31:0] GPIO0_I,  // GPIO0 Input
    output wire [31:0] GPIO0_O,  // GPIO0 Output
    output wire [31:0] GPIO0_OE, // GPIO0 Output Enable
    input  wire [31:0] GPIO1_I,  // GPIO1 Input
    output wire [31:0] GPIO1_O,  // GPIO1 Output
    output wire [31:0] GPIO1_OE, // GPIO1 Output Enable
    input  wire [31:0] GPIO2_I,  // GPIO2 Input
    output wire [31:0] GPIO2_O,  // GPIO2 Output
    output wire [31:0] GPIO2_OE, // GPIO2 Output Enable
    input  wire [31:0] GPIO3_I,  // GPIO3 Input
    output wire [31:0] GPIO3_O,  // GPIO3 Output
    output wire [31:0] GPIO3_OE, // GPIO3 Output Enable
    input  wire [31:0] GPIO4_I,  // GPIO4 Input
    output wire [31:0] GPIO4_O,  // GPIO4 Output
    output wire [31:0] GPIO4_OE  // GPIO4 Output Enable
);

//---------------------
// Internal Signals
//---------------------
reg  [31:0] pdr0; // Port Data Register 0
reg  [31:0] pdr1; // Port Data Register 1
reg  [31:0] pdr2; // Port Data Register 2
reg  [31:0] pdr3; // Port Data Register 3
reg  [31:0] pdr4; // Port Data Register 4
reg  [31:0] pdd0; // Port Data Direction 0
reg  [31:0] pdd1; // Port Data Direction 1
reg  [31:0] pdd2; // Port Data Direction 2
reg  [31:0] pdd3; // Port Data Direction 3
reg  [31:0] pdd4; // Port Data Direction 4
//
reg         dphase_active;
reg  [31:0] dphase_addr;
reg         dphase_write;
//
reg  [31:0] gpio0_rd;
reg  [31:0] gpio1_rd;
reg  [31:0] gpio2_rd;
reg  [31:0] gpio3_rd;
reg  [31:0] gpio4_rd;

//-------------------
// Register Access
//-------------------
assign S_HREADYOUT = 1'b1;
assign S_HRESP = 1'b0;
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        dphase_active <= 1'b0;
        dphase_addr   <= 32'h00000000;
        dphase_write  <= 1'b0;
    end
    else if (S_HREADY & S_HSEL & S_HTRANS[1])
    begin
        dphase_active <= 1'b1;
        dphase_addr   <= S_HADDR;
        dphase_write  <= S_HWRITE;
    end
    else if (S_HREADY)
    begin
        dphase_active <= 1'b0;
        dphase_addr   <= 32'h00000000;
        dphase_write  <= 1'b0;
    end
end
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        pdr0 <= 32'h00000000;
        pdr1 <= 32'h00000000;
        pdr2 <= 32'h00000000;
        pdr3 <= 32'h00000000;
        pdr4 <= 32'h00000000;
    end
    else if (dphase_active & dphase_write)   
    begin
        if (dphase_addr[5:2] == 4'b0000) pdr0 <= S_HWDATA;
        if (dphase_addr[5:2] == 4'b0001) pdr1 <= S_HWDATA;
        if (dphase_addr[5:2] == 4'b0010) pdr2 <= S_HWDATA;
        if (dphase_addr[5:2] == 4'b0011) pdr3 <= S_HWDATA;
        if (dphase_addr[5:2] == 4'b0100) pdr4 <= S_HWDATA;
    end
end
//
always @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        pdd0 <= 32'h00000000;
        pdd1 <= 32'h00000000;
        pdd2 <= 32'h00000000;
        pdd3 <= 32'h00000000;
        pdd4 <= 32'h00000000;
    end
    else if (dphase_active & dphase_write)
    begin
        if (dphase_addr[5:2] == 4'b1000) pdd0 <= S_HWDATA;
        if (dphase_addr[5:2] == 4'b1001) pdd1 <= S_HWDATA;
        if (dphase_addr[5:2] == 4'b1010) pdd2 <= S_HWDATA;
        if (dphase_addr[5:2] == 4'b1011) pdd3 <= S_HWDATA;
        if (dphase_addr[5:2] == 4'b1100) pdd4 <= S_HWDATA;
    end
end
//
always @*
begin
    if (dphase_active & ~dphase_write)
    begin
             if (dphase_addr[5:2] == 4'b0000) S_HRDATA = gpio0_rd;
        else if (dphase_addr[5:2] == 4'b0001) S_HRDATA = gpio1_rd;
        else if (dphase_addr[5:2] == 4'b0010) S_HRDATA = gpio2_rd;
        else if (dphase_addr[5:2] == 4'b0011) S_HRDATA = gpio3_rd;
        else if (dphase_addr[5:2] == 4'b0100) S_HRDATA = gpio4_rd;
        else if (dphase_addr[5:2] == 4'b1000) S_HRDATA = pdd0;
        else if (dphase_addr[5:2] == 4'b1001) S_HRDATA = pdd1;
        else if (dphase_addr[5:2] == 4'b1010) S_HRDATA = pdd2;
        else if (dphase_addr[5:2] == 4'b1011) S_HRDATA = pdd3;
        else if (dphase_addr[5:2] == 4'b1100) S_HRDATA = pdd4;
        else S_HRDATA = 32'h00000000;
    end
    else
    begin
        S_HRDATA = 32'h00000000;
    end
end

//----------------------
// Port Input/Output
//----------------------
integer i;
genvar  j;
//
always @*
begin
    for (i = 0; i < 32; i = i + 1)
    begin
        gpio0_rd[i] = (pdd0[i])? pdr0[i] : GPIO0_I[i];
        gpio1_rd[i] = (pdd1[i])? pdr1[i] : GPIO1_I[i];
        gpio2_rd[i] = (pdd2[i])? pdr2[i] : GPIO2_I[i];
        gpio3_rd[i] = (pdd3[i])? pdr3[i] : GPIO3_I[i];
        gpio4_rd[i] = (pdd4[i])? pdr4[i] : GPIO4_I[i];
    end
end
//
assign GPIO0_O = pdr0;
assign GPIO1_O = pdr1;
assign GPIO2_O = pdr2;
assign GPIO3_O = pdr3;
assign GPIO4_O = pdr4;
//
assign GPIO0_OE = pdd0;
assign GPIO1_OE = pdd1;
assign GPIO2_OE = pdd2;
assign GPIO3_OE = pdd3;
assign GPIO4_OE = pdd4;

//======================================================
  endmodule
//======================================================
