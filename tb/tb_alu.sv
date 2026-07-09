class alu_transaction; //設計圖 模板

//資料 
  rand logic signed [3:0] a;
  rand logic signed [3:0] b;
  rand logic        [1:0] op;

  logic signed [4:0] expected;
  logic signed [4:0] actual;
  string name;

//Constructor建構子
  function new(string name = "unnamed");
    this.name = name;
  endfunction

//function new(string input_name = "unnamed");
//  this.name = input_name;
//endfunction

//動作
  function void calc_expected(); //這個class有自己算expected的功能
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
   //只有在rst_n是0的時候，斷言(implication)才會執行，然後去檢查c是不是0。如果c是0的話，斷言就會通過；如果c不是0的話，斷言就會失敗，並且會執行else語句，印出錯誤信息。
   //rst_n是1的時候，斷言不會執行，因為前提條件(!rst_n)不成立，所以不會檢查c的值。所以也就不會跳到else
   //A |-> B (記住:如果 A 成立，B 必須成立。如果 A 不成立，這次 assertion 直接 pass。)
  assert property (p_reset_c_zero)
    else $error("ASSERTION FAILED: c is not zero during reset");

  property p_reset_known;
    @(posedge clk)
      !$isunknown(rst_n);
  endproperty
    //如果 $isunknown(rst_n) 是 1，代表 rst_n 是 X/Z。因為前面有 !，所以 !$isunknown(rst_n) 會變成 0。assertion 失敗，就會跳到 else。
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
//spec 裡重要的功能、狀態、corner case、組合情境，有沒有被測到？
//Functional coverage = 把 spec 變成一張「測試完整度 checklist」。
//有點像class，這裡是設計圖。必須先命名，然後在去生成物件
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

  alu_cov_cg alu_cov; //命名：alu_cov，型別：alu_cov_cg。這裡是宣告一個物件，還沒生成物件。在main那裏才建立object，alu_cov = new();

  // ------------------------------------------------------------
  // Driver-like task
  // ------------------------------------------------------------
//把東西塞到DUT裡面去
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
//把DUT的結果抓出來，塞到transaction裡面去
  task automatic monitor_task(
    input alu_transaction tr
  );
    begin
      @(posedge clk);
      #1; //等DUT算好
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
      alu_cov.sample(tr.a, tr.b, tr.op, tr.actual); //算functional coverage 

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
    input alu_transaction item1
  );
    //這裡面的是照順序執行，執行完一個才會做下一個
    begin 
      item1.calc_expected();

      driver_task(item1);
      monitor_task(item1);
      scoreboard_check(item1);
    end
  endtask

  // ------------------------------------------------------------
  // Helper task for directed tests
  // ------------------------------------------------------------
  //run_directed_test(4'sd3,    4'sd2,   2'b00, "ADD");
  task automatic run_directed_test(
    input logic signed [3:0] test_a,
    input logic signed [3:0] test_b,
    input logic        [1:0] test_op,
    input string             test_name
  );

    alu_transaction tr; // 宣告：我要一個 transaction 變數，名字叫 tr。 注意，在這個時候object還沒被產生

    begin
      tr = new(test_name);  //object這裡才被建立
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
      alu_transaction tr;
      tr = new($sformatf("RANDOM_%0d", i));

      if (!tr.randomize()) begin  //呼叫randomize()，如果randomize()回傳0，代表randomization失敗
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
