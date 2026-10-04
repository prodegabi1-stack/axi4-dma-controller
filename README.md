# AXI4 DMA Controller & Async FIFO

This repository contains an AXI4-based Direct Memory Access (DMA) controller implemented in SystemVerilog. The design executes burst-based memory-to-memory transfers and utilizes an asynchronous FIFO to handle data crossing between two different clock domains (Clock Domain Crossing).

## Key Features
* **AXI4 Master Interfaces:** Decoupled read and write modules that strictly adhere to the AXI4 VALID/READY handshaking protocol and support backpressure.
* **Dual-Clock Asynchronous FIFO:** Safe data crossing between the read and write clock domains using Gray-code pointers, preventing multi-bit glitches.
* **CDC Synchronization:** Metastability mitigation using 2-FF synchronizers constrained with Vivado `(* ASYNC_REG = "TRUE" *)` attributes.
* **Timing Constraints:** Included `.xdc` file that defines asynchronous clock groups, essential for correct timing analysis during synthesis and implementation.

## Repository Structure
* `SourceCode/` - Synthesizable RTL modules (DMA Top, AXI Masters, FIFO sub-modules).
* `Simulation/` - Verification environment, including `TB_DMA.sv` (generates dual-clock stimuli) and the simulated slave memory `axi_ram.sv`.
* `timing.xdc` - Clock constraints for Xilinx Vivado.

## Simulation
The project can be simulated using Vivado Simulator (or any other SystemVerilog-compatible simulator). The testbench instantiates two distinct clocks (100 MHz for the read channel, ~166 MHz for the write channel) and verifies data integrity after a complete burst transfer.

## Waveforms
Below is the behavior of the AXI masters and the data transfer across the asynchronous clock domains:

![Waveform 1](Waveform1.png)

![Waveform 2](Waveform2.png)
