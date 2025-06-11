## How it works
The chip being manufactured by this shuttle is the MCS-4 i4004-compatible CPU chip .<br>
Using this chip, I aim to recreate the historic calculator Busicom 141-PF. <br>
Except for the i4004 (CPU), the i4001 (ROM), i4002 (RAM), i4003 (Shifter), and the 141-PF calculator hardware, including user interface components such as the keyboard and printer, are integrated into an Altera FPGA.<br>
<br>
Additionally, the FPGA includes a fully expanded ROM/RAM system, allowing the i4004 to compute the first 500 digits of π (pi)!

## How to test
To test the RTL, I have created the testbench which consists of...<br>
(1) CPU Chip (i4004) :  src/tt_um_munetomomaruyama_CPU.v<br>
(2) MCS-4's System (i4001, i4002, i4403 and 141-PF Calculator Hardware) : mcs4_system/RTL/MCS4/*.v<br>
(3) Testbanch for iverilog : mcs_system/SIM_iverilog (to test the MCS-4 system and the Printer hardware)<br>
(4) Testbanch for Questa : mcs_system/SIM_questa (to test whole system including the FPGA with user interface supported by RISC-V CPU which is created by myself: mmRISC-1)<br>

## External hardware
The extenal FPGA includes following items.<br>
- ROM i4001 x 16 chips (reprogrammable by using Altera Quartus In-System Memory Content Editor) <br>
- RAM i4002 x 32 chips<br>
- Shifter i4003 x 3 chips<br>
- Calculator Interface Hardware <br>
- RISC-V System for Calculator User Interface (Key Board and Printer) <br> 
