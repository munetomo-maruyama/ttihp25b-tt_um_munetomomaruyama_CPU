## How it works
MCS-4 i4004 CPU Compatible Chip

## How to test
To test the RTL, I have created the testbench consists of...<br>
(1) CPU Chip (i4004) :  src/tt_um_munetomomaruyama_CPU.v<br>
(2) MCS-4's Memory System (i4001, i4002) : test/mcs4_system/mcs4_mem.v (includes mcs4_rom.v and mcs4_ram.v)<br>
(3) 141-PF Caluculator Harware Model (i4003) : test/mcs4_system/key_printer.v (includes mcs4_shifter.v)<br>

## External hardware
FPGA system is prepared.<br>
