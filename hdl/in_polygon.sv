`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module in_polygon # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter MAX_NUM_VERTICES = 4
) (
  input wire [$clog2(PIXEL_WIDTH)-1:0] hcount_in,
  input wire [$clog2(PIXEL_HEIGHT)-1:0] vcount_in,
  input wire signed [31:0] xs_in [MAX_NUM_VERTICES],
  input wire signed [31:0] ys_in [MAX_NUM_VERTICES],
  output logic out
);

  logic signed [31:0] angles [MAX_NUM_VERTICES];
  logic signed [31:0] sum_angle_delta, angle_diff;

  generate
    genvar t;
    for (t = 0; t < MAX_NUM_VERTICES; t = t + 1) begin
      angle_approx instance_name_i (
        .x(xs_in[t] - hcount_in),
        .y(ys_in[t] - vcount_in),
        .angle(angles[t])
      );
    end
  endgenerate

  logic [31:0] j;
  always_comb begin
    sum_angle_delta = 0;
    for (int i = 0; i < MAX_NUM_VERTICES; i = i + 1) begin
      j = (i + 1) % MAX_NUM_VERTICES;
      angle_diff = angles[j] - angles[i];
      if (angle_diff > 180) begin
        sum_angle_delta = sum_angle_delta + angle_diff - 360;
      end else if (angle_diff < -180) begin
        sum_angle_delta = sum_angle_delta + 360 + angle_diff;
      end else begin
        sum_angle_delta = sum_angle_delta + angle_diff;
      end
    end

    if (sum_angle_delta > -180 && sum_angle_delta < 180) begin
      out = 0;
    end else begin
      out = 1;
    end
  end

endmodule

`default_nettype wire