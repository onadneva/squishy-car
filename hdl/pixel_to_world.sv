`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

// converts a pixel hcount and vcount to real world coordinates
module pixel_to_world # (
  parameter PIXEL_WIDTH = 1280,
  parameter PIXEL_HEIGHT = 720,
  parameter WORLD_BITS = 32,
  parameter SCALE_LEVEL = 0 // camera will zoom out 2**SCALE_LEVEL times (or zoom in, if SCALE_LEVEL < 0)
) (
  input wire clk_in,
  input wire signed [WORLD_BITS-1:0] camera_x_in,
  input wire signed [WORLD_BITS-1:0] camera_y_in,
  input wire [$clog2(PIXEL_WIDTH)-1:0] hcount_in, 
  input wire [$clog2(PIXEL_HEIGHT)-1:0] vcount_in,
  output logic signed [WORLD_BITS-1:0] world_x_out,
  output logic signed [WORLD_BITS-1:0] world_y_out
);

  logic signed [WORLD_BITS-1:0] x_pos, y_pos, scaled_x_pos, scaled_y_pos, world_x_temp, world_y_temp;

  always_comb begin
    x_pos = hcount_in - (PIXEL_WIDTH >> 1);
    y_pos = vcount_in - (PIXEL_HEIGHT >> 1);

    world_x_temp = (SCALE_LEVEL >= 0 ? x_pos << SCALE_LEVEL : x_pos >>> -SCALE_LEVEL) + camera_x_in;
    world_y_temp = (SCALE_LEVEL >= 0 ? y_pos << SCALE_LEVEL : y_pos >>> -SCALE_LEVEL) + camera_y_in;
  end

  always_ff @(posedge clk_in) begin
    world_x_out <= world_x_temp;
    world_y_out <= world_y_temp;
  end

endmodule

`default_nettype wire