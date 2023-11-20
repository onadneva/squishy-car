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

module render # (
  parameter PIXEL_WIDTH = 1280, // number of pixels in resulting image width
  parameter PIXEL_HEIGHT = 720, // number of pixels in resulting image height
  parameter PIXEL_SCALE = 1,     // how much to zoom in (bigger scale means bigger zoom)
  parameter MAX_NUM_VERTICES = 4
) (
  input wire rst_in,
  input wire clk_in,
  input wire [$clog2(PIXEL_WIDTH)-1:0] hcount_in,
  input wire [$clog2(PIXEL_HEIGHT)-1:0] vcount_in,
  input wire [3:0] background_color,
  output logic [23:0] color_out
);

  localparam PIXEL_TOTAL = PIXEL_WIDTH*PIXEL_HEIGHT;

  logic [$clog2(PIXEL_TOTAL)-1:0] read_addr, write_addr;
  logic [3:0] read_data, write_data;
  logic read_valid, write_valid;

  assign read_addr = hcount_in + PIXEL_WIDTH * vcount_in;
  assign read_valid = hcount_in < PIXEL_WIDTH && vcount_in < PIXEL_HEIGHT;

  typedef enum {
    WAITING=0,
    POLYGONS=1
  } draw_state;

  draw_state state;

  logic poly_start, poly_valid, poly_done;
  logic [3:0] poly_color;

  logic signed [31:0] polygon_xs [MAX_NUM_VERTICES];
  logic signed [31:0] polygon_ys [MAX_NUM_VERTICES];
  logic [$clog2(MAX_NUM_VERTICES):0] polygon_num_sides;

  assign polygon_xs[0] = 100;
  assign polygon_xs[1] = 200;
  assign polygon_xs[2] = 200;
  assign polygon_xs[3] = 100;

  assign polygon_ys[0] = 100;
  assign polygon_ys[1] = 100;
  assign polygon_ys[2] = 200;
  assign polygon_ys[3] = 200;

  assign polygon_num_sides = 4;

  draw_polygon # (
    .PIXEL_WIDTH(PIXEL_WIDTH), // number of pixels in resulting image width
    .PIXEL_HEIGHT(PIXEL_HEIGHT), // number of pixels in resulting image height
    .PIXEL_SCALE(PIXEL_SCALE),    // how much to zoom in (bigger scale means bigger zoom)

    .LINE_THICKNESS(5), // thickness in pixels
    .LINE_COLOR(`BLACK),
    .FILL_COLOR(`RED),

    .MAX_NUM_VERTICES(4)
  ) polygon (
    .rst_in(rst_in),
    .clk_in(clk_in),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .camera_x_in(640),
    .camera_y_in(360),
    .xs_in(polygon_xs), // points of polygon in order
    .ys_in(polygon_ys),
    .num_points_in(polygon_num_sides), // from 3 to 31
    .pixel_color_out(poly_color),
    .valid_out(poly_valid)
  );

  logic [3:0] color_idx;

  assign color_idx = poly_valid ? poly_color : background_color;

  palette palette_idx_to_color (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .idx_in(color_idx),
    .color_out(color_out)
  );

endmodule

`default_nettype wire