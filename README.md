# SystemVerilog ALU Verification

A beginner-friendly SystemVerilog verification project for a small clocked ALU.  
This project demonstrates a simple directed testbench with automatic PASS/FAIL checking.

## Project Goal

The goal of this project is to practice basic digital verification concepts:

- Writing a simple RTL design
- Creating a SystemVerilog testbench
- Generating clock and reset
- Driving input stimulus
- Checking DUT output automatically
- Reading simulation logs
- Preparing for more advanced verification topics such as tasks, random testing, scoreboards, and UVM

## DUT: ALU

The DUT is a small clocked ALU with:

- Two 4-bit signed inputs: `a`, `b`
- One 2-bit opcode input: `op`
- One 5-bit signed registered output: `c`
- Active-low asynchronous reset: `rst_n`

## Opcode Table

| Opcode | Operation | Description |
|---|---|---|
| `2'b00` | `a + b` | Signed addition |
| `2'b01` | `a - b` | Signed subtraction |
| `2'b10` | `~a` | Bitwise invert of `a` |
| `2'b11` | `|b` | Reduction OR of `b` |

## File Structure

```text
sv-alu-verification/
├── rtl/
│   └── alu.sv
├── tb/
│   └── tb_alu.sv
├── sim/
│   └── edaplayground.md
└── README.md
