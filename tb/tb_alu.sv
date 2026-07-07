module tb;

  logic clk;
  logic rst_n;
  logic signed [3:0] a;
  logic signed [3:0] b;
  logic [1:0] op;
  logic signed [4:0] c;

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

  task automatic apply_and_check(
    input logic signed [3:0] ta,
    input logic signed [3:0] tb,
    input logic        [1:0] top,
    input logic signed [4:0] expected,
    input string             test_name
  );
    begin
      @(posedge clk);
      a  = ta;
      b  = tb;
      op = top;

      @(posedge clk);
      #1;

      if (c !== expected) begin
        $display("FAIL: %s, a=%0d, b=%0d, op=%b, expected=%0d, actual=%0d",
                 test_name, ta, tb, top, expected, c);
      end else begin
        $display("PASS: %s", test_name);
      end
    end
  endtask

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);

    rst_n = 0;
    a = 0;
    b = 0;
    op = 0;

    repeat (2) @(posedge clk);
    rst_n = 1;

    apply_and_check(4'sd3,    4'sd2,   2'b00,  5'sd5,    "ADD");
    apply_and_check(4'sd3,    4'sd5,   2'b01, -5'sd2,    "SUB");
    apply_and_check(4'sb0011, 4'sd0,   2'b10,  5'b11100, "INV");
    apply_and_check(4'sd0,    4'b0000, 2'b11,  5'sd0,    "OR zero");
    apply_and_check(4'sd0,    4'b0100, 2'b11,  5'sd1,    "OR nonzero");

    apply_and_check(4'sd7,    4'sd7,   2'b00,  5'sd14,   "ADD max positive");
    apply_and_check(-4'sd8,   4'sd7,   2'b01, -5'sd15,   "SUB negative edge");

    $display("All directed tests completed.");
    $finish;
  end

endmodule