`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module angle_approx (
  input wire clk_in,
  input wire signed [31:0] x_in,
  input wire signed [31:0] y_in,
  output logic signed [31:0] angle_out
);

  localparam PRECISION = 4; // make same as python script
  localparam DIVIDER_LATENCY = 36;

  logic signed [31:0] dividend, divisor, ratio, remainder, angle;
  logic in_valid, out_valid;

  logic signed [31:0] old_xs [DIVIDER_LATENCY];
  logic signed [31:0] old_ys [DIVIDER_LATENCY];

  assign in_valid = 1;

  always_comb begin
    if ((x_in < 0 ? -x_in : x_in) > (y_in < 0 ? -y_in : y_in)) begin
      // abs(x) > abs(y)
      dividend = x_in << PRECISION;
      divisor = y_in;
    end else begin
      // abs(x) <= abs(y)
      dividend = y_in << PRECISION;
      divisor = x_in;
    end
  end

  signed_int_divider div (
    .aclk(clk_in),
    .s_axis_dividend_tdata(dividend),
    .s_axis_dividend_tvalid(in_valid),
    .s_axis_divisor_tdata(divisor),
    .s_axis_divisor_tvalid(in_valid),
    .m_axis_dout_tdata({ ratio, remainder }),
    .m_axis_dout_tvalid(out_valid)
  );

  always_comb begin
    if (old_xs[0] == 0) begin
      angle = old_ys[0] > 0 ? 90 : 270;
    end else if (old_ys[0] == 0) begin
      angle = old_xs[0] > 0 ? 0 : 180;
    //////////////////////////////////////////
    // Paste LUT from generate_angle_lut.py //
    //////////////////////////////////////////
    end else if (ratio <= -917) begin
      angle = old_xs[0] > 0 ? 271 : 91;
    end else if (ratio <= -152) begin
      angle = old_xs[0] > 0 ? 276 : 96;
    end else if (ratio <= -82) begin
      angle = old_xs[0] > 0 ? 281 : 101;
    end else if (ratio <= -56) begin
      angle = old_xs[0] > 0 ? 286 : 106;
    end else if (ratio <= -42) begin
      angle = old_xs[0] > 0 ? 291 : 111;
    end else if (ratio <= -33) begin
      angle = old_xs[0] > 0 ? 296 : 116;
    end else if (ratio <= -27) begin
      angle = old_xs[0] > 0 ? 301 : 121;
    end else if (ratio <= -22) begin
      angle = old_xs[0] > 0 ? 306 : 126;
    end else if (ratio <= -18) begin
      angle = old_xs[0] > 0 ? 311 : 131;
    end else if (ratio <= -15) begin
      angle = old_xs[0] > 0 ? 316 : 136;
    end else if (ratio <= -13) begin
      angle = old_xs[0] > 0 ? 321 : 141;
    end else if (ratio <= -11) begin
      angle = old_xs[0] > 0 ? 326 : 146;
    end else if (ratio <= -9) begin
      angle = old_xs[0] > 0 ? 331 : 151;
    end else if (ratio <= -7) begin
      angle = old_xs[0] > 0 ? 336 : 156;
    end else if (ratio <= -6) begin
      angle = old_xs[0] > 0 ? 341 : 161;
    end else if (ratio <= -4) begin
      angle = old_xs[0] > 0 ? 346 : 166;
    end else if (ratio <= -3) begin
      angle = old_xs[0] > 0 ? 351 : 171;
    end else if (ratio <= -1) begin
      angle = old_xs[0] > 0 ? 356 : 176;
    end else if (ratio <= 0) begin
      angle = old_xs[0] > 0 ? 1 : 181;
    end else if (ratio <= 2) begin
      angle = old_xs[0] > 0 ? 6 : 186;
    end else if (ratio <= 3) begin
      angle = old_xs[0] > 0 ? 11 : 191;
    end else if (ratio <= 5) begin
      angle = old_xs[0] > 0 ? 16 : 196;
    end else if (ratio <= 6) begin
      angle = old_xs[0] > 0 ? 21 : 201;
    end else if (ratio <= 8) begin
      angle = old_xs[0] > 0 ? 26 : 206;
    end else if (ratio <= 10) begin
      angle = old_xs[0] > 0 ? 31 : 211;
    end else if (ratio <= 12) begin
      angle = old_xs[0] > 0 ? 36 : 216;
    end else if (ratio <= 14) begin
      angle = old_xs[0] > 0 ? 41 : 221;
    end else if (ratio <= 17) begin
      angle = old_xs[0] > 0 ? 46 : 226;
    end else if (ratio <= 20) begin
      angle = old_xs[0] > 0 ? 51 : 231;
    end else if (ratio <= 24) begin
      angle = old_xs[0] > 0 ? 56 : 236;
    end else if (ratio <= 29) begin
      angle = old_xs[0] > 0 ? 61 : 241;
    end else if (ratio <= 36) begin
      angle = old_xs[0] > 0 ? 66 : 246;
    end else if (ratio <= 46) begin
      angle = old_xs[0] > 0 ? 71 : 251;
    end else if (ratio <= 64) begin
      angle = old_xs[0] > 0 ? 76 : 256;
    end else if (ratio <= 101) begin
      angle = old_xs[0] > 0 ? 81 : 261;
    end else if (ratio <= 229) begin
      angle = old_xs[0] > 0 ? 86 : 266;
    ///////////////////////////////////////////
    end else begin
      angle = old_ys[0] > 0 ? 90 : 270;
    end
  end

  always_ff @(posedge clk_in) begin
    old_xs[DIVIDER_LATENCY-1] <= x_in;
    old_ys[DIVIDER_LATENCY-1] <= y_in;
    for (int i = DIVIDER_LATENCY - 2; i >= 0; i = i - 1) begin
      old_xs[i] <= old_xs[i + 1];
      old_ys[i] <= old_ys[i + 1];
    end
  end
  
  always_ff @(posedge clk_in) begin
    angle_out <= angle;
  end
  
endmodule

`default_nettype wire
