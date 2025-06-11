## How it works
The chip being manufactured by this shuttle is the MCS-4 i4004-compatible CPU chip .<br>
Using this chip, I aim to recreate the historic calculator Busicom 141-PF. <br>
Except for the i4004 (CPU), the i4001 (ROM), i4002 (RAM), i4003 (Shifter), and the 141-PF calculator hardware, including user interface components such as the keyboard and printer, are integrated into an FPGA.<br>
<br>
In addition, the FPGA will have full-expanded ROM/RAM system, and the i4004 will calculate the first 500 digits of π (pi)!

## How to test
To test the RTL, I have created the testbench which consists of...<br>
(1) CPU Chip (i4004) :  src/tt_um_munetomomaruyama_CPU.v<br>
(2) MCS-4's System (i4001, i4002, i4403 and 141-PF Calculator Hardware) : mcs4_system/RTL/MCS4/*.v<br>
(3) Testbanch for iverilog : mcs_system/SIM_iverilog (to test MCS-4 system and Printer hardware)<br>
(4) Testbanch for Questa : mcs_system/SIM_questa (to test user interface supported by RISC-V CPU which is created by myself: mmRISC-1)<br>

## External hardware
FPGA system will be prepared.<br>
