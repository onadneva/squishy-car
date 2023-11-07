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
  output logic [23:0] color_out
);
  localparam PIXEL_TOTAL = PIXEL_WIDTH*PIXEL_HEIGHT;
  logic [$clog2(PIXEL_TOTAL)-1:0] read_addr, write_addr;
  logic [3:0] read_data, write_data;
  logic write_valid;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(4),
    .RAM_DEPTH(PIXEL_TOTAL))
    pixel_array (
    .addra(read_addr),
    .clka(clk_in),
    .wea(1'b0),
    .dina(4'b0),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(rst_in),
    .douta(read_data),
    .addrb(write_addr),
    .dinb(write_data),
    .clkb(clk_in),
    .web(write_valid),
    .enb(1'b1),
    .rstb(rst_in),
    .regceb(1'b1),
    .doutb()
  );

  assign read_addr = hcount_in + PIXEL_WIDTH * vcount_in;

  palette palette_idx_to_color (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .idx_in(read_data),
    .color_out(color_out)
  );

  typedef enum {
    WAITING=0,
    BACKGROUND=1,
    POLYGONS=2
  } draw_state;

  draw_state state;

  logic bg_start, bg_valid, bg_done;
  logic [$clog2(PIXEL_TOTAL):0] bg_addr;
  logic [3:0] bg_color;
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

  draw_background # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .COLOR(`LBLUE)
  ) background (
    .rst_in(rst_in),
    .clk_in(clk_in),
    .start_in(bg_start),
    .pixel_addr_out(bg_addr),
    .pixel_color_out(bg_color),
    .valid_out(bg_valid),
    .done_out(bg_done)
  );

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
    .valid_in(poly_start),
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
      bg_start <= 0;
      poly_start <= 0;
      write_valid <= 0;
    end else begin
      case (state)
        WAITING : begin
          if (start_in) begin
            state <= BACKGROUND;
            bg_start <= 1;
          end
        end
        BACKGROUND : begin
          bg_start <= 0;
          write_addr <= bg_addr;
          write_data <= bg_color;
          write_valid <= bg_valid;
          if (bg_done) begin
            poly_start <= 1;
            state <= POLYGONS;
            write_valid <= 0;
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

module draw_background # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter COLOR = `LBLUE
) (
  input wire rst_in,
  input wire clk_in,
  input wire start_in,
  output logic [$clog2(PIXEL_WIDTH*PIXEL_HEIGHT):0] pixel_addr_out,
  output logic [3:0] pixel_color_out,
  output logic valid_out,
  output logic done_out
);

  logic ongoing;

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      done_out <= 1;
      valid_out <= 0;
    end else if (start_in) begin
      pixel_addr_out <= 0;
      done_out <= 0;
      valid_out <= 1;
      ongoing <= 1;
    end else if (ongoing) begin
      if (pixel_addr_out < PIXEL_WIDTH * PIXEL_HEIGHT - 1) begin
        pixel_addr_out <= pixel_addr_out + 1;
      end else begin
        valid_out <= 0;
        done_out <= 1;
        ongoing <= 0;
      end
    end else begin
      done_out <= 0;
    end
  end

  assign pixel_color_out = COLOR;

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
  input wire valid_in,
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

  logic [31:0] point_a, point_b;
  logic [4:0] i;

  always_ff @(posedge clk_in) begin
    if (valid_in) begin
      done_out <= 0;
      valid_out <= 1;
      pixel_addr_out <= 0;
      pixel_color_out <= `RED;
    end else begin
      valid_out <= 0;
      done_out <= 1;
    end
    i <= i + 1;
    point_a <= xs_in[i];
    point_b <= point_a;
  end

endmodule

`default_nettype wire