`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module in_polygon # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter MAX_NUM_VERTICES = 32
) (
  input wire clk_in,
  input wire signed [31:0] x_in,
  input wire signed [31:0] y_in,
  input wire signed [31:0] poly_xs_in [MAX_NUM_VERTICES],
  input wire signed [31:0] poly_ys_in [MAX_NUM_VERTICES],
  input wire [$clog2(MAX_NUM_VERTICES+1)-1:0] num_points_in,
  output logic out
);

  logic signed [31:0] angles [MAX_NUM_VERTICES];
  logic signed [31:0] angle_diffs [MAX_NUM_VERTICES];
  logic signed [31:0] temp_angle_diffs [MAX_NUM_VERTICES];
  logic signed [31:0] sum_angle_delta;
  logic is_inside;

  // compute, in parallel, the angle from (hcount, vcount) to each point in the polygon
  generate
    genvar t;
    for (t = 0; t < MAX_NUM_VERTICES; t = t + 1) begin
      angle_approx angle_approx_i (
        .clk_in(clk_in),
        .x_in(poly_xs_in[t] - x_in),
        .y_in(poly_ys_in[t] - y_in),
        .angle_out(angles[t])
      );
    end
  endgenerate

  // compute, in parallel, the difference in consecutive pairs of angles
  generate
    genvar u;
    for (u = 0; u < MAX_NUM_VERTICES; u = u + 1) begin
      always_comb begin
        temp_angle_diffs[u] = angles[u + 1 < num_points_in ? u + 1 : 0] - angles[u];
        if (temp_angle_diffs[u] > 180) begin
          temp_angle_diffs[u] = temp_angle_diffs[u] - 360;
        end else if (temp_angle_diffs[u] < -180) begin
          temp_angle_diffs[u] = 360 + temp_angle_diffs[u];
        end else begin
          temp_angle_diffs[u] = temp_angle_diffs[u];
        end
      end
    end
  endgenerate

  always_ff @(posedge clk_in) begin
    for (int i = 0; i < MAX_NUM_VERTICES; i = i + 1) begin
      angle_diffs[i] <= temp_angle_diffs[i];
    end
  end

  // sum up all these differences in angles to determine whether the (hcount, vcount) is inside the polygon
  logic [$clog2(MAX_NUM_VERTICES)-1:0] i;
  always_comb begin
    sum_angle_delta = 0;
    for (int i = 0; i < MAX_NUM_VERTICES; i = i + 1) begin
      sum_angle_delta = sum_angle_delta + (i < num_points_in ? angle_diffs[i] : 0);
    end

    if (sum_angle_delta > -180 && sum_angle_delta < 180) begin
      is_inside = 0;
    end else begin
      is_inside = 1;
    end
  end

  always_ff @(posedge clk_in) begin
    out <= is_inside;
  end

endmodule

`default_nettype wire