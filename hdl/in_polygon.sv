`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module in_polygon # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter WORLD_BITS = 32,
  parameter MAX_NUM_VERTICES = 32
) (
  input wire clk_in,
  input wire signed [WORLD_BITS-1:0] x_in,
  input wire signed [WORLD_BITS-1:0] y_in,
  input wire signed [WORLD_BITS-1:0] poly_xs_in [MAX_NUM_VERTICES],
  input wire signed [WORLD_BITS-1:0] poly_ys_in [MAX_NUM_VERTICES],
  input wire [$clog2(MAX_NUM_VERTICES+1)-1:0] num_points_in,
  output logic out
);

  logic [MAX_NUM_VERTICES-1:0] intersections;
  logic signed [WORLD_BITS-1:0] Hx [MAX_NUM_VERTICES];
  logic signed [WORLD_BITS-1:0] Hy [MAX_NUM_VERTICES];
  logic signed [WORLD_BITS-1:0] Lx [MAX_NUM_VERTICES];
  logic signed [WORLD_BITS-1:0] Ly [MAX_NUM_VERTICES];
  logic signed [2*WORLD_BITS-1:0] mul1 [MAX_NUM_VERTICES];
  logic signed [2*WORLD_BITS-1:0] mul2 [MAX_NUM_VERTICES];
  logic [MAX_NUM_VERTICES-1:0] in_bounds;

  generate
    for (genvar v = 0; v < MAX_NUM_VERTICES; v = v + 1) begin
      signed_int_multiplier multiply1 (
        .CLK(clk_in),
        .A(Lx[v] - Hx[v]),
        .B(y_in - Hy[v]),
        .P(mul1[v])
      );

      signed_int_multiplier multiply2 (
        .CLK(clk_in),
        .A(Ly[v] - Hy[v]),
        .B(x_in - Hx[v]),
        .P(mul2[v])
      );
    end
  endgenerate

  always_ff @(posedge clk_in) begin
    for (int v = 0; v < MAX_NUM_VERTICES; v = v + 1) begin
      if (v < num_points_in) begin
        if (poly_ys_in[v] > poly_ys_in[v + 1 < num_points_in ? v + 1 : 0]) begin
          Hx[v] <= poly_xs_in[v];
          Hy[v] <= poly_ys_in[v];
          Lx[v] <= poly_xs_in[v + 1 < num_points_in ? v + 1 : 0];
          Ly[v] <= poly_ys_in[v + 1 < num_points_in ? v + 1 : 0];
        end else begin
          Hx[v] <= poly_xs_in[v + 1 < num_points_in ? v + 1 : 0];
          Hy[v] <= poly_ys_in[v + 1 < num_points_in ? v + 1 : 0];
          Lx[v] <= poly_xs_in[v];
          Ly[v] <= poly_ys_in[v];
        end
        in_bounds[v] <= (Hy[v] > y_in) && (y_in >= Ly[v]);
        intersections[v] <= in_bounds[v] && (mul1[v] - mul2[v] >= 0);
      end
    end
  end

  logic odd_intersections;
  always_comb begin
    odd_intersections = 0;
    for (int i = 0; i < MAX_NUM_VERTICES; i = i + 1) begin
      odd_intersections ^= i < num_points_in && intersections[i];
    end
  end

  always_ff @(posedge clk_in) begin
    out <= odd_intersections;
  end

endmodule

`default_nettype wire