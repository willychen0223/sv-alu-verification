# SystemVerilog ALU Verification

A beginner-friendly SystemVerilog verification project for a small clocked ALU.

This project started from a simple directed testbench and is gradually evolving toward a UVM-like verification structure.

The main goal is to practice digital verification concepts step by step, including:

- SystemVerilog testbench basics
- Clock and reset generation
- Directed testing
- Reusable tasks
- Automatic PASS/FAIL checking
- Transaction-based verification
- Random stimulus generation
- Scoreboard-style checking
- Assertions
- Functional coverage
- UVM-style testbench architecture

---

## DUT: ALU

The DUT is a small clocked ALU with:

- Two 4-bit signed inputs: `a`, `b`
- One 2-bit opcode input: `op`
- One 5-bit signed registered output: `c`
- Active-low asynchronous reset: `rst_n`

### Opcode Table

| Opcode | Operation | Description |
|---|---|---|
| `2'b00` | `a + b` | Signed addition |
| `2'b01` | `a - b` | Signed subtraction |
| `2'b10` | `~a` | Bitwise invert of `a` |
| `2'b11` | `\|b` | Reduction OR of `b` |

---

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
```

---

## Progress

- [x] Create ALU RTL
- [x] Create a basic directed testbench
- [x] Generate clock and reset
- [x] Add automatic PASS/FAIL checking
- [x] Refactor repeated directed tests into a reusable task
- [x] Add expected-result calculation
- [x] Add transaction class
- [x] Add driver-like task
- [x] Add monitor-like task
- [x] Add scoreboard-like task
- [x] Add random stimulus using class randomization
- [x] Add basic SystemVerilog assertions
- [x] Add functional coverage
- [x] Achieve 100% functional coverage
- [ ] Add generator and mailbox
- [ ] Add SystemVerilog interface
- [ ] Refactor toward a more complete UVM-style structure
- [ ] Build a FIFO verification project

---

## Day 4 Update: Reusable Task

The original testbench repeated the same drive-and-check sequence for every directed test.

In Day 4, the repeated code was refactored into a reusable task called `apply_and_check()`.

This made the testbench cleaner, easier to read, and easier to extend.

Example:

```systemverilog
task automatic apply_and_check(
  input logic signed [3:0] ta,
  input logic signed [3:0] tb,
  input logic        [1:0] top,
  input logic signed [4:0] expected,
  input string             test_name
);
```

---

## Day 11 Update: Transaction-Based UVM-like Testbench

In Day 11, the testbench was upgraded from a simple directed testbench into a more structured transaction-based verification environment.

The ALU is still simple, but the purpose of this version is to practice the architecture used in real digital verification.

### Key Idea

Instead of directly driving signals and checking outputs in one place, the testbench now uses a transaction object to represent one ALU test item.

Each transaction stores:

- Input stimulus: `a`, `b`, `op`
- Expected result: `expected`
- Actual DUT result: `actual`
- Test name: `name`

This makes the testbench easier to organize and closer to a UVM-style structure.

---

## Transaction Class

The `alu_transaction` class represents one ALU test item.

```systemverilog
class alu_transaction;

  rand logic signed [3:0] a;
  rand logic signed [3:0] b;
  rand logic        [1:0] op;

  logic signed [4:0] expected;
  logic signed [4:0] actual;
  string name;

  function new(string name = "unnamed");
    this.name = name;
  endfunction

  function void calc_expected();
    case (op)
      2'b00: expected = a + b;
      2'b01: expected = a - b;
      2'b10: expected = ~a;
      2'b11: expected = |b;
      default: expected = 5'sd0;
    endcase
  endfunction

endclass
```

### What this class does

The class acts like a test item template.

Each object created from this class is one ALU test transaction.

Example:

```systemverilog
alu_transaction tr;

tr = new("ADD");
tr.a  = 4'sd3;
tr.b  = 4'sd2;
tr.op = 2'b00;
```

This creates one transaction named `ADD`.

---

## Directed Tests

Directed tests are manually specified test cases.

Example:

```systemverilog
run_directed_test(4'sd3, 4'sd2, 2'b00, "ADD");
```

This creates one transaction with:

- `a = 3`
- `b = 2`
- `op = 2'b00`
- Test name = `ADD`

The transaction is then passed into the main transaction flow.

---

## Random Tests

Random tests use SystemVerilog class randomization.

The randomized fields are:

```systemverilog
rand logic signed [3:0] a;
rand logic signed [3:0] b;
rand logic        [1:0] op;
```

Random test loop:

```systemverilog
for (int i = 0; i < 50; i++) begin
  alu_transaction tr;

  tr = new($sformatf("RANDOM_%0d", i));

  if (!tr.randomize()) begin
    $fatal(1, "Randomization failed");
  end

  run_transaction(tr);
end
```

This automatically creates 50 random ALU transactions.

For example:

```text
RANDOM_0
RANDOM_1
RANDOM_2
...
RANDOM_49
```

Each random transaction gets randomized values for `a`, `b`, and `op`.

---

## Main Transaction Flow

The main transaction flow is handled by `run_transaction()`.

```systemverilog
task automatic run_transaction(
  input alu_transaction tr
);
  begin
    tr.calc_expected();

    driver_task(tr);
    monitor_task(tr);
    scoreboard_check(tr);
  end
endtask
```

The flow is:

```text
Create transaction
↓
Calculate expected result
↓
Driver sends a/b/op to DUT
↓
Monitor samples DUT output
↓
Scoreboard compares expected vs actual
↓
Coverage records the test scenario
```

---

## Driver-like Task

The driver task sends transaction data to the DUT inputs.

```systemverilog
task automatic driver_task(
  input alu_transaction tr
);
  begin
    @(posedge clk);
    a  = tr.a;
    b  = tr.b;
    op = tr.op;
  end
endtask
```

The driver reads:

```text
tr.a
tr.b
tr.op
```

and drives them into the DUT input signals.

---

## Monitor-like Task

The monitor task samples the DUT output and stores it back into the transaction.

```systemverilog
task automatic monitor_task(
  input alu_transaction tr
);
  begin
    @(posedge clk);
    #1;
    tr.actual = c;
  end
endtask
```

The `#1` delay lets the DUT output update before the monitor samples `c`.

---

## Scoreboard-like Task

The scoreboard compares the DUT result against the expected result.

```systemverilog
if (tr.actual !== tr.expected) begin
  fail_count++;
end else begin
  pass_count++;
end
```

This is the automatic PASS/FAIL checking mechanism.

The scoreboard checks:

```text
expected result from testbench
vs.
actual result from DUT
```

---

## Assertions

Basic assertions were added to check important design rules.

The assertions check:

- During reset, `c` must be zero.
- `rst_n` must not be X/Z.
- During normal operation, `op` must not be X/Z.
- During normal operation, `c` must not be X/Z.

Example:

```systemverilog
property p_reset_c_zero;
  @(posedge clk)
    (!rst_n) |-> (c == 5'sd0);
endproperty

assert property (p_reset_c_zero)
  else $error("ASSERTION FAILED: c is not zero during reset");
```

---

## Functional Coverage

Functional coverage was added to measure whether important scenarios were tested.

The covergroup checks:

- All ALU operations
- `a` negative / zero / positive
- `b` negative / zero / positive
- Result negative / zero / positive
- Cross coverage between operation and `a`

Example:

```systemverilog
cp_op: coverpoint sampled_op {
  bins add    = {2'b00};
  bins sub    = {2'b01};
  bins inv    = {2'b10};
  bins red_or = {2'b11};
}
```

Coverage is sampled in the scoreboard:

```systemverilog
alu_cov.sample(tr.a, tr.b, tr.op, tr.actual);
```

---

## UVM-style Mapping

This testbench is not full UVM yet, but it is intentionally structured to look like a simplified UVM environment.

| Current Testbench | UVM Concept |
|---|---|
| `alu_transaction` | sequence item / transaction |
| `run_directed_test()` | simple sequence-like stimulus |
| `driver_task()` | driver |
| `monitor_task()` | monitor |
| `scoreboard_check()` | scoreboard |
| `covergroup` | coverage collector |
| `run_transaction()` | simplified transaction flow |

The purpose is to understand the core ideas before moving into full UVM.

---

## Simulation Result

The testbench was run using Synopsys VCS on EDA Playground.

Final result:

```text
PASS count = 65
FAIL count = 0
Functional coverage = 100.00%
ALL TESTS PASSED
```

The 65 tests include:

- 15 directed tests
- 50 randomized tests

---

## What I Learned

Through this update, I learned:

- How to use a SystemVerilog class to represent one transaction
- The meaning of class, object, handle, constructor, `new()`, and `this`
- How `tr.randomize()` generates random stimulus
- How directed tests and random tests differ
- How to split a testbench into driver, monitor, and scoreboard roles
- How to use a scoreboard for automatic checking
- How to use assertions for rule checking
- How to use functional coverage to measure test completeness
- How this structure connects to future UVM learning

---

## Next Steps

Planned next steps:

1. Add a generator and mailbox to separate stimulus generation from driving.
2. Add a SystemVerilog interface to group DUT signals.
3. Refactor the testbench toward a more UVM-like structure.
4. Build a FIFO verification project using the same methodology.
