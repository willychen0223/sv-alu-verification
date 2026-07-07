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

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);

    rst_n = 0;
    a = 0;
    b = 0;
    op = 0;

    repeat (2) @(posedge clk);
    rst_n = 1;

    // ADD: 3 + 2 = 5
    @(posedge clk);
    a = 4'sd3;
    b = 4'sd2;
    op = 2'b00;
    @(posedge clk);
    #1;
    if (c !== 5'sd5)
      $display("FAIL: ADD, expected=5, actual=%0d", c);
    else
      $display("PASS: ADD");

    // SUB: 3 - 5 = -2
    @(posedge clk);
    a = 4'sd3;
    b = 4'sd5;
    op = 2'b01;
    @(posedge clk);
    #1;
    if (c !== -5'sd2)
      $display("FAIL: SUB, expected=-2, actual=%0d", c);
    else
      $display("PASS: SUB");

    // INV: ~0011 = 1100.
    // Since a is signed [3:0], 4'b1100 is -4.
    // Assigned to signed [4:0], it becomes sign-extended: 5'b11100.
    @(posedge clk);
    a = 4'sb0011;
    b = 4'sd0;
    op = 2'b10;
    @(posedge clk);
    #1;
    if (c !== 5'b11100)
      $display("FAIL: INV, expected=11100, actual=%b", c);
    else
      $display("PASS: INV");

    // OR zero: |0000 = 0
    @(posedge clk);
    a = 4'sd0;
    b = 4'b0000;
    op = 2'b11;
    @(posedge clk);
    #1;
    if (c !== 5'sd0)
      $display("FAIL: OR zero, expected=0, actual=%0d", c);
    else
      $display("PASS: OR zero");

    // OR nonzero: |0100 = 1
    @(posedge clk);
    a = 4'sd0;
    b = 4'b0100;
    op = 2'b11;
    @(posedge clk);
    #1;
    if (c !== 5'sd1)
      $display("FAIL: OR nonzero, expected=1, actual=%0d", c);
    else
      $display("PASS: OR nonzero");

    $display("All directed tests completed.");
    $finish;
  end

endmodule
