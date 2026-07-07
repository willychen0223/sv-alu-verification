module alu (
  input  logic              clk,
  input  logic              rst_n,
  input  logic signed [3:0] a,
  input  logic signed [3:0] b,
  input  logic        [1:0] op,
  output logic signed [4:0] c
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      c <= 5'sd0;
    end else begin
      case (op)
        2'b00: c <= a + b;   // ADD
        2'b01: c <= a - b;   // SUB
        2'b10: c <= ~a;      // Bitwise invert A
        2'b11: c <= |b;      // Reduction OR B
        default: c <= 5'sd0;
      endcase
    end
  end

endmodule
