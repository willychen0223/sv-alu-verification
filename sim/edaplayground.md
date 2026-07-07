# Simulation Instructions

This project was simulated using EDA Playground with a commercial SystemVerilog simulator.

## Recommended Settings

- Language: SystemVerilog
- Simulator: QuestaSim / Xcelium / Riviera-Pro
- Timescale: `1ns/1ns`

## Files

Place the files as follows:

- Design pane: `rtl/alu.sv`
- Testbench pane: `tb/tb_alu.sv`

## Expected Output

```text
PASS: ADD
PASS: SUB
PASS: INV
PASS: OR zero
PASS: OR nonzero
All directed tests completed.
