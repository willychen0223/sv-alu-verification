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

  function automatic logic signed [4:0] calc_expected(
    input logic signed [3:0] fa,
    input logic signed [3:0] fb,
    input logic        [1:0] fop
  );
    begin
      case (fop)
        2'b00: calc_expected = fa + fb;
        2'b01: calc_expected = fa - fb;
        2'b10: calc_expected = ~fa;
        2'b11: calc_expected = |fb;
        default: calc_expected = 5'sd0;
      endcase
    end
  endfunction

  task automatic scoreboard_check(
    input logic signed [3:0] checked_a,
    input logic signed [3:0] checked_b,
    input logic        [1:0] checked_op,
    input logic signed [4:0] expected,
    input logic signed [4:0] actual,
    input string             test_name
  );
    begin
      alu_cov.sample(checked_a, checked_b, checked_op, actual);

      if (actual !== expected) begin
        fail_count++;

        $display("FAIL: %s, a=%0d, b=%0d, op=%b, expected=%0d, actual=%0d",
                 test_name, checked_a, checked_b, checked_op, expected, actual);
      end else begin
        pass_count++;

        $display("PASS: %s, a=%0d, b=%0d, op=%b, result=%0d",
                 test_name, checked_a, checked_b, checked_op, actual);
      end
    end
  endtask

  task automatic apply_and_check(
    input logic signed [3:0] ta,
    input logic signed [3:0] tb,
    input logic        [1:0] top,
    input string             test_name
  );

    logic signed [4:0] expected;

    begin
      expected = calc_expected(ta, tb, top);

      @(posedge clk);
      a  = ta;
      b  = tb;
      op = top;

      @(posedge clk);
      #1;

      scoreboard_check(ta, tb, top, expected, c, test_name);
    end
  endtask

  initial begin
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
    apply_and_check(4'sd3,    4'sd2,   2'b00, "ADD");
    apply_and_check(4'sd3,    4'sd5,   2'b01, "SUB");
    apply_and_check(4'sb0011, 4'sd0,   2'b10, "INV");
    apply_and_check(4'sd0,    4'b0000, 2'b11, "OR zero");
    apply_and_check(4'sd0,    4'b0100, 2'b11, "OR nonzero");

    apply_and_check(4'sd7,    4'sd7,   2'b00, "ADD max positive");
    apply_and_check(-4'sd8,   4'sd7,   2'b01, "SUB negative edge");

    // Extra directed tests for coverage closure
    apply_and_check(4'sd0,    4'sd3,   2'b00, "ADD a zero");
    apply_and_check(4'sd0,    4'sd3,   2'b01, "SUB a zero");

    // Random tests
    for (int i = 0; i < 50; i++) begin
      logic signed [3:0] rand_a;
      logic signed [3:0] rand_b;
      logic        [1:0] rand_op;

      rand_a  = $urandom_range(0, 15);
      rand_b  = $urandom_range(0, 15);
      rand_op = $urandom_range(0, 3);

      apply_and_check(rand_a, rand_b, rand_op, $sformatf("RANDOM_%0d", i));
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
