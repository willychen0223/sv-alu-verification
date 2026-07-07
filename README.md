# SystemVerilog ALU Verification

A beginner-friendly SystemVerilog verification project for a small clocked ALU.  
This project demonstrates a simple directed testbench with automatic PASS/FAIL checking.

## Day 4 Update: Reusable Task

The original testbench repeated the same drive-and-check sequence for every directed test.

In this version, the repeated code was refactored into a reusable task called `apply_and_check()`.

This makes the testbench cleaner, easier to read, and easier to extend.

```systemverilog
task automatic apply_and_check(
  input logic signed [3:0] ta,
  input logic signed [3:0] tb,
  input logic        [1:0] top,
  input logic signed [4:0] expected,
  input string             test_name
);
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
| `2'b11` | `\|b` | Reduction OR of `b` |

## Directed Test Cases

| Test Name | Input | Opcode | Expected Output |
|---|---|---|---|
| ADD | `3 + 2` | `2'b00` | `5` |
| SUB | `3 - 5` | `2'b01` | `-2` |
| INV | `~4'b0011` | `2'b10` | `5'b11100` |
| OR zero | `\|4'b0000` | `2'b11` | `0` |
| OR nonzero | `\|4'b0100` | `2'b11` | `1` |
| ADD max positive | `7 + 7` | `2'b00` | `14` |
| SUB negative edge | `-8 - 7` | `2'b01` | `-15` |


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

---


## Progress

- [x] Create ALU RTL
- [x] Create basic directed testbench
- [x] Run simulation on a commercial SystemVerilog simulator
- [x] Refactor repeated directed tests into a reusable task
- [ ] Add an expected-result function
- [ ] Add random stimulus
- [ ] Add a simple scoreboard
- [ ] Add functional coverage
- [ ] Convert the project into a basic UVM-style testbench