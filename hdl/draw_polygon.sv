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
  input wire start_in,
  input wire [31:0] camera_x_in,
  input wire [31:0] camera_y_in,
  input wire signed [31:0] xs_in [MAX_NUM_VERTICES], // points of polygon in order
  input wire signed [31:0] ys_in [MAX_NUM_VERTICES],
  input wire [$clog2(MAX_NUM_VERTICES):0] num_points_in, // from 3 to MAX_NUM_VERTICES
  output logic [$clog2(PIXEL_WIDTH)-1:0] hcount_out,
  output logic [$clog2(PIXEL_HEIGHT)-1:0] vcount_out,
  output logic [3:0] pixel_color_out,
  output logic valid_out,
  output logic done_out
);

  logic [$clog2(PIXEL_WIDTH)-1:0] x_a, x_b;
  logic [$clog2(PIXEL_HEIGHT)-1:0] y_a, y_b;
  logic [$clog2(MAX_NUM_VERTICES)-1:0] i;

  typedef enum {
    READY,
    MINMAX,
    START_FILL,
    FILL,
    EDGES,
    DONE
  } draw_state;

  draw_state state;

  // minmax variables
  logic [$clog2(PIXEL_WIDTH)-1:0] x_min, x_max;
  logic [$clog2(PIXEL_HEIGHT)-1:0] y_min, y_max;

  // fill variables
  logic valid_fill;
  logic [$clog2(PIXEL_WIDTH)-1:0] hcount;
  logic [$clog2(PIXEL_HEIGHT)-1:0] vcount;

  in_polygon # (
    .PIXEL_WIDTH(1280),
    .PIXEL_HEIGHT(720),
    .MAX_NUM_VERTICES(4)
  ) check_in_polygon (
    .hcount_in(hcount),
    .vcount_in(vcount),
    .xs_in(xs_in),
    .ys_in(ys_in),
    .out(valid_fill)
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= READY;
    end else begin
      case (state)
        READY : begin
          done_out <= 0;

          // reset minmax variables
          i <= 0;
          x_a <= xs_in[0];
          y_a <= ys_in[0];
          x_min <= PIXEL_WIDTH - 1;
          y_min <= PIXEL_HEIGHT - 1;
          x_max <= 0;
          y_max <= 0;

          // reset fill variables
          hcount <= 0;
          vcount <= 0;

          if (start_in) begin
            state <= MINMAX;
          end
        end
        MINMAX : begin
          x_min <= x_a < x_min ? x_a : x_min;
          y_min <= y_a < y_min ? y_a : y_min;
          x_max <= x_a > x_max ? x_a : x_max;
          y_max <= y_a > y_max ? y_a : y_max;

          if (i < num_points_in - 1) begin
            x_a <= xs_in[i + 1];
            y_a <= ys_in[i + 1];
            i <= i + 1;
          end else begin
            i <= 0;
            x_a <= xs_in[0];
            y_a <= ys_in[0];
            state <= START_FILL;
          end
        end
        START_FILL : begin
          hcount <= x_min;
          vcount <= y_min;
          state <= FILL;
        end
        FILL : begin
          hcount_out <= hcount;
          vcount_out <= vcount;
          valid_out <= valid_fill;
          pixel_color_out <= FILL_COLOR;
          if (hcount < x_max) begin
            hcount <= hcount + 1;
          end else if (vcount < y_max) begin
            hcount <= x_min;
            vcount <= vcount + 1;
          end else begin
            state <= EDGES;
          end
        end
        EDGES : begin
          state <= DONE;
        end
        DONE : begin
          done_out <= 1;
          state <= READY;
        end
      endcase
    end
  end

endmodule

`default_nettype wire