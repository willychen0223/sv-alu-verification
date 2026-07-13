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

//動作 Method
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

interface alu_if;

  logic clk;
  logic rst_n;
  logic signed [3:0] a;
  logic signed [3:0] b;
  logic        [1:0] op;
  logic signed [4:0] c;

  clocking driver_cb @(negedge clk);
    default output #0;

    output a;
    output b;
    output op;
  endclocking

  clocking monitor_cb @(negedge clk);
    default input #1step;

    input rst_n;
    input a;
    input b;
    input op;
    input c;
  endclocking

  modport DRIVER (
    clocking driver_cb
  );

  modport MONITOR (
    clocking monitor_cb
  );

endinterface

class alu_driver;

  mailbox #(alu_transaction) gen2drv_mbx;
  virtual alu_if.DRIVER vif;

  function new(
    mailbox #(alu_transaction) gen2drv_mbx,
    virtual alu_if.DRIVER vif
  );
    this.gen2drv_mbx = gen2drv_mbx;
    this.vif         = vif;
  endfunction

  task drive(input alu_transaction tr);

    @(vif.driver_cb);
    vif.driver_cb.a  <= tr.a;
    vif.driver_cb.b  <= tr.b;
    vif.driver_cb.op <= tr.op;

  endtask

  task run(input int num_tests);

    alu_transaction tr;

    for (int i = 0; i < num_tests; i++) begin
      gen2drv_mbx.get(tr);

      $display("DRV: got %s from mailbox", tr.name);

      drive(tr);
    end

  endtask

endclass
  

module tb;
  //先建立testbench裡面的訊號，然後再把訊號接到DUT裡面去
  //logic clk;
  //logic rst_n;
  //logic signed [3:0] a;
  //logic signed [3:0] b;
  //logic [1:0] op;
  //logic signed [4:0] c;

  alu_if intf(); //
  //alu_if:型別 ，intf名稱
  //執行這行 interface instance 就已經建立完成。
  //為什麼不需要 new()？
  //因為 interface 和 module 都屬於靜態結構。模擬器會在模擬開始前的 elaboration 階段建立它們。
  //module / interface instance：不用 new()
  //class object：需要 new()
  //virtual interface：只是指標，不用 new()

  int pass_count;
  int fail_count;

  // Day 12 : mailbox between geneator and driver
  mailbox #(alu_transaction) gen2drv_mbx;
  alu_driver drv;

//gen2drv_mbx 是一個信箱。
//它專門傳 alu_transaction。
//generator 把 tr 放進去。
//driver 從裡面拿 tr。

  alu dut (
    .clk   (intf.clk),
    .rst_n (intf.rst_n),
    .a     (intf.a),
    .b     (intf.b),
    .op    (intf.op),
    .c     (intf.c)
  );

  initial begin
    intf.clk = 0;
    forever #5 intf.clk = ~intf.clk;
  end

  // ------------------------------------------------------------
  // Assertions
  // ------------------------------------------------------------

  property p_reset_c_zero;
    @(posedge intf.clk)
      (!intf.rst_n) |-> (intf.c == 5'sd0); 
  endproperty
   //只有在rst_n是0的時候，斷言(implication)才會執行，然後去檢查c是不是0。如果c是0的話，斷言就會通過；如果c不是0的話，斷言就會失敗，並且會執行else語句，印出錯誤信息。
   //rst_n是1的時候，斷言不會執行，因為前提條件(!rst_n)不成立，所以不會檢查c的值。所以也就不會跳到else
   //A |-> B (記住:如果 A 成立，B 必須成立。如果 A 不成立，這次 assertion 直接 pass。)
  assert property (p_reset_c_zero)
    else $error("ASSERTION FAILED: c is not zero during reset");

  property p_reset_known;
    @(posedge intf.clk)
      !$isunknown(intf.rst_n);
  endproperty
    //如果 $isunknown(rst_n) 是 1，代表 rst_n 是 X/Z。因為前面有 !，所以 !$isunknown(rst_n) 會變成 0。assertion 失敗，就會跳到 else。
  assert property (p_reset_known)
    else $error("ASSERTION FAILED: rst_n is X or Z");

  property p_op_known;
    @(posedge intf.clk)
      intf.rst_n |-> !$isunknown(intf.op);
  endproperty

  assert property (p_op_known)
    else $error("ASSERTION FAILED: op is X or Z during normal operation");

  property p_c_known;
    @(posedge intf.clk)
      intf.rst_n |-> !$isunknown(intf.c);
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
    virtual alu_if.DRIVER vif,
    input alu_transaction tr
  );
    begin
      @(vif.driver_cb);
      vif.driver_cb.a  <= tr.a;
      vif.driver_cb.b  <= tr.b;
      vif.driver_cb.op <= tr.op;
    end
  endtask

  // ------------------------------------------------------------
  // Monitor-like task
  // ------------------------------------------------------------
//把DUT的結果抓出來，塞到transaction裡面去
  task automatic monitor_task(
    virtual alu_if.MONITOR vif,  //這裡的vif是task內的區域變數
    input alu_transaction tr
  );
    begin
      @(vif.monitor_cb);
      tr.actual = vif.monitor_cb.c;
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

      driver_task(intf,item1);
      monitor_task(intf,item1);
      scoreboard_check(item1);
    end
  endtask
  
  // ------------------------------------------------------------
// Day 12: Generator task
// ------------------------------------------------------------

task automatic generator_task(
  input int num_tests
);

  alu_transaction tr;

  begin
    for (int i = 0; i < num_tests; i++) begin
      tr = new($sformatf("GEN_RANDOM_%0d", i));

      if (!tr.randomize()) begin
        $fatal(1, "Randomization failed");
      end

      tr.calc_expected();

      gen2drv_mbx.put(tr);

      $display("GEN: put %s into mailbox", tr.name);
    end
  end

endtask

// ------------------------------------------------------------
// Day 12: Driver gets transactions from mailbox
// ------------------------------------------------------------

task automatic driver_from_mailbox_task(
  input int num_tests
);

  alu_transaction tr;

  begin
    for (int i = 0; i < num_tests; i++) begin
      gen2drv_mbx.get(tr);

      $display("DRV: got %s from mailbox", tr.name);

      drv.drive(tr);
      monitor_task(intf, tr);
      scoreboard_check(tr);


    end
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
    //tr叫做handle，可以想像成住家地址
    //alu_transaction是Class型別
    //new()建立object
    //tr.a，透過handle存取object裡的a
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

    intf.rst_n = 0;
    intf.a = 0;
    intf.b = 0;
    intf.op = 0;

    repeat (2) @(posedge intf.clk);
    intf.rst_n = 1;

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

    // Day 12: Random tests using generator + mailbox
    gen2drv_mbx = new(1);  //信箱的容量是1，代表一次只能放一個transaction。可以透過這個了解put get怎麼跟mailbox互動
    drv = new(gen2drv_mbx, intf);
    if (drv == null)
      $fatal(1, "Driver construction failed");
    else
      $display("Driver object constructed successfully");

    fork //fork join裡面的東西平行一起處理。begin end裡面的東西照順序執行
    //put = 放進 mailbox
    //get = 從 mailbox 拿出來

    //如果 mailbox 空的，get 會等。
    //fork...join 讓 generator 和 driver 同時跑。
    //所以 generator 一邊放，driver 一邊拿。
      generator_task(50);
      driver_from_mailbox_task(50);
    join





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
