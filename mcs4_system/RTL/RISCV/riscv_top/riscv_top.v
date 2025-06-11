//===========================================================
// mmRISC-1 Project
//-----------------------------------------------------------
// File Name   : riscv_top.v
// Description : Top Layer of Chip
//-----------------------------------------------------------
// History :
// Rev.01 2017.07.16 M.Maruyama First Release
// Rev.02 2020.01.01 M.Maruyama Debug Spec Version 0.13.2
// Rev.03 2023.05.14 M.Maruyama cJTAG Support and Halt-on-Reset
// Rev.04 2024.07.27 M.Maruyama Changed selection method for JTAG/cJTAG
// Rev.05 2025.05.27 M.Maruyama RISCV_Top for MCS-4 system
//-----------------------------------------------------------
// Copyright (C) 2017-2023 M.Maruyama
//===========================================================

`include "defines_chip.v"
`include "defines_core.v"

//----------------------
// Define Module
//----------------------
module RISCV_TOP
(
    input  wire RES_ORG, // Reset Origin
    output wire RES_SYS, // Reset Output (RES_ORG + Debug Reset) 
    input  wire CLK,     // Clock Input (50MHz)
    //
    input  wire TRSTn, // JTAG TAP Reset
    input  wire TCK,   // JTAG Clock
    input  wire TMS,   // JTAG Mode Select
    input  wire TDI,   // JTAG Data Input
    output wire TDO_D, // JTAG Data Output Level
    output wire TDO_E, // JTAG Data Output Enable
    input  wire RESET_HALT_N, // Reset Halt Request
    //
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
    output wire [31:0] GPIO4_OE, // GPIO4 Output Enable
    //
    input  wire RXD, // UART receive data
    output wire TXD, // UART transmit data
    //
    input  wire I2C0_SCL_I,   //I2C0 SCL Input
    output wire I2C0_SCL_O,   //I2C0 SCL Output
    output wire I2C0_SCL_OEN, //I2C0 SCL Output Enable
    input  wire I2C0_SDA_I,   //I2C0 SDA Input
    output wire I2C0_SDA_O,   //I2C0 SDA Output
    output wire I2C0_SDA_OEN, //I2C0 SDA Output Enable
    //
    output wire I2C0_ENA,  // I2C0 Enable (Fixed to 1)
    output wire I2C0_ADR,  // I2C0 ALTADDR (Fixed to 0)
    input  wire I2C0_INT1, // I2C0 Device Interrupt Request 1
    input  wire I2C0_INT2, // I2C0 Device Interrupt Request 2
    //
    input  wire I2C1_SCL_I,   //I2C1 SCL Input
    output wire I2C1_SCL_O,   //I2C1 SCL Output
    output wire I2C1_SCL_OEN, //I2C1 SCL Output Enable
    input  wire I2C1_SDA_I,   //I2C1 SDA Input
    output wire I2C1_SDA_O,   //I2C1 SDA Output
    output wire I2C1_SDA_OEN, //I2C1 SDA Output Enable
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
    inout  wire [15:0] SDRAM_DQ    // SDRAM Data
);

//---------------------
// System Signals
//---------------------
wire clk;
wire res_org;
wire res_sys;
assign clk = CLK;
assign res_org = RES_ORG;
assign RES_SYS = res_sys;
//
wire stby_req;
wire stby_ack;
wire srst_n_in;
wire srst_n_out;
assign stby_req = 1'b0;
assign srst_n_in = ~res_org;

//---------------------
// Reset Halt Control
//---------------------
reg halt_req;
wire force_halt_on_reset_req_jtag;
wire force_halt_on_reset_ack_jtag;
//
always @(posedge CLK, posedge RES_ORG)
begin
    if (RES_ORG)
        halt_req <= ~RESET_HALT_N;
    else if (force_halt_on_reset_ack_jtag)
        halt_req <= 1'b0;
end
//
assign force_halt_on_reset_req_jtag = halt_req;

//--------------------------
// JTAG related signals
//--------------------------
wire rtck;
wire [31:0] jtag_dr_user_in;   // You can put data to JTAG
wire [31:0] jtag_dr_user_out;  // You can get data from JTAG such as Mode Settings
assign jtag_dr_user_in = ~jtag_dr_user_out; // So far, Loop back inverted value

//---------------
// mmRISC
//---------------
wire [31:0] reset_vector     [0:`HART_COUNT-1]; // Reset Vector
wire        debug_secure;        // Debug Authentication is available or not
wire [31:0] debug_secure_code_0; // Debug Authentication Code 0
wire [31:0] debug_secure_code_1; // Debug Authentication Code 1
//
wire        cpui_m_hsel      [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [ 1:0] cpui_m_htrans    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hwrite    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hmastlock [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [ 2:0] cpui_m_hsize     [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [ 2:0] cpui_m_hburst    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [ 3:0] cpui_m_hprot     [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [31:0] cpui_m_haddr     [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [31:0] cpui_m_hwdata    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hready    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hreadyout [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire [31:0] cpui_m_hrdata    [0:`HART_COUNT-1]; // AHB for CPU Instruction
wire        cpui_m_hresp     [0:`HART_COUNT-1]; // AHB for CPU Instruction
//
wire        cpud_m_hsel      [0:`HART_COUNT-1]; // AHB for CPU Data
wire [ 1:0] cpud_m_htrans    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hwrite    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hmastlock [0:`HART_COUNT-1]; // AHB for CPU Data
wire [ 2:0] cpud_m_hsize     [0:`HART_COUNT-1]; // AHB for CPU Data
wire [ 2:0] cpud_m_hburst    [0:`HART_COUNT-1]; // AHB for CPU Data
wire [ 3:0] cpud_m_hprot     [0:`HART_COUNT-1]; // AHB for CPU Data
wire [31:0] cpud_m_haddr     [0:`HART_COUNT-1]; // AHB for CPU Data
wire [31:0] cpud_m_hwdata    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hready    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hreadyout [0:`HART_COUNT-1]; // AHB for CPU Data
wire [31:0] cpud_m_hrdata    [0:`HART_COUNT-1]; // AHB for CPU Data
wire        cpud_m_hresp     [0:`HART_COUNT-1]; // AHB for CPU Data
//
`ifdef RISCV_ISA_RV32A
wire        cpum_s_hsel      [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire [ 1:0] cpum_s_htrans    [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire        cpum_s_hwrite    [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire [31:0] cpum_s_haddr     [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire        cpum_s_hready    [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
wire        cpum_s_hreadyout [0:`HART_COUNT-1]; // AHB Monitor for LR/SC
`endif
//
wire        dbgd_m_hsel     ; // AHB for Debugger System Access
wire [ 1:0] dbgd_m_htrans   ; // AHB for Debugger System Access
wire        dbgd_m_hwrite   ; // AHB for Debugger System Access
wire        dbgd_m_hmastlock; // AHB for Debugger System Access
wire [ 2:0] dbgd_m_hsize    ; // AHB for Debugger System Access
wire [ 2:0] dbgd_m_hburst   ; // AHB for Debugger System Access
wire [ 3:0] dbgd_m_hprot    ; // AHB for Debugger System Access
wire [31:0] dbgd_m_haddr    ; // AHB for Debugger System Access
wire [31:0] dbgd_m_hwdata   ; // AHB for Debugger System Access
wire        dbgd_m_hready   ; // AHB for Debugger System Access
wire        dbgd_m_hreadyout; // AHB for Debugger System Access
wire [31:0] dbgd_m_hrdata   ; // AHB for Debugger System Access
wire        dbgd_m_hresp    ; // AHB for Debugger System Access
//
wire        m_hsel     [0:`MASTERS-1];
wire [ 1:0] m_htrans   [0:`MASTERS-1];
wire        m_hwrite   [0:`MASTERS-1];
wire        m_hmastlock[0:`MASTERS-1];
wire [ 2:0] m_hsize    [0:`MASTERS-1];
wire [ 2:0] m_hburst   [0:`MASTERS-1];
wire [ 3:0] m_hprot    [0:`MASTERS-1];
wire [31:0] m_haddr    [0:`MASTERS-1];
wire [31:0] m_hwdata   [0:`MASTERS-1];
wire        m_hready   [0:`MASTERS-1];
wire        m_hreadyout[0:`MASTERS-1];
wire [31:0] m_hrdata   [0:`MASTERS-1];
wire        m_hresp    [0:`MASTERS-1];
//
wire        s_hsel     [0:`SLAVES-1];
wire [ 1:0] s_htrans   [0:`SLAVES-1];
wire        s_hwrite   [0:`SLAVES-1];
wire        s_hmastlock[0:`SLAVES-1];
wire [ 2:0] s_hsize    [0:`SLAVES-1];
wire [ 2:0] s_hburst   [0:`SLAVES-1];
wire [ 3:0] s_hprot    [0:`SLAVES-1];
wire [31:0] s_haddr    [0:`SLAVES-1];
wire [31:0] s_hwdata   [0:`SLAVES-1];
wire        s_hready   [0:`SLAVES-1];
wire        s_hreadyout[0:`SLAVES-1];
wire [31:0] s_hrdata   [0:`SLAVES-1];
wire        s_hresp    [0:`SLAVES-1];
//
// Bus Signals
generate
begin
    genvar i;
    for (i = 0; i < `HART_COUNT; i = i + 1)
    begin : AHB_SIGNALS
        assign m_hsel     [i            ] = cpud_m_hsel[i];
        assign m_htrans   [i            ] = cpud_m_htrans[i];
        assign m_hwrite   [i            ] = cpud_m_hwrite[i];
        assign m_hmastlock[i            ] = cpud_m_hmastlock[i];
        assign m_hsize    [i            ] = cpud_m_hsize[i];
        assign m_hburst   [i            ] = cpud_m_hburst[i];
        assign m_hprot    [i            ] = cpud_m_hprot[i];
        assign m_haddr    [i            ] = cpud_m_haddr[i];
        assign m_hwdata   [i            ] = cpud_m_hwdata[i];
        assign m_hready   [i            ] = cpud_m_hready[i];
        assign m_hsel     [i+`HART_COUNT] = cpui_m_hsel[i];
        assign m_htrans   [i+`HART_COUNT] = cpui_m_htrans[i];
        assign m_hwrite   [i+`HART_COUNT] = cpui_m_hwrite[i];
        assign m_hmastlock[i+`HART_COUNT] = cpui_m_hmastlock[i];
        assign m_hsize    [i+`HART_COUNT] = cpui_m_hsize[i];
        assign m_hburst   [i+`HART_COUNT] = cpui_m_hburst[i];
        assign m_hprot    [i+`HART_COUNT] = cpui_m_hprot[i];
        assign m_haddr    [i+`HART_COUNT] = cpui_m_haddr[i];
        assign m_hwdata   [i+`HART_COUNT] = cpui_m_hwdata[i];
        assign m_hready   [i+`HART_COUNT] = cpui_m_hready[i];
        assign cpud_m_hreadyout[i] = m_hreadyout[i            ];
        assign cpud_m_hrdata[i]    = m_hrdata   [i            ];
        assign cpud_m_hresp[i]     = m_hresp    [i            ];
        assign cpui_m_hreadyout[i] = m_hreadyout[i+`HART_COUNT];
        assign cpui_m_hrdata[i]    = m_hrdata   [i+`HART_COUNT];
        assign cpui_m_hresp[i]     = m_hresp    [i+`HART_COUNT];
        //
        `ifdef RISCV_ISA_RV32A
        assign cpum_s_hsel[i]      = s_hsel     [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_htrans[i]    = s_htrans   [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_hwrite[i]    = s_hwrite   [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_haddr[i]     = s_haddr    [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_hready[i]    = s_hready   [`SLAVE_SDRAM]; // Monitor SDRAM
        assign cpum_s_hreadyout[i] = s_hreadyout[`SLAVE_SDRAM]; // Monitor SDRAM
        `endif
    end
    //
    assign m_hsel     [`HART_COUNT * 2] = dbgd_m_hsel;
    assign m_htrans   [`HART_COUNT * 2] = dbgd_m_htrans;
    assign m_hwrite   [`HART_COUNT * 2] = dbgd_m_hwrite;
    assign m_hmastlock[`HART_COUNT * 2] = dbgd_m_hmastlock;
    assign m_hsize    [`HART_COUNT * 2] = dbgd_m_hsize;
    assign m_hburst   [`HART_COUNT * 2] = dbgd_m_hburst;
    assign m_hprot    [`HART_COUNT * 2] = dbgd_m_hprot;
    assign m_haddr    [`HART_COUNT * 2] = dbgd_m_haddr;
    assign m_hwdata   [`HART_COUNT * 2] = dbgd_m_hwdata;
    assign m_hready   [`HART_COUNT * 2] = dbgd_m_hready;
    assign dbgd_m_hreadyout = m_hreadyout[`HART_COUNT * 2];
    assign dbgd_m_hrdata    = m_hrdata   [`HART_COUNT * 2];
    assign dbgd_m_hresp     = m_hresp    [`HART_COUNT * 2];
end
endgenerate
//
// Interrupts
wire        irq_ext;
wire        irq_msoft;
wire        irq_mtime;
wire [63:0] irq_gen;
wire [63:0] irq;
wire        irq_uart;
wire        irq_i2c0;
wire        irq_i2c1;
wire        irq_spi;
//
// Timer Counter
wire [31:0] mtime;
wire [31:0] mtimeh;
wire        dbg_stop_timer; // Stop Timer due to Debug Mode
//
// UART
wire cts, rts;
assign cts = 1'b0;
//
// I2C
assign I2C0_ENA   = 1'b1;
assign I2C0_ADR   = 1'b0;

//-----------------------------------------
// mmRISC
//-----------------------------------------
// Reset Vector
generate
begin
    genvar i;
    for (i = 0; i < `HART_COUNT; i = i + 1)
    begin : RESET_VECTOR
        assign reset_vector[i] = (`RESET_VECTOR_BASE) + (`RESET_VECTOR_DISP * i);
    end
end
endgenerate
//
// Security
assign debug_secure        = `DEBUG_SECURE_ENBL;
assign debug_secure_code_0 = `DEBUG_SECURE_CODE_0;
assign debug_secure_code_1 = `DEBUG_SECURE_CODE_1;
//
// mmRISC Body
mmRISC
   #(
        .HART_COUNT   (`HART_COUNT)
    )
U_MMRISC
(
    .RES_ORG (res_org),
    .RES_SYS (res_sys),
    .CLK     (clk),
    //
    .STBY_REQ (stby_req),
    .STBY_ACK (stby_ack),
    //
    .SRSTn_IN  (srst_n_in),
    .SRSTn_OUT (srst_n_out),
    //
    .FORCE_HALT_ON_RESET_REQ (force_halt_on_reset_req),
    .FORCE_HALT_ON_RESET_ACK (force_halt_on_reset_ack),
    .JTAG_DR_USER_IN  (jtag_dr_user_in ),
    .JTAG_DR_USER_OUT (jtag_dr_user_out),
    //
    .TRSTn (TRSTn),
    .TCK   (TCK),
    .TMS   (TMS),
    .TDI   (TDI),
    .TDO_D (TDO_D),
    .TDO_E (TDO_E),
    .RTCK  (rtck),
    //
    .RESET_VECTOR        (reset_vector),
    .DEBUG_SECURE        (debug_secure),
    .DEBUG_SECURE_CODE_0 (debug_secure_code_0),
    .DEBUG_SECURE_CODE_1 (debug_secure_code_1),
    //
    .CPUI_M_HSEL      (cpui_m_hsel),
    .CPUI_M_HTRANS    (cpui_m_htrans),
    .CPUI_M_HWRITE    (cpui_m_hwrite),
    .CPUI_M_HMASTLOCK (cpui_m_hmastlock),
    .CPUI_M_HSIZE     (cpui_m_hsize),
    .CPUI_M_HBURST    (cpui_m_hburst),
    .CPUI_M_HPROT     (cpui_m_hprot),
    .CPUI_M_HADDR     (cpui_m_haddr),
    .CPUI_M_HWDATA    (cpui_m_hwdata),
    .CPUI_M_HREADY    (cpui_m_hready),
    .CPUI_M_HREADYOUT (cpui_m_hreadyout),
    .CPUI_M_HRDATA    (cpui_m_hrdata),
    .CPUI_M_HRESP     (cpui_m_hresp),
    //
    .CPUD_M_HSEL      (cpud_m_hsel),
    .CPUD_M_HTRANS    (cpud_m_htrans),
    .CPUD_M_HWRITE    (cpud_m_hwrite),
    .CPUD_M_HMASTLOCK (cpud_m_hmastlock),
    .CPUD_M_HSIZE     (cpud_m_hsize),
    .CPUD_M_HBURST    (cpud_m_hburst),
    .CPUD_M_HPROT     (cpud_m_hprot),
    .CPUD_M_HADDR     (cpud_m_haddr),
    .CPUD_M_HWDATA    (cpud_m_hwdata),
    .CPUD_M_HREADY    (cpud_m_hready),
    .CPUD_M_HREADYOUT (cpud_m_hreadyout),
    .CPUD_M_HRDATA    (cpud_m_hrdata),
    .CPUD_M_HRESP     (cpud_m_hresp),
    //
    `ifdef RISCV_ISA_RV32A
    .CPUM_S_HSEL      (cpum_s_hsel),
    .CPUM_S_HTRANS    (cpum_s_htrans),
    .CPUM_S_HWRITE    (cpum_s_hwrite),
    .CPUM_S_HADDR     (cpum_s_haddr),
    .CPUM_S_HREADY    (cpum_s_hready),
    .CPUM_S_HREADYOUT (cpum_s_hreadyout),
    `endif
    //
    .DBGD_M_HSEL      (dbgd_m_hsel),
    .DBGD_M_HTRANS    (dbgd_m_htrans),
    .DBGD_M_HWRITE    (dbgd_m_hwrite),
    .DBGD_M_HMASTLOCK (dbgd_m_hmastlock),
    .DBGD_M_HSIZE     (dbgd_m_hsize),
    .DBGD_M_HBURST    (dbgd_m_hburst),
    .DBGD_M_HPROT     (dbgd_m_hprot),
    .DBGD_M_HADDR     (dbgd_m_haddr),
    .DBGD_M_HWDATA    (dbgd_m_hwdata),
    .DBGD_M_HREADY    (dbgd_m_hready),
    .DBGD_M_HREADYOUT (dbgd_m_hreadyout),
    .DBGD_M_HRDATA    (dbgd_m_hrdata),
    .DBGD_M_HRESP     (dbgd_m_hresp),
    //
    .IRQ_EXT   (irq_ext),
    .IRQ_MSOFT (irq_msoft),
    .IRQ_MTIME (irq_mtime),
    .IRQ       (irq),
    //
    .MTIME  (mtime),
    .MTIMEH (mtimeh),
    .DBG_STOP_TIMER (dbg_stop_timer)  // Stop Timer due to Debug Mode
);

//---------------------
// AHB Bus Matrix
//---------------------
wire  [`MASTERS_BIT-1:0] m_priority[0:`MASTERS-1];
wire [31:0] s_haddr_base[0:`SLAVES-1];
wire [31:0] s_haddr_mask[0:`SLAVES-1];
//
generate
begin
    genvar i;
    //
    // Priorty of Data Port and Instruction Port for Each Hart
    for (i = 0; i < `HART_COUNT; i = i + 1)
    begin : MASTER_HART_PRIORITY
        assign m_priority[i              ] = ((`MASTERS_BIT)'(1)); // Data
        assign m_priority[i + `HART_COUNT] = ((`MASTERS_BIT)'(2)); // Inst
    end
    //
    // Priorty of Other Ports
    assign m_priority[(`HART_COUNT * 2    )] = ((`MASTERS_BIT)'(0)); // DBGD
end
endgenerate
//
//generate
//    for (i = 0; i < `MASTERS; i = i + 1)
//    begin : MASTER_PRIORITY
//        if (i == 0)      assign m_priority[i] = `M_PRIORITY_0;
//        else if (i == 1) assign m_priority[i] = `M_PRIORITY_1;
//        else if (i == 2) assign m_priority[i] = `M_PRIORITY_2;
//        else if (i == 3) assign m_priority[i] = `M_PRIORITY_3;
//        else if (i == 4) assign m_priority[i] = `M_PRIORITY_4;
//        else if (i == 5) assign m_priority[i] = `M_PRIORITY_5;
//        else if (i == 6) assign m_priority[i] = `M_PRIORITY_6;
//        else if (i == 7) assign m_priority[i] = `M_PRIORITY_7;
//        else if (i == 8) assign m_priority[i] = `M_PRIORITY_8;
//        else             assign m_priority[i] = ((`MASTERS_BIT)'(i));
//    end
//endgenerate

//-----------------------
// Slave Address
//-----------------------
assign s_haddr_base[`SLAVE_MTIME ] = `SLAVE_BASE_MTIME;
assign s_haddr_base[`SLAVE_SDRAM ] = `SLAVE_BASE_SDRAM;
assign s_haddr_base[`SLAVE_RAMD  ] = `SLAVE_BASE_RAMD;
assign s_haddr_base[`SLAVE_RAMI  ] = `SLAVE_BASE_RAMI;
assign s_haddr_base[`SLAVE_GPIO  ] = `SLAVE_BASE_GPIO;
assign s_haddr_base[`SLAVE_UART  ] = `SLAVE_BASE_UART;
assign s_haddr_base[`SLAVE_INTGEN] = `SLAVE_BASE_INTGEN;
assign s_haddr_base[`SLAVE_I2C0  ] = `SLAVE_BASE_I2C0;
assign s_haddr_base[`SLAVE_I2C1  ] = `SLAVE_BASE_I2C1;
assign s_haddr_base[`SLAVE_SPI   ] = `SLAVE_BASE_SPI;
//
assign s_haddr_mask[`SLAVE_MTIME ] = `SLAVE_MASK_MTIME;
assign s_haddr_mask[`SLAVE_SDRAM ] = `SLAVE_MASK_SDRAM;
assign s_haddr_mask[`SLAVE_RAMD  ] = `SLAVE_MASK_RAMD;
assign s_haddr_mask[`SLAVE_RAMI  ] = `SLAVE_MASK_RAMI;
assign s_haddr_mask[`SLAVE_GPIO  ] = `SLAVE_MASK_GPIO;
assign s_haddr_mask[`SLAVE_UART  ] = `SLAVE_MASK_UART;
assign s_haddr_mask[`SLAVE_INTGEN] = `SLAVE_MASK_INTGEN;
assign s_haddr_mask[`SLAVE_I2C0  ] = `SLAVE_MASK_I2C0;
assign s_haddr_mask[`SLAVE_I2C1  ] = `SLAVE_MASK_I2C1;
assign s_haddr_mask[`SLAVE_SPI   ] = `SLAVE_MASK_SPI;
//
AHB_MATRIX
   #(
        .MASTERS  (`MASTERS),
        .SLAVES   (`SLAVES)
    )
U_AHB_MATRIX 
(
    // Global Signals
    .HCLK    (clk),
    .HRESETn (~res_sys),
    // Master Ports
    .M_HSEL      (m_hsel),
    .M_HTRANS    (m_htrans),
    .M_HWRITE    (m_hwrite),
    .M_HMASTLOCK (m_hmastlock),
    .M_HSIZE     (m_hsize),
    .M_HBURST    (m_hburst),
    .M_HPROT     (m_hprot),
    .M_HADDR     (m_haddr),
    .M_HWDATA    (m_hwdata),
    .M_HREADY    (m_hready),
    .M_HREADYOUT (m_hreadyout),
    .M_HRDATA    (m_hrdata),
    .M_HRESP     (m_hresp),
    .M_PRIORITY  (m_priority),
    // Slave Ports
    .S_HSEL      (s_hsel),
    .S_HTRANS    (s_htrans),
    .S_HWRITE    (s_hwrite),
    .S_HMASTLOCK (s_hmastlock),
    .S_HSIZE     (s_hsize),
    .S_HBURST    (s_hburst),
    .S_HPROT     (s_hprot),
    .S_HADDR     (s_haddr),
    .S_HWDATA    (s_hwdata),
    .S_HREADY    (s_hready),
    .S_HREADYOUT (s_hreadyout),
    .S_HRDATA    (s_hrdata),
    .S_HRESP     (s_hresp),
    .S_HADDR_BASE(s_haddr_base),
    .S_HADDR_MASK(s_haddr_mask)
);

//--------------------
// CSR_MTIME
//--------------------
CSR_MTIME U_CSR_MTIME 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_MTIME]),
    .S_HTRANS    (s_htrans   [`SLAVE_MTIME]),
    .S_HWRITE    (s_hwrite   [`SLAVE_MTIME]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_MTIME]),
    .S_HSIZE     (s_hsize    [`SLAVE_MTIME]),
    .S_HBURST    (s_hburst   [`SLAVE_MTIME]),
    .S_HPROT     (s_hprot    [`SLAVE_MTIME]),
    .S_HADDR     (s_haddr    [`SLAVE_MTIME]),
    .S_HWDATA    (s_hwdata   [`SLAVE_MTIME]),
    .S_HREADY    (s_hready   [`SLAVE_MTIME]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_MTIME]),
    .S_HRDATA    (s_hrdata   [`SLAVE_MTIME]),
    .S_HRESP     (s_hresp    [`SLAVE_MTIME]),
    // External Clock
    .CSR_MTIME_EXTCLK (TCK),
    // Interrupt Output
    .IRQ_MSOFT (irq_msoft),
    .IRQ_MTIME (irq_mtime),
    // Timer Counter
    .MTIME  (mtime),
    .MTIMEH (mtimeh),
    .DBG_STOP_TIMER (dbg_stop_timer)  // Stop Timer due to Debug Mode
);

//----------------------
// SDRAM Interface
//----------------------
ahb_lite_sdram U_AHB_SDRAM
(
    // Global Signals
    .HCLK     (clk),
    .HRESETn  (~res_sys),
    // Slave Ports
    // Slave Ports
    .HSEL      (s_hsel     [`SLAVE_SDRAM]),
    .HTRANS    (s_htrans   [`SLAVE_SDRAM]),
    .HWRITE    (s_hwrite   [`SLAVE_SDRAM]),
    .HMASTLOCK (s_hmastlock[`SLAVE_SDRAM]),
    .HSIZE     (s_hsize    [`SLAVE_SDRAM]),
    .HBURST    (s_hburst   [`SLAVE_SDRAM]),
    .HPROT     (s_hprot    [`SLAVE_SDRAM]),
    .HADDR     (s_haddr    [`SLAVE_SDRAM]),
    .HWDATA    (s_hwdata   [`SLAVE_SDRAM]),
    .HREADY    (s_hready   [`SLAVE_SDRAM]),
    .HREADYOUT (s_hreadyout[`SLAVE_SDRAM]),
    .HRDATA    (s_hrdata   [`SLAVE_SDRAM]),
    .HRESP     (s_hresp    [`SLAVE_SDRAM]),
    .SI_Endian (1'b0),
    //SDRAM side
    .CKE   (SDRAM_CKE),
    .CSn   (SDRAM_CSn),
    .RASn  (SDRAM_RASn),
    .CASn  (SDRAM_CASn),
    .WEn   (SDRAM_WEn),
    .ADDR  (SDRAM_ADDR),
    .BA    (SDRAM_BA),
    .DQ    (SDRAM_DQ),
    .DQM   (SDRAM_DQM)
);

//--------------------
// RAM Data
//--------------------
RAM
   #(
        .RAM_SIZE(`RAMD_SIZE)
    )
U_RAMD
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_RAMD]),
    .S_HTRANS    (s_htrans   [`SLAVE_RAMD]),
    .S_HWRITE    (s_hwrite   [`SLAVE_RAMD]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_RAMD]),
    .S_HSIZE     (s_hsize    [`SLAVE_RAMD]),
    .S_HBURST    (s_hburst   [`SLAVE_RAMD]),
    .S_HPROT     (s_hprot    [`SLAVE_RAMD]),
    .S_HADDR     (s_haddr    [`SLAVE_RAMD]),
    .S_HWDATA    (s_hwdata   [`SLAVE_RAMD]),
    .S_HREADY    (s_hready   [`SLAVE_RAMD]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_RAMD]),
    .S_HRDATA    (s_hrdata   [`SLAVE_RAMD]),
    .S_HRESP     (s_hresp    [`SLAVE_RAMD])
);

//--------------------
// RAM Instruction
//--------------------
`ifdef FPGA
RAM_FPGA U_RAMI
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_RAMI]),
    .S_HTRANS    (s_htrans   [`SLAVE_RAMI]),
    .S_HWRITE    (s_hwrite   [`SLAVE_RAMI]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_RAMI]),
    .S_HSIZE     (s_hsize    [`SLAVE_RAMI]),
    .S_HBURST    (s_hburst   [`SLAVE_RAMI]),
    .S_HPROT     (s_hprot    [`SLAVE_RAMI]),
    .S_HADDR     (s_haddr    [`SLAVE_RAMI]),
    .S_HWDATA    (s_hwdata   [`SLAVE_RAMI]),
    .S_HREADY    (s_hready   [`SLAVE_RAMI]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_RAMI]),
    .S_HRDATA    (s_hrdata   [`SLAVE_RAMI]),
    .S_HRESP     (s_hresp    [`SLAVE_RAMI])
);
`else
RAM
   #(
        .RAM_SIZE(`RAMI_SIZE)
    )
U_RAMI
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_RAMI]),
    .S_HTRANS    (s_htrans   [`SLAVE_RAMI]),
    .S_HWRITE    (s_hwrite   [`SLAVE_RAMI]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_RAMI]),
    .S_HSIZE     (s_hsize    [`SLAVE_RAMI]),
    .S_HBURST    (s_hburst   [`SLAVE_RAMI]),
    .S_HPROT     (s_hprot    [`SLAVE_RAMI]),
    .S_HADDR     (s_haddr    [`SLAVE_RAMI]),
    .S_HWDATA    (s_hwdata   [`SLAVE_RAMI]),
    .S_HREADY    (s_hready   [`SLAVE_RAMI]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_RAMI]),
    .S_HRDATA    (s_hrdata   [`SLAVE_RAMI]),
    .S_HRESP     (s_hresp    [`SLAVE_RAMI])
);
`endif

//--------------------
// GPIO Port
//--------------------
PORT U_PORT 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_GPIO]),
    .S_HTRANS    (s_htrans   [`SLAVE_GPIO]),
    .S_HWRITE    (s_hwrite   [`SLAVE_GPIO]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_GPIO]),
    .S_HSIZE     (s_hsize    [`SLAVE_GPIO]),
    .S_HBURST    (s_hburst   [`SLAVE_GPIO]),
    .S_HPROT     (s_hprot    [`SLAVE_GPIO]),
    .S_HADDR     (s_haddr    [`SLAVE_GPIO]),
    .S_HWDATA    (s_hwdata   [`SLAVE_GPIO]),
    .S_HREADY    (s_hready   [`SLAVE_GPIO]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_GPIO]),
    .S_HRDATA    (s_hrdata   [`SLAVE_GPIO]),
    .S_HRESP     (s_hresp    [`SLAVE_GPIO]),
    // GPIO Port
    .GPIO0_I  (GPIO0_I),  // GPIO0 Input
    .GPIO0_O  (GPIO0_O),  // GPIO0 Output
    .GPIO0_OE (GPIO0_OE), // GPIO0 Output Enable
    .GPIO1_I  (GPIO1_I),  // GPIO1 Input
    .GPIO1_O  (GPIO1_O),  // GPIO1 Output
    .GPIO1_OE (GPIO1_OE), // GPIO1 Output Enable
    .GPIO2_I  (GPIO2_I),  // GPIO2 Input
    .GPIO2_O  (GPIO2_O),  // GPIO2 Output
    .GPIO2_OE (GPIO2_OE), // GPIO2 Output Enable
    .GPIO3_I  (GPIO3_I),  // GPIO3 Input
    .GPIO3_O  (GPIO3_O),  // GPIO3 Output
    .GPIO3_OE (GPIO3_OE), // GPIO3 Output Enable
    .GPIO4_I  (GPIO4_I),  // GPIO4 Input
    .GPIO4_O  (GPIO4_O),  // GPIO4 Output
    .GPIO4_OE (GPIO4_OE)  // GPIO4 Output Enable
);

//-------------------
// UART
//-------------------
UART U_UART 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_UART]),
    .S_HTRANS    (s_htrans   [`SLAVE_UART]),
    .S_HWRITE    (s_hwrite   [`SLAVE_UART]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_UART]),
    .S_HSIZE     (s_hsize    [`SLAVE_UART]),
    .S_HBURST    (s_hburst   [`SLAVE_UART]),
    .S_HPROT     (s_hprot    [`SLAVE_UART]),
    .S_HADDR     (s_haddr    [`SLAVE_UART]),
    .S_HWDATA    (s_hwdata   [`SLAVE_UART]),
    .S_HREADY    (s_hready   [`SLAVE_UART]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_UART]),
    .S_HRDATA    (s_hrdata   [`SLAVE_UART]),
    .S_HRESP     (s_hresp    [`SLAVE_UART]),
    // UART Port
    .RXD (RXD),
    .TXD (TXD),
    .CTS (cts),
    .RTS (rts),
    // Interrupt
    .IRQ_UART (irq_uart)
);

//--------------------
// INT_GEN
//--------------------
INT_GEN U_INT_GEN 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_INTGEN]),
    .S_HTRANS    (s_htrans   [`SLAVE_INTGEN]),
    .S_HWRITE    (s_hwrite   [`SLAVE_INTGEN]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_INTGEN]),
    .S_HSIZE     (s_hsize    [`SLAVE_INTGEN]),
    .S_HBURST    (s_hburst   [`SLAVE_INTGEN]),
    .S_HPROT     (s_hprot    [`SLAVE_INTGEN]),
    .S_HADDR     (s_haddr    [`SLAVE_INTGEN]),
    .S_HWDATA    (s_hwdata   [`SLAVE_INTGEN]),
    .S_HREADY    (s_hready   [`SLAVE_INTGEN]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_INTGEN]),
    .S_HRDATA    (s_hrdata   [`SLAVE_INTGEN]),
    .S_HRESP     (s_hresp    [`SLAVE_INTGEN]),
    // Interrupt Output
    .IRQ_EXT (irq_ext),
    .IRQ     (irq_gen)
);

//-------------------
// I2C0
//-------------------
I2C U_I2C0
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_I2C0]),
    .S_HTRANS    (s_htrans   [`SLAVE_I2C0]),
    .S_HWRITE    (s_hwrite   [`SLAVE_I2C0]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_I2C0]),
    .S_HSIZE     (s_hsize    [`SLAVE_I2C0]),
    .S_HBURST    (s_hburst   [`SLAVE_I2C0]),
    .S_HPROT     (s_hprot    [`SLAVE_I2C0]),
    .S_HADDR     (s_haddr    [`SLAVE_I2C0]),
    .S_HWDATA    (s_hwdata   [`SLAVE_I2C0]),
    .S_HREADY    (s_hready   [`SLAVE_I2C0]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_I2C0]),
    .S_HRDATA    (s_hrdata   [`SLAVE_I2C0]),
    .S_HRESP     (s_hresp    [`SLAVE_I2C0]),
    // I2C Port
    .I2C_SCL_I   (I2C0_SCL_I),   // SCL Input
    .I2C_SCL_O   (I2C0_SCL_O),   // SCL Output
    .I2C_SCL_OEN (I2C0_SCL_OEN), // SCL Output Enable (neg)
    .I2C_SDA_I   (I2C0_SDA_I),   // SDA Input
    .I2C_SDA_O   (I2C0_SDA_O),   // SDA Output
    .I2C_SDA_OEN (I2C0_SDA_OEN), // SDA Output Enable (neg)
    // Interrupt
    .IRQ_I2C (irq_i2c0)
);

//-------------------
// I2C1
//-------------------
I2C U_I2C1
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_I2C1]),
    .S_HTRANS    (s_htrans   [`SLAVE_I2C1]),
    .S_HWRITE    (s_hwrite   [`SLAVE_I2C1]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_I2C1]),
    .S_HSIZE     (s_hsize    [`SLAVE_I2C1]),
    .S_HBURST    (s_hburst   [`SLAVE_I2C1]),
    .S_HPROT     (s_hprot    [`SLAVE_I2C1]),
    .S_HADDR     (s_haddr    [`SLAVE_I2C1]),
    .S_HWDATA    (s_hwdata   [`SLAVE_I2C1]),
    .S_HREADY    (s_hready   [`SLAVE_I2C1]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_I2C1]),
    .S_HRDATA    (s_hrdata   [`SLAVE_I2C1]),
    .S_HRESP     (s_hresp    [`SLAVE_I2C1]),
    // I2C Port
    .I2C_SCL_I   (I2C1_SCL_I),   // SCL Input
    .I2C_SCL_O   (I2C1_SCL_O),   // SCL Output
    .I2C_SCL_OEN (I2C1_SCL_OEN), // SCL Output Enable (neg)
    .I2C_SDA_I   (I2C1_SDA_I),   // SDA Input
    .I2C_SDA_O   (I2C1_SDA_O),   // SDA Output
    .I2C_SDA_OEN (I2C1_SDA_OEN), // SDA Output Enable (neg)
    // Interrupt
    .IRQ_I2C (irq_i2c1)
);

//-------------------
// SPI
//-------------------
SPI U_SPI 
(
    // Global Signals
    .CLK  (clk),
    .RES  (res_sys),
    // Slave Ports
    .S_HSEL      (s_hsel     [`SLAVE_SPI]),
    .S_HTRANS    (s_htrans   [`SLAVE_SPI]),
    .S_HWRITE    (s_hwrite   [`SLAVE_SPI]),
    .S_HMASTLOCK (s_hmastlock[`SLAVE_SPI]),
    .S_HSIZE     (s_hsize    [`SLAVE_SPI]),
    .S_HBURST    (s_hburst   [`SLAVE_SPI]),
    .S_HPROT     (s_hprot    [`SLAVE_SPI]),
    .S_HADDR     (s_haddr    [`SLAVE_SPI]),
    .S_HWDATA    (s_hwdata   [`SLAVE_SPI]),
    .S_HREADY    (s_hready   [`SLAVE_SPI]),
    .S_HREADYOUT (s_hreadyout[`SLAVE_SPI]),
    .S_HRDATA    (s_hrdata   [`SLAVE_SPI]),
    .S_HRESP     (s_hresp    [`SLAVE_SPI]),
    // SPI Port
    .SPI_CSN   (SPI_CSN),  // SPI Chip Select
    .SPI_SCK   (SPI_SCK),  // SPI Clock
    .SPI_MOSI  (SPI_MOSI), // SPI MOSI
    .SPI_MISO  (SPI_MISO), // SPI MISO
    // Interrupt
    .IRQ_SPI (irq_spi)
);

//-----------------------------------------
// Interrupts
//-----------------------------------------
assign irq = irq_gen | 
    {
        58'h0,
        I2C0_INT2,
        I2C0_INT1,
        irq_spi,
        irq_i2c1,
        irq_i2c0,
        irq_uart
    };

//------------------------
// End of Module
//------------------------
endmodule

//===========================================================
// End of File
//===========================================================
