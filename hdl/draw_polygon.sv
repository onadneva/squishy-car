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
  parameter PIXEL_WIDTH = 1280, // number of pixels in resulting image width
  parameter PIXEL_HEIGHT = 720, // number of pixels in resulting image height
  parameter PIXEL_SCALE = 1,    // how much to zoom in (bigger scale means bigger zoom)

  parameter LINE_THICKNESS = 1, // thickness in pixels
  parameter LINE_COLOR = `BLACK,
  parameter FILL_COLOR = `RED,

  parameter MAX_NUM_VERTICES = 4
) (
  input wire rst_in,
  input wire clk_in,
  input wire [$clog2(PIXEL_WIDTH)-1:0] hcount_in,
  input wire [$clog2(PIXEL_HEIGHT)-1:0] vcount_in,
  input wire [31:0] camera_x_in,
  input wire [31:0] camera_y_in,
  input wire signed [31:0] xs_in [MAX_NUM_VERTICES], // points of polygon in order
  input wire signed [31:0] ys_in [MAX_NUM_VERTICES],
  input wire [$clog2(MAX_NUM_VERTICES):0] num_points_in, // from 3 to MAX_NUM_VERTICES
  output logic [3:0] pixel_color_out,
  output logic valid_out
);

  logic valid_fill;

  in_polygon # (
    .PIXEL_WIDTH(1280),
    .PIXEL_HEIGHT(720),
    .MAX_NUM_VERTICES(4)
  ) check_in_polygon (
    .clk_in(clk_in),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .xs_in(xs_in),
    .ys_in(ys_in),
    .out(valid_fill)
  );

  assign pixel_color_out = FILL_COLOR;
  assign valid_out = valid_fill;  

endmodule

`default_nettype wire