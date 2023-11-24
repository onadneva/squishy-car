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
  parameter WORLD_BITS = 32,
  parameter MAX_NUM_VERTICES = 8,
  parameter MAX_POLYGONS_ON_SCREEN = 4,
  parameter BACKGROUND_COLOR = `GRAY,
  parameter EDGE_COLOR = `BLACK,
  parameter EDGE_THICKNESS = 3
) (
  input wire rst_in,
  input wire clk_in,
  input wire [$clog2(PIXEL_WIDTH)-1:0] hcount_in,
  input wire [$clog2(PIXEL_HEIGHT)-1:0] vcount_in,
  input wire signed [WORLD_BITS-1:0] camera_x_in,
  input wire signed [WORLD_BITS-1:0] camera_y_in,
  input wire signed [WORLD_BITS-1:0] polygons_xs_in [MAX_POLYGONS_ON_SCREEN] [MAX_NUM_VERTICES],
  input wire signed [WORLD_BITS-1:0] polygons_ys_in [MAX_POLYGONS_ON_SCREEN] [MAX_NUM_VERTICES],
  input wire [$clog2(MAX_NUM_VERTICES+1)-1:0] polygons_num_sides_in [MAX_POLYGONS_ON_SCREEN],
  input wire [$clog2(MAX_POLYGONS_ON_SCREEN+1)-1:0] num_polygons_in,
  input wire [3:0] colors_in [MAX_POLYGONS_ON_SCREEN],
  output logic [23:0] color_out
);

  logic [MAX_POLYGONS_ON_SCREEN-1:0] edge_valids, fill_valids;

  generate
    genvar p;
    for (p = 0; p < MAX_POLYGONS_ON_SCREEN; p = p + 1) begin
      draw_polygon # (
        .PIXEL_WIDTH(PIXEL_WIDTH), // number of pixels in resulting image width
        .PIXEL_HEIGHT(PIXEL_HEIGHT), // number of pixels in resulting image height
        .WORLD_BITS(WORLD_BITS),
        .SCALE_LEVEL(SCALE_LEVEL),    // how much to zoom in (bigger scale means bigger zoom)
        .EDGE_THICKNESS(EDGE_THICKNESS),
        .MAX_NUM_VERTICES(MAX_NUM_VERTICES)
      ) polygon (
        .rst_in(rst_in),
        .clk_in(clk_in),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .camera_x_in(camera_x_in),
        .camera_y_in(camera_y_in),
        .xs_in(polygons_xs_in[p]), // points of polygon in order
        .ys_in(polygons_ys_in[p]),
        .num_points_in(polygons_num_sides_in[p]), // from 3 to 31
        .edge_out(edge_valids[p]),
        .fill_out(fill_valids[p])
      );
    end
  endgenerate

  logic [3:0] color_idx;

  always_comb begin
    color_idx = BACKGROUND_COLOR;
    for (int i = MAX_POLYGONS_ON_SCREEN - 1; i >= 0; i = i - 1) begin
      if (i < num_polygons_in) begin
        color_idx = edge_valids[i] ? EDGE_COLOR : (fill_valids[i] ? colors_in[i] : color_idx);
      end else begin
        color_idx = color_idx;
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