//===========================================================
// MCS-4 Project
//-----------------------------------------------------------
// File Name   : fpga_top.v
// Description : MCS-4 System implemented in a FPGA
//-----------------------------------------------------------
// History :
// Rev.01 2025.05.25 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

// < FPGA Board Terasic DE10-Lite>
//
// RES_N     B8  KEY0
// CLK50     P11
//
// RESOUT_N  F16 RESET Output (negative)
//
// TRSTn     Y5  GPIO_29
// TCK       Y6  GPIO_27
// TMS       AA2 GPIO_35
// TDI       Y4  GPIO_31
// TDO       Y3  GPIO_33
//
// TXD       AB2 GPIO_34 (!)
// RXD       AB3 GPIO_32 (!)
//
// I2C0_SCL  AB15  GSENSOR SCL
// I2C0_SDA  V11   GSENSOR SDA
// I2C0_ENA  AB16  GSENSOR CSn (Fixed to 1)
// I2C0_ADR  V12   GSENSOR ALTADDR (Fixed to 0)
// I2C0_INT1 Y14   GSENSOR INT1
// I2C0_INT2 Y13   GSENSOR INT2
//
// I2C1_SCL   AA20  Arduino IO15 CT_SCL (Capacitive Touch Controller)
// I2C1_SDA   AB21  Arduino IO14 CT_SDA (Capacitive Touch Controller)
// 
// SPI_CSN[3] AB9   Arduino IO04 CARD_CS (SD Card)
// SPI_CSN[2] AB17  Arduino IO08 RT_CS   (Resistive Touch Controller)
// SPI_CSN[1] AA17  Arduino IO09 TFT_DC  (LCD Controller)
// SPI_CSN[0] AB19  Arduino IO10 TFT_CS  (LCD Controller)
// SPI_MOSI   AA19  Arduino IO11
// SPI_MISO   Y19   Arduino IO12
// SPI_SCK    AB20  Arduino IO13
//
// SDRAM_CLK      L14
// SDRAM_CKE      N22
// SDRAM_CSn      U20
// SDRAM_DQM [ 0] V22
// SDRAM_DQM [ 1] J21
// SDRAM_RASn     U22
// SDRAM_CASn     U21
// SDRAM_WEn      V20
// SDRAM_BA  [ 0] T21
// SDRAM_BA  [ 1] T22
// SDRAM_ADDR[ 0] U17
// SDRAM_ADDR[ 1] W19 
// SDRAM_ADDR[ 2] V18
// SDRAM_ADDR[ 3] U18
// SDRAM_ADDR[ 4] U19
// SDRAM_ADDR[ 5] T18
// SDRAM_ADDR[ 6] T19
// SDRAM_ADDR[ 7] R18
// SDRAM_ADDR[ 8] P18
// SDRAM_ADDR[ 9] P19
// SDRAM_ADDR[10] T20
// SDRAM_ADDR[11] P20
// SDRAM_ADDR[12] R20
// SDRAM_DQ  [ 0] Y21
// SDRAM_DQ  [ 1] Y20
// SDRAM_DQ  [ 2] AA22
// SDRAM_DQ  [ 3] AA21
// SDRAM_DQ  [ 4] Y22
// SDRAM_DQ  [ 5] W22
// SDRAM_DQ  [ 6] W20
// SDRAM_DQ  [ 7] V21
// SDRAM_DQ  [ 8] P21
// SDRAM_DQ  [ 9] J22
// SDRAM_DQ  [10] H21
// SDRAM_DQ  [11] H22
// SDRAM_DQ  [12] G22
// SDRAM_DQ  [13] G20
// SDRAM_DQ  [14] G19
// SDRAM_DQ  [15] F22
//
// GPIO0[ 0] C14 HEX00 segA
// GPIO0[ 1] E15 HEX01 segB
// GPIO0[ 2] C15 HEX02 segC
// GPIO0[ 3] C16 HEX03 segD
// GPIO0[ 4] E16 HEX04 segE
// GPIO0[ 5] D17 HEX05 segF
// GPIO0[ 6] C17 HEX06 segG
// GPIO0[ 7] D15 HEX07 segDP
// GPIO0[ 8] C18 HEX10 segA
// GPIO0[ 9] D18 HEX11 segB
// GPIO0[10] E18 HEX12 segC
// GPIO0[11] B16 HEX13 segD
// GPIO0[12] A17 HEX14 segE
// GPIO0[13] A18 HEX15 segF
// GPIO0[14] B17 HEX16 segG
// GPIO0[15] A16 HEX17 segDP
// GPIO0[16] B20 HEX20 segA
// GPIO0[17] A20 HEX21 segB
// GPIO0[18] B19 HEX22 segC
// GPIO0[19] A21 HEX23 segD
// GPIO0[20] B21 HEX24 segE
// GPIO0[21] C22 HEX25 segF
// GPIO0[22] B22 HEX26 segG
// GPIO0[23] A19 HEX27 segDP
// GPIO0[24] F21 HEX30 segA
// GPIO0[25] E22 HEX31 segB
// GPIO0[26] E21 HEX32 segC
// GPIO0[27] C19 HEX33 segD
// GPIO0[28] C20 HEX34 segE
// GPIO0[29] D19 HEX35 segF
// GPIO0[30] E17 HEX36 segG
// GPIO0[31] D22 HEX37 segDP
//
// GPIO1[ 0] F18 HEX40 segA
// GPIO1[ 1] E20 HEX41 segB
// GPIO1[ 2] E19 HEX42 segC
// GPIO1[ 3] J18 HEX43 segD
// GPIO1[ 4] H19 HEX44 segE
// GPIO1[ 5] F19 HEX45 segF
// GPIO1[ 6] F20 HEX46 segG
// GPIO1[ 7] F17 HEX47 segDP
// GPIO1[ 8] J20 HEX50 segA
// GPIO1[ 9] K20 HEX51 segB
// GPIO1[10] L18 HEX52 segC
// GPIO1[11] N18 HEX53 segD
// GPIO1[12] M20 HEX54 segE
// GPIO1[13] N19 HEX55 segF
// GPIO1[14] N20 HEX56 segG
// GPIO1[15] L19 HEX57 segDP
// GPIO1[16] A8  LEDR0
// GPIO1[17] A9  LEDR1
// GPIO1[18] A10 LEDR2
// GPIO1[19] B10 LEDR3
// GPIO1[20] D13 LEDR4
// GPIO1[21] C13 LEDR5
// GPIO1[22] E14 LEDR6
// GPIO1[23] D14 LEDR7
// GPIO1[24] A11 LEDR8
// GPIO1[25] B11 LEDR9
// GPIO1[26] AA5  TT_SEL_INC
// GPIO1[27] AA6  TT_SEL_RST_N
// GPIO1[28] AA7  TT_ENA
//
// GPIO2[ 0] C10  SW0
// GPIO2[ 1] C11  SW1
// GPIO2[ 2] D12  SW2
// GPIO2[ 3] C12  SW3
// GPIO2[ 4] A12  SW4
// GPIO2[ 5] B12  SW5
// GPIO2[ 6] A13  SW6
// GPIO2[ 7] A14  SW7
// GPIO2[ 8] B14  SW8
// GPIO2[ 9] F15  SW9
// GPIO2[10] A7   KEY1
//
// GPIO3[ 0] port_keyprt_cmd[ 0]
// GPIO3[ 1] port_keyprt_cmd[ 1]
// GPIO3[ 2] port_keyprt_cmd[ 2]
// GPIO3[ 3] port_keyprt_cmd[ 3]
// GPIO3[ 4] port_keyprt_cmd[ 4]
// GPIO3[ 5] port_keyprt_cmd[ 5]
// GPIO3[ 6] port_keyprt_cmd[ 6]
// GPIO3[ 7] port_keyprt_cmd[ 7]
// GPIO3[ 8] port_keyprt_cmd[ 8]
// GPIO3[ 9] port_keyprt_cmd[ 9]
// GPIO3[10] port_keyprt_cmd[10]
// GPIO3[11] port_keyprt_cmd[11]
// GPIO3[12] port_keyprt_cmd[12]
// GPIO3[13] port_keyprt_cmd[13]
// GPIO3[14] port_keyprt_cmd[14]
// GPIO3[15] port_keyprt_cmd[15]
// GPIO3[16] port_keyprt_cmd[16]
// GPIO3[17] port_keyprt_cmd[17]
// GPIO3[18] port_keyprt_cmd[18]
// GPIO3[19] port_keyprt_cmd[19]
// GPIO3[20] port_keyprt_cmd[20]
// GPIO3[21] port_keyprt_cmd[21]
// GPIO3[22] port_keyprt_cmd[22]
// GPIO3[23] port_keyprt_cmd[23]
// GPIO3[24] port_keyprt_cmd[24]
// GPIO3[25] port_keyprt_cmd[25]
// GPIO3[26] port_keyprt_cmd[26]
// GPIO3[27] port_keyprt_cmd[27]
// GPIO3[28] port_keyprt_cmd[28]
// GPIO3[29] port_keyprt_cmd[29]
// GPIO3[30] port_keyprt_cmd[30]
// GPIO3[31] port_keyprt_cmd[31]
//
// GPIO4[ 0] port_keyprt_res[ 0]
// GPIO4[ 1] port_keyprt_res[ 1]
// GPIO4[ 2] port_keyprt_res[ 2]
// GPIO4[ 3] port_keyprt_res[ 3]
// GPIO4[ 4] port_keyprt_res[ 4]
// GPIO4[ 5] port_keyprt_res[ 5]
// GPIO4[ 6] port_keyprt_res[ 6]
// GPIO4[ 7] port_keyprt_res[ 7]
// GPIO4[ 8] port_keyprt_res[ 8]
// GPIO4[ 9] port_keyprt_res[ 9]
// GPIO4[10] port_keyprt_res[10]
// GPIO4[11] port_keyprt_res[11]
// GPIO4[12] port_keyprt_res[12]
// GPIO4[13] port_keyprt_res[13]
// GPIO4[14] port_keyprt_res[14]
// GPIO4[15] port_keyprt_res[15]
// GPIO4[16] port_keyprt_res[16]
// GPIO4[17] port_keyprt_res[17]
// GPIO4[18] port_keyprt_res[18]
// GPIO4[19] port_keyprt_res[19]
// GPIO4[20] port_keyprt_res[20]
// GPIO4[21] port_keyprt_res[21]
// GPIO4[22] port_keyprt_res[22]
// GPIO4[23] port_keyprt_res[23]
// GPIO4[24] port_keyprt_res[24]
// GPIO4[25] port_keyprt_res[25]
// GPIO4[26] port_keyprt_res[26]
// GPIO4[27] port_keyprt_res[27]
// GPIO4[28] port_keyprt_res[28]
// GPIO4[29] port_keyprt_res[29]
// GPIO4[30] port_keyprt_res[30]
// GPIO4[31] port_keyprt_res[31]

//--------------------------------------------------------------------
// DE10-LITE External Connection
//--------------------------------------------------------------------
//              MCS4_SYS Side      |     MCS4_CPU Side (Si or FPGA)
//--------------------------------------------------------------------
// S_CLK         (V10 ) GPIO_0   01|02  GPIO_1  (W10 ) C_CLK
// S_RES_N       (V9  ) GPIO_2   03|04  GPIO_3  (W9  ) C_RES_N
// S_SYNC_N      (V8  ) GPIO_4   05|06  GPIO_5  (W8  ) C_SYNC_N
// S_TEST        (V7  ) GPIO_6   07|08  GPIO_7  (W7  ) C_TEST
// S_CM_ROM_N    (W6  ) GPIO_8   09|10  GPIO_9  (V5  ) C_CM_ROM_N
//                           5V  11|12  GND
// S_CM_RAM_N[0] (W5  ) GPIO_10  13|14  GPIO_11 (AA15) C_CM_RAM_N[0]
// S_CM_RAM_N[1] (AA14) GPIO_12  15|16  GPIO_13 (W13 ) C_CM_RAM_N[1]
// S_CM_RAM_N[2] (W12 ) GPIO_14  17|18  GPIO_15 (AB13) C_CM_RAM_N[2]
// S_CM_RAM_N[3] (AB12) GPIO_16  19|20  GPIO_17 (Y11 ) C_CM_RAM_N[3]
// S_DATA[0]     (AB11) GPIO_18  21|22  GPIO_19 (W11 ) C_DATA[0]
// S_DATA[1]     (AB10) GPIO_20  23|24  GPIO_21 (AA10) C_DATA[1]
// S_DATA[2]     (AA9 ) GPIO_22  25|26  GPIO_23 (Y8  ) C_DATA[2]
// S_DATA[3]     (AA8 ) GPIO_24  27|28  GPIO_25 (Y7  ) C_DATA[3]
//                         3.3V  29|30  GND
// TT_ENA        (AA7 ) GPIO_26  31|32  GPIO_27 (Y6  ) TCK
// TT_SEL_RST_N  (AA6 ) GPIO_28  33|34  GPIO_29 (Y5  ) TRST_n
// TT_SEL_INC    (AA5 ) GPIO_30  35|36  GPIO_31 (Y4  ) TDI
// RXD           (AB3 ) GPIO_32  37|38  GPIO_33 (Y3  ) TDO
// TXD           (AB2 ) GPIO_34  39|40  GPIO_35 (AA2 ) TMS

`include "defines_chip.v"
`include "defines_core.v"

//---------------------------------
// FPGA TOP
//---------------------------------
module FPGA_TOP
(
    input  wire RES_N, // Reset Input (Negative)
    input  wire CLK50, // Clock Input (50MHz)
    //
    output wire RESOUT_N, // Reset Output (negative) 
    //
    input  wire TRSTn, // JTAG TAP Reset
    input  wire TCK,   // JTAG Clock
    input  wire TMS,   // JTAG Mode Select
    input  wire TDI,   // JTAG Data Input
    output wire TDO,   // JTAG Data Output (3-state)
    //
    inout  wire [31: 0] GPIO0,   // GPIO0 Port (should be pulled-up)
    inout  wire [28: 0] GPIO1,   // GPIO1 Port (should be pulled-up)
    inout  wire [10: 0] GPIO2,   // GPIO2 Port (should be pulled-up)
    //
    input  wire RXD, // UART receive data
    output wire TXD, // UART transmit data
    //
    inout  wire I2C0_SCL,  // I2C0 SCL
    inout  wire I2C0_SDA,  // I2C0 SDA
    output wire I2C0_ENA,  // I2C0 Enable (Fixed to 1)
    output wire I2C0_ADR,  // I2C0 ALTADDR (Fixed to 0)
    input  wire I2C0_INT1, // I2C0 Device Interrupt Request 1
    input  wire I2C0_INT2, // I2C0 Device Interrupt Request 2
    //
    inout  wire I2C1_SCL,  // I2C1 SCL
    inout  wire I2C1_SDA,  // I2C1 SDA
    //
    output wire [ 3:0] SPI_CSN,  // SPI Chip Select
    output wire        SPI_SCK,  // SPI Clock
    output wire        SPI_MOSI, // SPI MOSI
    input  wire        SPI_MISO, // SPI MISO
    //
    output wire        SDRAM_CLK,  // SDRAM Clock
    output wire        SDRAM_CKE,  // SDRAM Clock Enable
    output wire        SDRAM_CSn,  // SDRAM Chip Select
    output wire [ 1:0] SDRAM_DQM,  // SDRAM Byte Data Mask
    output wire        SDRAM_RASn, // SDRAM Row Address Strobe
    output wire        SDRAM_CASn, // SDRAM Column Address Strobe
    output wire        SDRAM_WEn,  // SDRAM Write Enable
    output wire [ 1:0] SDRAM_BA,   // SDRAM Bank Address
    output wire [12:0] SDRAM_ADDR, // SDRAM Addess
    inout  wire [15:0] SDRAM_DQ,   // SDRAM Data
    //
    output wire        S_MCS4_CLK,      // MCS4_SYS Clock Output
    output wire        S_MCS4_RES_N,    // MCS4_SYS Reset Output
    input  wire        S_MCS4_SYNC_N,   // MCS4_SYS SYNC_N Input
    output wire        S_MCS4_TEST,     // MCS4_STS TEST Output
    input  wire        S_MCS4_CM_ROM_N, // MCS4_SYS CM_ROM_N Input
    input  wire [ 3:0] S_MCS4_CM_RAM_N, // MCS4_SYS CM_RAM_N Input
    inout  wire [ 3:0] S_MCS4_DATA,     // MCS4_SYS DATA Inout
    //
    input  wire        C_MCS4_CLK,      // MCS4_CPU Clock Input
    input  wire        C_MCS4_RES_N,    // MCS4_CPU Reset Input
    output wire        C_MCS4_SYNC_N,   // MCS4_CPU SYNC_N Output
    input  wire        C_MCS4_TEST,     // MCS4_CPU TEST Input
    output wire        C_MCS4_CM_ROM_N, // MCS4_CPU CM_ROM_N Output
    output wire [ 3:0] C_MCS4_CM_RAM_N, // MCS4_CPU CM_RAM_N Output
    inout  wire [ 3:0] C_MCS4_DATA      // MCS4_CPU DATA Inout
);

//---------------------------------
// MCS-4 CPU Chip i4004
//---------------------------------
MCS4_CPU_CHIP U_MCS4_CPU_CHIP
(
    .CLK   (C_MCS4_CLK),   // clock
    .RES_N (C_MCS4_RES_N), // reset_n
    //
    .SYNC_N   (C_MCS4_SYNC_N),   // Sync Signal
    .DATA     (C_MCS4_DATA),     // Data Input/Output
    .CM_ROM_N (C_MCS4_CM_ROM_N), // Memory Control for ROM
    .CM_RAM_N (C_MCS4_CM_RAM_N), // Memory Control for RAM
    .TEST     (C_MCS4_TEST)      // Test Input
);

//---------------------------------------------
// MCS-4 System ROM + RAM + Key&Printer I/F
//---------------------------------------------
wire [31:0] port_keyprt_cmd;
wire [31:0] port_keyprt_res;
//
MCS4_SYS U_MCS4_SYS
(
    // CPU Interfface (i4004)
    .CLK   (S_MCS4_CLK),   // clock
    .RES_N (S_MCS4_RES_N), // reset_n
    //
    .SYNC_N   (S_MCS4_SYNC_N),   // Sync Signal
    .DATA     (S_MCS4_DATA),     // Data Input/Output
    .CM_ROM_N (S_MCS4_CM_ROM_N), // Memory Control for ROM
    .CM_RAM_N (C_MCS4_CM_RAM_N), // Memory Control for RAM
    .TEST     (S_MCS4_TEST),     // Test Input
    //
    // Calculator Command : Host MCU (UI) --> MCS4_SYS
    .PORT_KEYPRT_CMD (port_keyprt_cmd),
    //
    // Calculator Response : MCS4_SYS --> Host MCU (UI)
    .PORT_KEYPRT_RES (port_keyprt_res)
);

//----------------------
// RISC-V Reset Halt
//----------------------
wire reset_halt_n;
assign reset_halt_n = GPIO1[26]; // KEY1

//-------------------------
// JTAG TDO Output Buffer
//-------------------------
wire tdo_d;
wire tdo_e;
assign TDO = (tdo_e)? tdo_d : 1'bz;

//----------------------
// I2C I/O Buffers
//----------------------
wire i2c0_scl_i;   //I2C0 SCL Input
wire i2c0_scl_o;   //I2C0 SCL Output
wire i2c0_scl_oen; //I2C0 SCL Output Enable
wire i2c0_sda_i;   //I2C0 SDA Input
wire i2c0_sda_o;   //I2C0 SDA Output
wire i2c0_sda_oen; //I2C0 SDA Output Enable
//
wire i2c1_scl_i;   //I2C1 SCL Input
wire i2c1_scl_o;   //I2C1 SCL Output
wire i2c1_scl_oen; //I2C1 SCL Output Enable
wire i2c1_sda_i;   //I2C1 SDA Input
wire i2c1_sda_o;   //I2C1 SDA Output
wire i2c1_sda_oen; //I2C1 SDA Output Enable
//
assign i2c0_scl_i = I2C0_SCL;
assign I2C0_SCL   = (i2c0_scl_oen)? 1'bz : i2c0_scl_o;
assign i2c0_sda_i = I2C0_SDA;
assign I2C0_SDA   = (i2c0_sda_oen)? 1'bz : i2c0_sda_o;
assign i2c1_scl_i = I2C1_SCL;
assign I2C1_SCL   = (i2c1_scl_oen)? 1'bz : i2c1_scl_o;
assign i2c1_sda_i = I2C1_SDA;
assign I2C1_SDA   = (i2c1_sda_oen)? 1'bz : i2c1_sda_o;

//----------------------
// GPIO I/O Buffers
//----------------------
wire [31:0] gpio0_i;
wire [31:0] gpio0_o;
wire [31:0] gpio0_oe;
wire [31:0] gpio1_i;
wire [31:0] gpio1_o;
wire [31:0] gpio1_oe;
wire [31:0] gpio2_i;
wire [31:0] gpio2_o;
wire [31:0] gpio2_oe;
wire [31:0] gpio3_i;
wire [31:0] gpio3_o;
wire [31:0] gpio3_oe;
wire [31:0] gpio4_i;
wire [31:0] gpio4_o;
wire [31:0] gpio4_oe;
//
generate
    genvar i;
    //
    for (i = 0; i < 32; i = i + 1)
    begin
        assign gpio0_i[i] = GPIO0[i];
        assign GPIO0[i] = (gpio0_oe[i])? gpio0_o[i] : 1'bz;
    end
    for (i = 0; i < 29; i = i + 1)
    begin
        assign gpio1_i[i] = GPIO1[i];
        assign GPIO1[i] = (gpio1_oe[i])? gpio1_o[i] : 1'bz;
    end
    for (i = 0; i < 11; i = i + 1)
    begin
        assign gpio2_i[i] = GPIO2[i];
        assign GPIO2[i] = (gpio2_oe[i])? gpio2_o[i] : 1'bz;
    end
    //
    for (i = 0; i < 32; i = i + 1)
    begin
        assign gpio3_i[i] = port_keyprt_cmd[i];
        assign port_keyprt_cmd[i] = (gpio3_oe[i])? gpio3_o[i] : 1'b0;
        //
        assign gpio4_i[i] = (gpio4_oe[i])? gpio4_o[i] : port_keyprt_res[i];
    end
endgenerate

//-----------------
// Clock and PLL
//-----------------
wire clk0;
wire clk1;
wire clk2;
wire clk;
wire clk_mcs4;
wire locked;
//
PLL U_PLL
(
    .areset  (1'b0),
    .inclk0  (CLK50), // 50.00MHz
    .c0      (clk0),  // 20.00MHz
    .c1      (clk1),  // 16.66MHz
    .c2      (clk2),  //   750KHz
    .locked  (locked)
);
//
`ifdef RISCV_ISA_RV32F
assign clk = clk1; // 16MHz with FPU
`else
assign clk = clk0; // 20MHz without FPU
`endif
//
`ifdef SIMULATION
assign clk_mcs4 = clk;
`else
assign clk_mcs4 = clk2;
`endif

//--------------------------
// Internal Power on Reset
//--------------------------
`ifdef SIMULATION
    `define POR_MAX 16'h000f // period of power on reset 
`else  // Real FPGA
    `define POR_MAX 16'hffff // period of power on reset 
`endif
wire res_org;          // Reset Origin
wire res_sys;          // Reset System
reg  por_n;            // should be power-up level = Low
reg  [15:0] por_count; // should be power-up level = Low
//
always @(posedge CLK50)
begin
    if (por_count != `POR_MAX)
    begin
        por_n <= 1'b0;
        por_count <= por_count + 16'h0001;
    end
    else
    begin
        por_n <= 1'b1;
        por_count <= por_count;
    end
end

//------------------------
// Generate Reset
//------------------------
reg por0, por1, por2;
always @(posedge clk)
begin
    por0 <= (~por_n) | (~RES_N) | (~locked);
    por1 <= por0;
    por2 <= por1;
end
//
assign res_org = por2;
assign RESOUT_N = ~res_sys;

//-------------------------
// MCS4 System Signals
//-------------------------
assign S_MCS4_CLK = clk_mcs4;
assign S_MCS4_RES_N = ~res_sys;

//------------------------
// RISC-V Top
//------------------------
RISCV_TOP U_RISCV_TOP
(
    .RES_ORG (res_org), // Reset Origin
    .RES_SYS (res_sys), // Reset Output (RES_ORG + Debug Reset) 
    .CLK     (clk),     // Clock Input (PLL)
    //
    .TRSTn (TRSTn), // JTAG TAP Reset
    .TCK   (TCK),   // JTAG Clock
    .TMS   (TMS),   // JTAG Mode Select
    .TDI   (TDI),   // JTAG Data Input
    .TDO_D (tdo_d), // JTAG Data Output Level
    .TDO_E (tdo_e), // JTAG Data Output Enable
    .RESET_HALT_N (reset_halt_n), // Reset Halt Request
    //
    .GPIO0_I  (gpio0_i),  // GPIO0 Input
    .GPIO0_O  (gpio0_o),  // GPIO0 Output
    .GPIO0_OE (gpio0_oe), // GPIO0 Output Enable
    .GPIO1_I  (gpio1_i),  // GPIO1 Input
    .GPIO1_O  (gpio1_o),  // GPIO1 Output
    .GPIO1_OE (gpio1_oe), // GPIO1 Output Enable
    .GPIO2_I  (gpio2_i),  // GPIO2 Input
    .GPIO2_O  (gpio2_o),  // GPIO2 Output
    .GPIO2_OE (gpio2_oe), // GPIO2 Output Enable
    .GPIO3_I  (gpio3_i),  // GPIO3 Input
    .GPIO3_O  (gpio3_o),  // GPIO3 Output
    .GPIO3_OE (gpio3_oe), // GPIO3 Output Enable
    .GPIO4_I  (gpio4_i),  // GPIO4 Input
    .GPIO4_O  (gpio4_o),  // GPIO4 Output
    .GPIO4_OE (gpio4_oe), // GPIO4 Output Enable
    //
    .RXD (RXD), // UART receive data
    .TXD (TXD), // UART transmit data
    //
    .I2C0_SCL_I   (i2c0_scl_i),   // SCL Input
    .I2C0_SCL_O   (i2c0_scl_o),   // SCL Output
    .I2C0_SCL_OEN (i2c0_scl_oen), // SCL Output Enable (neg)
    .I2C0_SDA_I   (i2c0_sda_i),   // SDA Input
    .I2C0_SDA_O   (i2c0_sda_o),   // SDA Output
    .I2C0_SDA_OEN (i2c0_sda_oen), // SDA Output Enable (neg)
    .I2C0_ENA  (I2C0_ENA),  // I2C0 Enable (Fixed to 1)
    .I2C0_ADR  (I2C0_ADR),  // I2C0 ALTADDR (Fixed to 0)
    .I2C0_INT1 (I2C0_INT1), // I2C0 Device Interrupt Request 1
    .I2C0_INT2 (I2C0_INT2), // I2C0 Device Interrupt Request 2
    //
    .I2C1_SCL_I   (i2c1_scl_i),   // SCL Input
    .I2C1_SCL_O   (i2c1_scl_o),   // SCL Output
    .I2C1_SCL_OEN (i2c1_scl_oen), // SCL Output Enable (neg)
    .I2C1_SDA_I   (i2c1_sda_i),   // SDA Input
    .I2C1_SDA_O   (i2c1_sda_o),   // SDA Output
    .I2C1_SDA_OEN (i2c1_sda_oen), // SDA Output Enable (neg)
    //
    .SPI_CSN   (SPI_CSN),  // SPI Chip Select
    .SPI_SCK   (SPI_SCK),  // SPI Clock
    .SPI_MOSI  (SPI_MOSI), // SPI MOSI
    .SPI_MISO  (SPI_MISO), // SPI MISO
    //
    .SDRAM_CLK  (SDRAM_CLK),  // SDRAM Clock
    .SDRAM_CKE  (SDRAM_CKE),  // SDRAM Clock Enable
    .SDRAM_CSn  (SDRAM_CSn),  // SDRAM Chip Select
    .SDRAM_DQM  (SDRAM_DQM),  // SDRAM Byte Data Mask
    .SDRAM_RASn (SDRAM_RASn), // SDRAM Row Address Strobe
    .SDRAM_CASn (SDRAM_CASn), // SDRAM Column Address Strobe
    .SDRAM_WEn  (SDRAM_WEn),  // SDRAM Write Enable
    .SDRAM_BA   (SDRAM_BA),   // SDRAM Bank Address
    .SDRAM_ADDR (SDRAM_ADDR), // SDRAM Addess
    .SDRAM_DQ   (SDRAM_DQ)    // SDRAM Data
);

endmodule
//===========================================================
// End of File
//===========================================================
