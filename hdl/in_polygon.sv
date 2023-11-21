`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module in_polygon # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter MAX_NUM_VERTICES = 4
) (
  input wire clk_in,
  input wire [$clog2(PIXEL_WIDTH)-1:0] hcount_in,
  input wire [$clog2(PIXEL_HEIGHT)-1:0] vcount_in,
  input wire signed [31:0] xs_in [MAX_NUM_VERTICES],
  input wire signed [31:0] ys_in [MAX_NUM_VERTICES],
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
      angle_approx instance_name_i (
        .clk_in(clk_in),
        .x_in(xs_in[t] - hcount_in),
        .y_in(ys_in[t] - vcount_in),
        .angle_out(angles[t])
      );
    end
  endgenerate

  // compute, in parallel, the difference in consecutive pairs of angles
  generate
    genvar u;
    for (u = 0; u < MAX_NUM_VERTICES; u = u + 1) begin
      always_comb begin
        temp_angle_diffs[u] = angles[u + 1 < MAX_NUM_VERTICES ? u + 1 : 0] - angles[u];
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
    angle_diffs <= temp_angle_diffs;
  end

  // sum up all these differences in angles to determine whether the (hcount, vcount) is inside the polygon
  logic [$clog2(MAX_NUM_VERTICES)-1:0] i;
  always_comb begin
    sum_angle_delta = 0;
    for (int i = 0; i < MAX_NUM_VERTICES; i = i + 1) begin
      sum_angle_delta = sum_angle_delta + angle_diffs[i];
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