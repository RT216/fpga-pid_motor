# FPGA-Based PID Motor Controller

[English](README.md) | [中文](README_zh.md)

## Project Overview

This project implements a PID (Proportional-Integral-Derivative) controller for precise motor speed regulation on an FPGA. It's designed as a subsystem for an autonomous robot car, ensuring smooth and accurate vehicle movement by maintaining consistent motor speeds across all four wheels.

## Key Features

- Closed-loop PID control system for motor speed regulation
- Configurable PID parameters
- FPGA implementation for high-speed, real-time control
- Support for four independent motors
- PWM signal generation for motor control
- UART communication for receiving target RPM values
- Support for braking while avoiding wheel lock during steering
- Real-time RPM reading from motor encoders and friction factor calculation

## Hardware Requirements

- FPGA Board: Sipeed FPGA 
    - I used Tang Primer 25k, other modules should also work
- Motor Driver PCB (custom design, not included in this repository)
- Motor Driver IC: AT8236 (4x)
    - [Datasheet for AT8236 in Chinese](https://www.lcsc.com/datasheet/lcsc_datasheet_2109242230_ZHONGKEWEI-AT8236_C2827823.pdf)
    - You may need to modify the design for other drivers
- DC Motors with Encoders (4x)

## Software Requirements

- Gowin EDA (for synthesis and implementation)
- MATLAB (for PID coefficient simulation and tuning)

## Project Structure

The project consists of several Verilog modules and utility tools:

### Verilog Modules

1. `top.v`: The top-level module that integrates all submodules.

2. `pid_input_processor.v`: Handles input processing for the PID controller.

3. `pid_output_processor.v`: Converts PID output to PWM signals for motor control.

4. `rpm_reader.v`: Reads and processes encoder signals to calculate motor RPM.

5. `uart_recv.v`: Receives commands and target RPM values via UART.

6. `uart_controller.v`: Decodes received UART data into control signals.

7. `uart_send.v`: Sends data back via UART (for debugging or monitoring).

8. `uart_driver.v`: Handles UART communication for sending friction factor data.

9. `signed_divider.v`: Performs signed division operations.

### Tools Directory

The `tools/` directory contains utility scripts to assist with development and testing:

1. `fixedPointToDecimal.m` (MATLAB): Converts fixed-point numbers to decimal representation.

2. `pid_sim.m` (MATLAB): Simulates the PID controller with given parameters.

3. `uart_cmd_gen.cpp` (C++): Generates UART commands for setting target RPM values.

## PID Controller

The core PID controller is implemented using Gowin's PID Controller 3p3z IP. It uses a three-zero, three-pole digital discrete-time system, optimized to minimize steady-state error, ripple, and overshoot. The PID computation rate is set to 1.2 kHz to avoid potential ringing effects.

## Usage

1. Clone the repository:
    ```bash
    git clone https://github.com/RT216/fpga-pid_motor
    ```
2. Open the project in Gowin EDA.
3. Synthesize and implement the design.
4. Program the FPGA with the generated bitstream.
5. Connect the FPGA to your motor driver PCB and motors.
6. Use UART to send target RPM values to the system.
    - Setting the RPM of all 4 motors to 0 is a brake command. Setting only a few to 0 will not cause a brake.

### UART Protocol

The UART receiver uses a simple command format:
1. Set RPM command: `0x91`
2. High 5 bits: `{3'b[channel_number], 5'b[rpm_high_bits]}`
3. Low 8 bits: `8'b[rpm_low_bits]`
4. Return command: `0xFF`

### Tools

The `tools/` directory contains several utility scripts to assist with development and testing:

1. `fixedPointToDecimal.m` (MATLAB)

    This script is particularly useful for interpreting the PID controller parameters, which are configured as fixed-point numbers in the Verilog code. It helps in easily reading and understanding the actual values of these parameters.

2. `pid_sim.m` (MATLAB)
	
    Use this script to test and tune PID parameters before implementing them in the FPGA. It provides a quick way to visualize the system's response and stability.

3.	`uart_cmd_gen.cpp` (C++)
	
    Compile and run this program to quickly generate the correct UART commands for setting desired RPM values for each motor. It formats the commands according to the protocol used by the FPGA implementation.

## Acknowledgments
This project uses the Gowin PID Controller 3p3z IP. For more information, refer to:
- Gowin PID Controller 3p3z IP User Guide, Gowin Semiconductor Co., Version 1.0, Feb. 22, 2023. [Online]. Available: [https://www.gowinsemi.com/en/support/ip_detail/113/](https://www.gowinsemi.com/en/support/ip_detail/113/)