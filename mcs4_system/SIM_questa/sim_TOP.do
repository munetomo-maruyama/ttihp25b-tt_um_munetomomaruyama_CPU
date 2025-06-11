# Convert hex to memh
exec ../SOFTWARE/tools/hex2mif32.exe ../SOFTWARE/workspace/MCS4_141PF/Debug/MCS4_141PF.hex > RAM128KB_DP.mif

# Directory
set DIR_RTL_MCS4_CPU ../../src
set DIR_RTL_MCS4_SYS ../RTL/MCS4
set DIR_RTL_TOP      ../RTL/FPGA_TOP
set DIR_RTL_RISCV    ../RTL/RISCV
set DIR_FPGA         ../FPGA
set DIR_RTL_TB       ../SIM_questa

vlib work
vmap work work

vlog \
    -work work \
    -sv \
    +incdir+$DIR_RTL_RISCV/common                    \
    +incdir+$DIR_RTL_RISCV/ahb_sdram/model           \
    +incdir+$DIR_RTL_RISCV/i2c/i2c/trunk/rtl/verilog \
    -timescale=1ns/100ps \
    +define+SIMULATION   \
    +define+FPGA         \
    +define+den512Mb     \
    +define+sg75         \
    +define+x16          \
    $DIR_RTL_MCS4_CPU/tt_um_munetomomaruyama_CPU.v \
    $DIR_RTL_MCS4_SYS/mcs4_cpu_chip.v \
    $DIR_RTL_MCS4_SYS/mcs4_cpu_core.v \
    $DIR_RTL_MCS4_SYS/mcs4_sys.v      \
    $DIR_RTL_MCS4_SYS/mcs4_rom_fpga.v \
    $DIR_FPGA/ROM4KB_SP.v             \
    $DIR_RTL_MCS4_SYS/mcs4_ram.v      \
    $DIR_RTL_MCS4_SYS/key_printer.v   \
    $DIR_RTL_MCS4_SYS/mcs4_shifter.v  \
    $DIR_RTL_RISCV/mmRISC/mmRISC.v    \
    $DIR_RTL_RISCV/mmRISC/bus_m_ahb.v \
    $DIR_RTL_RISCV/mmRISC/csr_mtime.v \
    $DIR_RTL_RISCV/cpu/cpu_top.v      \
    $DIR_RTL_RISCV/cpu/cpu_fetch.v    \
    $DIR_RTL_RISCV/cpu/cpu_datapath.v \
    $DIR_RTL_RISCV/cpu/cpu_pipeline.v \
    $DIR_RTL_RISCV/cpu/cpu_fpu32.v    \
    $DIR_RTL_RISCV/cpu/cpu_csr.v      \
    $DIR_RTL_RISCV/cpu/cpu_csr_int.v  \
    $DIR_RTL_RISCV/cpu/cpu_csr_dbg.v  \
    $DIR_RTL_RISCV/cpu/cpu_debug.v    \
    $DIR_RTL_RISCV/debug/debug_top.v  \
    $DIR_RTL_RISCV/debug/debug_dtm_jtag.v \
    $DIR_RTL_RISCV/debug/debug_cdc.v  \
    $DIR_RTL_RISCV/debug/debug_dm.v   \
    $DIR_RTL_RISCV/int_gen/int_gen.v  \
    $DIR_RTL_RISCV/ahb_matrix/ahb_top.v          \
    $DIR_RTL_RISCV/ahb_matrix/ahb_master_port.v  \
    $DIR_RTL_RISCV/ahb_matrix/ahb_slave_port.v   \
    $DIR_RTL_RISCV/ahb_matrix/ahb_interconnect.v \
    $DIR_RTL_RISCV/ahb_matrix/ahb_arb.v          \
    $DIR_RTL_RISCV/ahb_sdram/logic/ahb_lite_sdram.v \
    $DIR_RTL_RISCV/ahb_sdram/model/sdr.v            \
    $DIR_RTL_RISCV/ram/ram.v      \
    $DIR_RTL_RISCV/ram/ram_fpga.v \
    $DIR_FPGA/RAM128KB_DP.v       \
    $DIR_RTL_RISCV/port/port.v    \
    $DIR_RTL_RISCV/uart/uart.v                              \
    $DIR_RTL_RISCV/uart/sasc/trunk/rtl/verilog/sasc_top.v   \
    $DIR_RTL_RISCV/uart/sasc/trunk/rtl/verilog/sasc_fifo4.v \
    $DIR_RTL_RISCV/uart/sasc/trunk/rtl/verilog/sasc_brg.v   \
    $DIR_RTL_RISCV/i2c/i2c.v                                         \
    $DIR_RTL_RISCV/i2c/i2c/trunk/rtl/verilog/i2c_master_top.v        \
    $DIR_RTL_RISCV/i2c/i2c/trunk/rtl/verilog/i2c_master_bit_ctrl.v   \
    $DIR_RTL_RISCV/i2c/i2c/trunk/rtl/verilog/i2c_master_byte_ctrl.v  \
    $DIR_RTL_RISCV/i2c/i2c_slave_model.v                             \
    $DIR_RTL_RISCV/spi/spi.v                                         \
    $DIR_RTL_RISCV/spi/simple_spi/trunk/rtl/verilog/simple_spi_top.v \
    $DIR_RTL_RISCV/spi/simple_spi/trunk/rtl/verilog/fifo4.v          \
    $DIR_RTL_RISCV/riscv_top/riscv_top.v  \
    $DIR_RTL_TOP/fpga_top.v  \
    $DIR_FPGA/PLL.v          \
    $DIR_RTL_TB/tb_TOP.v

vsim -c -voptargs="+acc" \
    -L altera_mf_ver \
    work.tb_TOP

# TestBench
add wave -divider TestBench
add wave -position end  sim:/tb_TOP/tb_clk
add wave -position end  sim:/tb_TOP/tb_res
add wave -position end  sim:/tb_TOP/tb_cyc

# Clock and Reset
add wave -divider TestBench
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/clk
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/clk_mcs4
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/por_n
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/locked
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/res_org
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/res_sys

# MCS4
add wave -divider MCS4
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/CLK
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/RES_N
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/SYNC_N
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/DATA
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/CM_ROM_N
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/CM_RAM_N
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/TEST

# 141-PF
add wave -divider 141-PF
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/PORT_KEYPRT_CMD
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/PORT_KEYPRT_RES
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/CLK
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/RES_N
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/ENABLE
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/TEST
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_IN_ROM_CHIP7_CHIP0
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_IN_ROM_CHIPF_CHIP8
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_OUT_ROM_CHIP7_CHIP0
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_OUT_ROM_CHIPF_CHIP8
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_OUT_RAM_BANK1_BANK0
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_OUT_RAM_BANK3_BANK2
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_OUT_RAM_BANK5_BANK4
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_OUT_RAM_BANK7_BANK6
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_KEYPRT_CMD
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/PORT_KEYPRT_RES
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/sck_key
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/sck_prt
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/sdi_common
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/sft_cascade
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/key_column
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_column
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_q0
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_q1
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_hammer
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/key_row
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_clkcnt
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_tick
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_tick_count
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_drum_row_each
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_drum_row_first
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_drum_row_last
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_drum_count
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_color
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_paper_feed
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_color_delay
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_hammer_delay
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_paper_feed_delay
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_paper_feed_req
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_pop
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_pop_sync
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_wdata
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_rdata
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_we
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_re
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_wp
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_rp
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_dc
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_full
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/prt_fifo_empty
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/lamp_minus
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/lamp_overflow
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_MCS4_SYS/KEY_PRINTER/lamp_memory

# GPIO
add wave -divider GPIO
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/GPIO0
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/GPIO1
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/GPIO2
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/gpio3_i
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/gpio3_o
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/gpio3_oe
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/gpio4_i
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/gpio4_o
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/gpio4_oe

# RISC-V
add wave -divider RISC-V
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/RES_ORG
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/RES_SYS
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/CLK
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/slot
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/stall
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/state_id_ope
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/state_id_seq
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_enable
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_pc
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/U_MMRISC/U_CPU_TOP[0]/U_CPU_TOP/U_CPU_PIPELINE/pipe_id_code
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpui_m_hsel
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpui_m_htrans
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpui_m_hwrite
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpui_m_hsize
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpui_m_haddr
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpui_m_hwdata
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpui_m_hrdata
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpui_m_hreadyout
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpud_m_hsel
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpud_m_htrans
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpud_m_hwrite
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpud_m_hsize
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpud_m_haddr
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpud_m_hwdata
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpud_m_hrdata
add wave -position end  sim:/tb_TOP/U_FPGA_TOP/U_RISCV_TOP/cpud_m_hreadyout

# Do Simulation with logging all signals in WLF file
log -r *
run -all

