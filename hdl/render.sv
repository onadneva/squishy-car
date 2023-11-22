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
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter SCALE_LEVEL = 0,
  parameter MAX_NUM_VERTICES = 8,
  parameter MAX_POLYGONS_ON_SCREEN = 4
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

  logic signed [31:0] polygons_xs [MAX_POLYGONS_ON_SCREEN] [MAX_NUM_VERTICES];
  logic signed [31:0] polygons_ys [MAX_POLYGONS_ON_SCREEN] [MAX_NUM_VERTICES];
  logic [$clog2(MAX_NUM_VERTICES+1)-1:0] polygons_num_sides [MAX_POLYGONS_ON_SCREEN];
  logic [$clog2(MAX_POLYGONS_ON_SCREEN+1)-1:0] polygons_on_screen;

  logic [3:0] colors_from_polygons [MAX_POLYGONS_ON_SCREEN];
  logic [MAX_POLYGONS_ON_SCREEN-1:0] color_valids;

  assign polygons_xs[0][0] = 100;
  assign polygons_xs[0][1] = 200;
  assign polygons_xs[0][2] = 200;
  assign polygons_xs[0][3] = 100;

  assign polygons_ys[0][0] = 100;
  assign polygons_ys[0][1] = 100;
  assign polygons_ys[0][2] = 200;
  assign polygons_ys[0][3] = 200;

  assign polygons_num_sides[0] = 4;

  assign polygons_xs[1][0] = 300;
  assign polygons_xs[1][1] = 400;
  assign polygons_xs[1][2] = 500;

  assign polygons_ys[1][0] = 300;
  assign polygons_ys[1][1] = 100;
  assign polygons_ys[1][2] = 300;

  assign polygons_num_sides[1] = 3;

  assign polygons_xs[2][0] = 700;
  assign polygons_xs[2][1] = 900;
  assign polygons_xs[2][2] = 900;
  assign polygons_xs[2][3] = 800;
  assign polygons_xs[2][4] = 700;

  assign polygons_ys[2][0] = 250;
  assign polygons_ys[2][1] = 250;
  assign polygons_ys[2][2] = 150;
  assign polygons_ys[2][3] = 50;
  assign polygons_ys[2][4] = 150;

  assign polygons_num_sides[2] = 5;
  
  assign polygons_on_screen = 3;

  generate
    genvar p;
    for (p = 0; p < MAX_POLYGONS_ON_SCREEN; p = p + 1) begin
      draw_polygon # (
        .PIXEL_WIDTH(PIXEL_WIDTH), // number of pixels in resulting image width
        .PIXEL_HEIGHT(PIXEL_HEIGHT), // number of pixels in resulting image height
        .SCALE_LEVEL(SCALE_LEVEL),    // how much to zoom in (bigger scale means bigger zoom)

        .LINE_THICKNESS(5), // thickness in pixels
        .LINE_COLOR(`BLACK),
        .FILL_COLOR(`RED),

        .MAX_NUM_VERTICES(MAX_NUM_VERTICES)
      ) polygon (
        .rst_in(rst_in),
        .clk_in(clk_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .camera_x_in(640),
        .camera_y_in(360),
        .xs_in(polygons_xs[p]), // points of polygon in order
        .ys_in(polygons_ys[p]),
        .num_points_in(polygons_num_sides[p]), // from 3 to 31
        .pixel_color_out(colors_from_polygons[p]),
        .valid_out(color_valids[p])
      );
    end
  endgenerate

  logic [3:0] color_idx;

  always_comb begin
    if (color_valids == 0) begin
      color_idx = background_color;
    end else begin
      for (int i = MAX_POLYGONS_ON_SCREEN - 1; i >= 0; i = i - 1) begin
        color_idx = color_valids[i] ? colors_from_polygons[i] : color_idx;
      end
    end
  end

  palette palette_idx_to_color (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .idx_in(color_idx),
    .color_out(color_out)
  );

endmodule

`default_nettype wire