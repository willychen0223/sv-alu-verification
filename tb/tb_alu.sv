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


module tb;

  logic clk;
  logic rst_n;
  logic signed [3:0] a;
  logic signed [3:0] b;
  logic [1:0] op;
  logic signed [4:0] c;

  int pass_count;
  int fail_count;

  alu dut (
    .clk   (clk),
    .rst_n (rst_n),
    .a     (a),
    .b     (b),
    .op    (op),
    .c     (c)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // ------------------------------------------------------------
  // Assertions
  // ------------------------------------------------------------

  property p_reset_c_zero;
    @(posedge clk)
      (!rst_n) |-> (c == 5'sd0);
  endproperty

  assert property (p_reset_c_zero)
    else $error("ASSERTION FAILED: c is not zero during reset");

  property p_reset_known;
    @(posedge clk)
      !$isunknown(rst_n);
  endproperty

  assert property (p_reset_known)
    else $error("ASSERTION FAILED: rst_n is X or Z");

  property p_op_known;
    @(posedge clk)
      rst_n |-> !$isunknown(op);
  endproperty

  assert property (p_op_known)
    else $error("ASSERTION FAILED: op is X or Z during normal operation");

  property p_c_known;
    @(posedge clk)
      rst_n |-> !$isunknown(c);
  endproperty

  assert property (p_c_known)
    else $error("ASSERTION FAILED: c is X or Z during normal operation");

  // ------------------------------------------------------------
  // Functional Coverage
  // ------------------------------------------------------------

  covergroup alu_cov_cg with function sample(
    input logic signed [3:0] sampled_a,
    input logic signed [3:0] sampled_b,
    input logic        [1:0] sampled_op,
    input logic signed [4:0] sampled_result
  );

    option.per_instance = 1;

    cp_op: coverpoint sampled_op {
      bins add    = {2'b00};
      bins sub    = {2'b01};
      bins inv    = {2'b10};
      bins red_or = {2'b11};
    }

    cp_a: coverpoint sampled_a {
      bins negative = {[-8:-1]};
      bins zero     = {0};
      bins positive = {[1:7]};
    }

    cp_b: coverpoint sampled_b {
      bins negative = {[-8:-1]};
      bins zero     = {0};
      bins positive = {[1:7]};
    }

    cp_result: coverpoint sampled_result {
      bins negative = {[-16:-1]};
      bins zero     = {0};
      bins positive = {[1:15]};
    }

    cross_op_a: cross cp_op, cp_a;

  endgroup

  alu_cov_cg alu_cov;

  // ------------------------------------------------------------
  // Driver-like task
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // Monitor-like task
  // ------------------------------------------------------------

  task automatic monitor_task(
    input alu_transaction tr
  );
    begin
      @(posedge clk);
      #1;
      tr.actual = c;
    end
  endtask

  // ------------------------------------------------------------
  // Scoreboard-like task
  // ------------------------------------------------------------

  task automatic scoreboard_check(
    input alu_transaction tr
  );
    begin
      alu_cov.sample(tr.a, tr.b, tr.op, tr.actual);

      if (tr.actual !== tr.expected) begin
        fail_count++;

        $display("FAIL: %s, a=%0d, b=%0d, op=%b, expected=%0d, actual=%0d",
                 tr.name, tr.a, tr.b, tr.op, tr.expected, tr.actual);
      end else begin
        pass_count++;

        $display("PASS: %s, a=%0d, b=%0d, op=%b, result=%0d",
                 tr.name, tr.a, tr.b, tr.op, tr.actual);
      end
    end
  endtask

  // ------------------------------------------------------------
  // Main transaction flow
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // Helper task for directed tests
  // ------------------------------------------------------------

  task automatic run_directed_test(
    input logic signed [3:0] test_a,
    input logic signed [3:0] test_b,
    input logic        [1:0] test_op,
    input string             test_name
  );

    alu_transaction tr;

    begin
      tr = new(test_name);
      tr.a  = test_a;
      tr.b  = test_b;
      tr.op = test_op;

      run_transaction(tr);
    end
  endtask

  // ------------------------------------------------------------
  // Main test
  // ------------------------------------------------------------

  initial begin
    alu_transaction tr;

    $dumpfile("wave.vcd");
    $dumpvars(0, tb);

    alu_cov = new();

    pass_count = 0;
    fail_count = 0;

    rst_n = 0;
    a = 0;
    b = 0;
    op = 0;

    repeat (2) @(posedge clk);
    rst_n = 1;

    // Directed tests
    run_directed_test(4'sd3,    4'sd2,   2'b00, "ADD");
    run_directed_test(4'sd3,    4'sd5,   2'b01, "SUB");
    run_directed_test(4'sb0011, 4'sd0,   2'b10, "INV");
    run_directed_test(4'sd0,    4'b0000, 2'b11, "OR zero");
    run_directed_test(4'sd0,    4'b0100, 2'b11, "OR nonzero");

    run_directed_test(4'sd7,    4'sd7,   2'b00, "ADD max positive");
    run_directed_test(-4'sd8,   4'sd7,   2'b01, "SUB negative edge");

    // Extra directed tests for coverage closure
    run_directed_test(4'sd0,    4'sd3,   2'b00, "ADD a zero");
    run_directed_test(4'sd0,    4'sd3,   2'b01, "SUB a zero");

    run_directed_test(-4'sd1,   4'sd3,   2'b00, "ADD a negative");
    run_directed_test(4'sd3,   -4'sd1,   2'b00, "ADD b negative");

    run_directed_test(4'sd0,    4'sd0,   2'b10, "INV a zero");
    run_directed_test(-4'sd1,   4'sd0,   2'b10, "INV a negative");

    run_directed_test(4'sd2,    4'sd1,   2'b11, "OR a positive");
    run_directed_test(-4'sd2,   4'sd1,   2'b11, "OR a negative");

    // Random tests using class randomization
    for (int i = 0; i < 50; i++) begin
      tr = new($sformatf("RANDOM_%0d", i));

      if (!tr.randomize()) begin
        $fatal(1, "Randomization failed");
      end

      run_transaction(tr);
    end

    $display("----------------------------------------");
    $display("Simulation completed.");
    $display("PASS count = %0d", pass_count);
    $display("FAIL count = %0d", fail_count);
    $display("Functional coverage = %0.2f%%", alu_cov.get_inst_coverage());
    $display("----------------------------------------");

    if (fail_count == 0)
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED");

    $finish;
  end

endmodule
