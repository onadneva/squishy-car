`timescale 1ns / 1ps
`default_nettype none

module draw_polygon_tb;

  //make logics for inputs and outputs!
  logic clk_in;
  logic rst_in;
  logic start_signal;
  logic [7:0] red_out, green_out, blue_out;
  logic [3:0] color_out;

  logic [10:0] hcount_out;
  logic [9:0] vcount_out;

  logic signed [31:0] polygon_xs [4];
  logic signed [31:0] polygon_ys [4];
  logic [$clog2(4):0] polygon_num_sides;

  logic valid_out, done_out;

  assign polygon_xs[0] = 100;
  assign polygon_xs[1] = 200;
  assign polygon_xs[2] = 200;
  assign polygon_xs[3] = 100;

  assign polygon_ys[0] = 100;
  assign polygon_ys[1] = 100;
  assign polygon_ys[2] = 200;
  assign polygon_ys[3] = 200;

  assign polygon_num_sides = 4;

  draw_polygon uut (
    .rst_in(rst_in),
    .clk_in(clk_in),
    .start_in(start_signal),
    .camera_x_in(640),
    .camera_y_in(360),
    .xs_in(polygon_xs), // points of polygon in order
    .ys_in(polygon_ys),
    .num_points_in(polygon_num_sides), // from 3 to MAX_NUM_VERTICES
    .hcount_out(hcount_out),
    .vcount_out(vcount_out),
    .pixel_color_out(color_out),
    .valid_out(valid_out),
    .done_out(done_out)
  );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("draw_polygon.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,draw_polygon_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;
        start_signal = 1;
        #10;
        start_signal = 0;
        #100000;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire

