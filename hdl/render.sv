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
  parameter PIXEL_SCALE = 1     // how much to zoom in (bigger scale means bigger zoom)
) (
  input wire rst_in,
  input wire clk_in,
  input wire [$clog2(PIXEL_WIDTH):0] hcount_in,
  input wire [$clog2(PIXEL_HEIGHT):0] vcount_in,
  input wire start_in,
  input wire [3:0] background_color,
  output logic [23:0] color_out
);

  localparam PIXEL_TOTAL = PIXEL_WIDTH*PIXEL_HEIGHT;

  logic [$clog2(PIXEL_TOTAL)-1:0] read_addr, write_addr;
  logic [3:0] read_data, write_data;
  logic read_valid, write_valid;

  assign read_addr = hcount_in + PIXEL_WIDTH * vcount_in;
  assign read_valid = hcount_in < PIXEL_WIDTH && vcount_in < PIXEL_HEIGHT;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(4),
    .RAM_DEPTH(PIXEL_TOTAL/2))
    pixel_array (
    .addra(read_addr),
    .clka(clk_in),
    .wea(read_valid),
    .dina(background_color),
    .ena(read_valid),
    .regcea(1'b1),
    .rsta(rst_in),
    .douta(read_data),
    .addrb(write_addr),
    .dinb(write_data),
    .clkb(clk_in),
    .web(write_valid),
    .enb(1'b0),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb()
  );

  palette palette_idx_to_color (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .idx_in(read_data),
    .color_out(color_out)
  );

  typedef enum {
    WAITING=0,
    POLYGONS=1
  } draw_state;

  draw_state state;

  logic poly_start, poly_valid, poly_done;
  logic [$clog2(PIXEL_TOTAL):0] poly_addr;
  logic [3:0] poly_color;

  logic [31:0] polygon_xs [32];
  logic [31:0] polygon_ys [32];
  logic [4:0] polygon_num_sides;

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
    .FILL_COLOR(`RED)
  ) polygon (
    .rst_in(rst_in),
    .clk_in(clk_in),
    .start_in(poly_start),
    .camera_x_in(640),
    .camera_y_in(360),
    .xs_in(polygon_xs), // points of polygon in order
    .ys_in(polygon_ys),
    .num_points_in(polygon_num_sides), // from 3 to 31
    .pixel_addr_out(poly_addr),
    .pixel_color_out(poly_color),
    .valid_out(poly_valid),
    .done_out(poly_done)
  );

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= WAITING;
      poly_start <= 0;
      write_valid <= 0;
    end else begin
      case (state)
        WAITING : begin
          if (start_in) begin
            state <= POLYGONS;
            poly_start <= 1;
          end
        end
        POLYGONS : begin
          poly_start <= 0;
          write_addr <= poly_addr;
          write_data <= poly_color;
          write_valid <= poly_valid;
          if (poly_done) begin
            write_valid <= 0;
            state <= WAITING;
          end
        end
        default : begin
          state <= WAITING;
        end
      endcase
    end
  end

endmodule

module draw_polygon # (
  parameter PIXEL_WIDTH = 1280, // number of pixels in resulting image width
  parameter PIXEL_HEIGHT = 720, // number of pixels in resulting image height
  parameter PIXEL_SCALE = 1,    // how much to zoom in (bigger scale means bigger zoom)

  parameter LINE_THICKNESS = 1, // thickness in pixels
  parameter LINE_COLOR = `BLACK,
  parameter FILL_COLOR = `RED
) (
  input wire rst_in,
  input wire clk_in,
  input wire start_in,
  input wire [31:0] camera_x_in,
  input wire [31:0] camera_y_in,
  input wire [31:0] xs_in [32], // points of polygon in order
  input wire [31:0] ys_in [32],
  input wire [4:0] num_points_in, // from 3 to 31
  output logic [$clog2(PIXEL_WIDTH*PIXEL_HEIGHT):0] pixel_addr_out,
  output logic [3:0] pixel_color_out,
  output logic valid_out,
  output logic done_out
);

  logic [$clog2(PIXEL_WIDTH):0] x_a, x_b;
  logic [$clog2(PIXEL_HEIGHT):0] y_a, y_b;
  logic [4:0] i;

  typedef enum {
    READY=0,
    MINMAX=1,
    FILL=2,
    EDGES=3
  } draw_state;

  draw_state state;

  // minmax variables
  logic [$clog2(PIXEL_WIDTH):0] x_min, x_max;
  logic [$clog2(PIXEL_HEIGHT):0] y_min, y_max;

  // fill variables
  logic angle_total;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= READY;
    end else begin
      case (state)
        READY : begin
          i <= 0;
          x_a <= xs_in[0];
          y_a <= ys_in[0];

          x_min <= PIXEL_WIDTH - 1;
          y_min <= PIXEL_HEIGHT - 1;
          x_max <= 0;
          y_max <= 0;

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
            state <= FILL;
          end
        end
        FILL : begin
          
        end
        EDGES : begin
          
        end
      endcase
    end
  end

endmodule

`default_nettype wire