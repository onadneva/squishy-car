`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module draw_polygon # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter WORLD_BITS = 32,
  parameter SCALE_LEVEL = 0,
  parameter EDGE_THICKNESS = 3, // thickness in pixels
  parameter MAX_NUM_VERTICES = 32
) (
  input wire rst_in,
  input wire clk_in,
  input wire [$clog2(PIXEL_WIDTH)-1:0] hcount_in,
  input wire [$clog2(PIXEL_HEIGHT)-1:0] vcount_in,
  input wire signed [WORLD_BITS-1:0] camera_x_in,
  input wire signed [WORLD_BITS-1:0] camera_y_in,
  input wire signed [WORLD_BITS-1:0] xs_in [MAX_NUM_VERTICES], // points of polygon in order
  input wire signed [WORLD_BITS-1:0] ys_in [MAX_NUM_VERTICES],
  input wire [$clog2(MAX_NUM_VERTICES+1)-1:0] num_points_in, // from 3 to MAX_NUM_VERTICES
  output logic edge_out,
  output logic fill_out
);

  logic signed [WORLD_BITS-1:0] world_x, world_y;

  pixel_to_world # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .WORLD_BITS(WORLD_BITS),
    .SCALE_LEVEL(SCALE_LEVEL)
  ) get_world_coordinates (
    .clk_in(clk_in),
    .camera_x_in(camera_x_in),
    .camera_y_in(camera_y_in),
    .hcount_in(hcount_in), 
    .vcount_in(vcount_in),
    .world_x_out(world_x),
    .world_y_out(world_y)
  );

  in_polygon # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .WORLD_BITS(WORLD_BITS),
    .MAX_NUM_VERTICES(MAX_NUM_VERTICES)
  ) check_in_polygon (
    .clk_in(clk_in),
    .x_in(world_x),
    .y_in(world_y),
    .poly_xs_in(xs_in),
    .poly_ys_in(ys_in),
    .num_points_in(num_points_in),
    .out(fill_out)
  );

  assign edge_out = 0; // since I haven't implemented edges yet

endmodule

`default_nettype wire