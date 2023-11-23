`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

`define BLACK 4'h0
`define GRAY 4'h1
`define WHITE 4'h2
`define RED 4'h3
`define PINK 4'h4
`define DBROWN 4'h5
`define BROWN 4'h6
`define ORANGE 4'h7
`define YELLOW 4'h8
`define DGREEN 4'h9
`define GREEN 4'hA
`define LGREEN 4'hB
`define PURPLE 4'hC
`define DBLUE 4'hD
`define BLUE 4'hE
`define LBLUE 4'hF

module draw_polygon # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter WORLD_BITS = 32,
  parameter SCALE_LEVEL = 0,

  parameter LINE_THICKNESS = 1, // thickness in pixels
  parameter LINE_COLOR = `BLACK,
  parameter FILL_COLOR = `RED,

  parameter MAX_NUM_VERTICES = 32
) (
  input wire rst_in,
  input wire clk_in,
  input wire [$clog2(PIXEL_WIDTH)-1:0] hcount_in,
  input wire [$clog2(PIXEL_HEIGHT)-1:0] vcount_in,
  input wire [WORLD_BITS-1:0] camera_x_in,
  input wire [WORLD_BITS-1:0] camera_y_in,
  input wire signed [WORLD_BITS-1:0] xs_in [MAX_NUM_VERTICES], // points of polygon in order
  input wire signed [WORLD_BITS-1:0] ys_in [MAX_NUM_VERTICES],
  input wire [$clog2(MAX_NUM_VERTICES+1)-1:0] num_points_in, // from 3 to MAX_NUM_VERTICES
  output logic [3:0] pixel_color_out,
  output logic valid_out
);

  logic signed [WORLD_BITS-1:0] world_x, world_y;
  logic valid_fill;

  pixel_to_world # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
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
    .MAX_NUM_VERTICES(MAX_NUM_VERTICES)
  ) check_in_polygon (
    .clk_in(clk_in),
    .x_in(world_x),
    .y_in(world_y),
    .poly_xs_in(xs_in),
    .poly_ys_in(ys_in),
    .num_points_in(num_points_in),
    .out(valid_fill)
  );

  assign pixel_color_out = FILL_COLOR;
  assign valid_out = valid_fill;  

endmodule

`default_nettype wire