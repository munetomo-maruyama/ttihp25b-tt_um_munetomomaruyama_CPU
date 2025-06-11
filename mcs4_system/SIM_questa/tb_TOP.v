//===========================================================
// MCS-4 Project
//-----------------------------------------------------------
// File Name   : tb_top.v
// Description : Testbench for FPGA
//-----------------------------------------------------------
// History :
// Rev.01 2025.05.26 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

`include "defines_core.v"
`include "defines_chip.v"

`timescale 1ns/100ps

`define TB_TCYC_CLK    20 //ns (50MHz)
`define TB_TCYC_CLK_2  10 //ns (50MHz)
`define TB_TCYC_TCK   100 //ns (10MHz)
//
`define TB_TCYC_TCKC (`TB_TCYC_TCK / 5) // cJTAG TCKC
//
`define TB_STOP 100000000 //cyc
`define TB_RESET_WIDTH 50  //ns

//------------------------
// Top of Testbench
//------------------------
module tb_TOP;

//-------------------------------
// Generate Clock
//-------------------------------
reg tb_clk;
reg tb_clk_speed;
//
initial tb_clk = 1'b0;
always #(`TB_TCYC_CLK_2) tb_clk = ~tb_clk;

//--------------------------
// Generate Reset
//--------------------------
reg tb_res;
reg tb_reset_halt_n;
//
initial
begin
    tb_reset_halt_n = 1'b1;
    tb_res = 1'b1;
        # (`TB_RESET_WIDTH)
    tb_res = 1'b0;       
end
//
// Initialize Internal Power on Reset
initial
begin
    U_FPGA_TOP.por_count = 0;
    U_FPGA_TOP.por_n = 0;
end

//----------------------------
// Simulation Cycle Counter
//----------------------------
wire clk_fpga;
assign clk_fpga = U_FPGA_TOP.clk;
//
reg [31:0] tb_cyc;
//
always @(posedge clk_fpga, posedge tb_res)
begin
    if (tb_res)
    
        tb_cyc <= 32'h0;
    else
        tb_cyc <= tb_cyc + 32'h1;
end
//
always @*
begin
    if (tb_cyc == `TB_STOP)
    begin
        $display("***** SIMULATION TIMEOUT ***** at %d", tb_cyc);
        $stop;
    end
end

//----------------------------
// Simulation Stop Condition
//----------------------------
reg stop_by_stimulus;
//
initial
begin
    stop_by_stimulus = 1'b0;
end
//
always @*
begin
    if (stop_by_stimulus)
    begin
        $stop;
    end
end

//--------------------------
// Device Under Test
//--------------------------
reg  tb_trst_n;
reg  tb_tck;
reg  tb_tms;
reg  tb_tdi;
wire tb_tdo;
pullup(tb_tdo);
//
assign tb_trst_n = ~tb_res;
assign tb_tck    = 1'b0;
assign tb_tms    = 1'b0;
assign tb_tdi    = 1'b0;
//
wire [31: 0] gpio0;
wire [28: 0] gpio1;
wire [10: 0] gpio2;
//
wire rxd;
wire txd;
wire i2c0_scl;  // I2C0 SCL
wire i2c0_sda;  // I2C0 SDA
wire i2c0_ena;  // I2C0 Enable (Fixed to 1)
wire i2c0_adr;  // I2C0 ALTADDR (Fixed to 0)
wire i2c0_int1; // I2C0 Device Interrupt Request 1
wire i2c0_int2; // I2C0 Device Interrupt Request 2
wire i2c1_scl;  // I2C1 SCL
wire i2c1_sda;  // I2C1 SDA
wire [ 3:0] spi_csn;  // SPI Chip Select
wire        spi_sck;  // SPI Clock
wire        spi_mosi; // SPI MOSI
wire        spi_miso; // SPI MISO
//
wire        sdram_clk;  // SDRAM Clock
wire        sdram_cke;  // SDRAM Clock Enable
wire        sdram_csn;  // SDRAM Chip Select
wire [ 1:0] sdram_dqm;  // SDRAM Byte Data Mask
wire        sdram_rasn; // SDRAM Row Address Strobe
wire        sdram_casn; // SDRAM Column Address Strobe
wire        sdram_wen;  // SDRAM Write Enable
wire [ 1:0] sdram_ba;   // SDRAM Bank Address
wire [12:0] sdram_addr; // SDRAM Addess
wire [15:0] sdram_dq;   // SDRAM Data
//
pullup(txd);
pullup(i2c0_scl);
pullup(i2c0_sda);
pullup(i2c1_scl);
pullup(i2c1_sda);
assign i2c0_int1 = 1'b0;
assign i2c0_int2 = 1'b0;
assign spi_miso = ~spi_mosi; // reversed loop back
//
generate
    genvar i;
    for (i =  0; i < 32; i = i + 1) pullup(gpio0[i]);
    for (i =  0; i < 29; i = i + 1) pullup(gpio1[i]);
    for (i =  0; i < 11; i = i + 1) pullup(gpio2[i]);
endgenerate
//
assign gpio2[10] = tb_reset_halt_n;
//
wire        mcs4_clk;      // MCS4_SYS Clock Loop Back
wire        mcs4_res_n;    // MCS4_SYS Reset Loop Back
wire        mcs4_sync_n;   // MCS4_SYS SYNC_N Loop Back
wire        mcs4_test;     // MCS4_STS TEST Loop Back
wire        mcs4_cm_rom_n; // MCS4_SYS CM_ROM_N Loop Back
wire [ 3:0] mcs4_cm_ram_n; // MCS4_SYS CM_RAM_N Loop Back
wire [ 3:0] mcs4_data;     // MCS4_SYS DATA Loop Back
//
FPGA_TOP U_FPGA_TOP
(
    .RES_N (~tb_res),
    .CLK50 (tb_clk),
    //
    .RESOUT_N (),
    //
    .TRSTn (tb_trst_n),
    .TCK   (tb_tck),
    .TMS   (tb_tms),
    .TDI   (tb_tdi),
    .TDO   (tb_tdo),
    //
    .GPIO0 (gpio0),
    .GPIO1 (gpio1),
    .GPIO2 (gpio2),
    //
    .RXD (txd),
    .TXD (rxd),
    //
    .I2C0_SCL  (i2c0_scl),  // I2C0 SCL
    .I2C0_SDA  (i2c0_sda),  // I2C0 SDA
    .I2C0_ENA  (i2c0_ena),  // I2C0 Enable (Fixed to 1)
    .I2C0_ADR  (i2c0_adr),  // I2C0 ALTADDR (Fixed to 0)
    .I2C0_INT1 (i2c0_int1), // I2C0 Device Interrupt Request 1
    .I2C0_INT2 (i2c0_int2), // I2C0 Device Interrupt Request 2
    //
    .I2C1_SCL  (i2c1_scl),  // I2C1 SCL
    .I2C1_SDA  (i2c1_sda),  // I2C1 SDA
    //
    .SPI_CSN  (spi_csn),  // SPI Chip Select
    .SPI_SCK  (spi_sck),  // SPI Clock
    .SPI_MOSI (spi_mosi), // SPI MOSI
    .SPI_MISO (spi_miso), // SPI MISO
    //
    .SDRAM_CLK  (sdram_clk),  // SDRAM Clock
    .SDRAM_CKE  (sdram_cke),  // SDRAM Clock Enable
    .SDRAM_CSn  (sdram_csn),  // SDRAM Chip Select
    .SDRAM_DQM  (sdram_dqm),  // SDRAM Byte Data Mask
    .SDRAM_RASn (sdram_rasn), // SDRAM Row Address Strobe
    .SDRAM_CASn (sdram_casn), // SDRAM Column Address Strobe
    .SDRAM_WEn  (sdram_wen),  // SDRAM Write Enable
    .SDRAM_BA   (sdram_ba),   // SDRAM Bank Address
    .SDRAM_ADDR (sdram_addr), // SDRAM Addess
    .SDRAM_DQ   (sdram_dq),   // SDRAM Data
    //
    .S_MCS4_CLK      (mcs4_clk),      // MCS4_SYS Clock Output
    .S_MCS4_RES_N    (mcs4_res_n),    // MCS4_SYS Reset Output
    .S_MCS4_SYNC_N   (mcs4_sync_n),   // MCS4_SYS SYNC_N Input
    .S_MCS4_TEST     (mcs4_test),     // MCS4_STS TEST Output
    .S_MCS4_CM_ROM_N (mcs4_cm_rom_n), // MCS4_SYS CM_ROM_N Input
    .S_MCS4_CM_RAM_N (mcs4_cm_ram_n), // MCS4_SYS CM_RAM_N Input
    .S_MCS4_DATA     (mcs4_data),     // MCS4_SYS DATA Inout
    //
    .C_MCS4_CLK      (mcs4_clk),      // MCS4_CPU Clock Input
    .C_MCS4_RES_N    (mcs4_res_n),    // MCS4_CPU Reset Input
    .C_MCS4_SYNC_N   (mcs4_sync_n),   // MCS4_CPU SYNC_N Output
    .C_MCS4_TEST     (mcs4_test),     // MCS4_CPU TEST Input
    .C_MCS4_CM_ROM_N (mcs4_cm_rom_n), // MCS4_CPU CM_ROM_N Output
    .C_MCS4_CM_RAM_N (mcs4_cm_ram_n), // MCS4_CPU CM_RAM_N Output
    .C_MCS4_DATA     (mcs4_data)      // MCS4_CPU DATA Inout
);

//--------------------
// I2C Model
//--------------------
i2c_slave_model U_I2C_SLAVE0
(
    .scl (i2c_scl0),
    .sda (i2c_sda0)
);
i2c_slave_model U_I2C_SLAVE1
(
    .scl (i2c_scl1),
    .sda (i2c_sda1)
);

//--------------------
// SDRAM Model
//--------------------
sdr U_SDRAM
(
    .Dq    (sdram_dq),
    .Addr  (sdram_addr),
    .Ba    (sdram_ba),
    .Clk   (sdram_clk),
    .Cke   (sdram_cke),
    .Cs_n  (sdram_csn),
    .Ras_n (sdram_rasn),
    .Cas_n (sdram_casn),
    .We_n  (sdram_wen),
    .Dqm   (sdram_dqm)
);

//------------------------
// Stimulus
//------------------------
initial
begin
  //#(`TB_TCYC_CLK * 100000);
  //$display("***** DETECT FINAL STIMULUS *****");
  //stop_by_stimulus = 1'b1;
end

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
