# SAR ADC Implementation for FPGA
Source code for the thesis `An FPGA-based 16-bit 48 kS/s SAR ADC
for Audio Applications`
## Introduction
Implementation of a SAR ADC with an integrated Delta-Sigma DAC for FPGA applications, targeting 7-Series Xilinx FPGAs. The goal is to require minimal external components while providing high SNR.
## Dependencies
This project makes use of [sv-ethernet](https://github.com/manaljosid/sv-ethernet), [sv-axis](https://github.com/manaljosid/sv-axis) and [sv-axil](https://github.com/manaljosid/sv-axil), which in turn use code from [Alex Forencich](https://github.com/alexforencich).
## Testing
Testing makes use of [VUnit](https://github.com/VUnit/vunit) and Modelsim in conjunction with Python code to process data from testbenches. Running the scripts inside `python/tb` will run simulations for their respective modules. Note that to get a GUI to appear the argument `-g` needs to be used.
## Vivado
A TCL script is provided under `workspace/vivado/scripts/` to generate a Vivado project for synthesis.
*Note that the code has only been simulated and no guarantee is that it is synthesizable.*