`timescale 1ns / 1ps
`default_nettype none

module in_polygon_tb;

  //make logics for inputs and outputs!
  logic clk_in;
  logic rst_in;
  logic [11:0] pixel_out;
  logic [10:0] hcount_in;
  logic [9:0] vcount_in;

  logic signed [31:0] polygon_xs [4];
  logic signed [31:0] polygon_ys [4];
  logic [$clog2(4):0] polygon_num_sides;

  logic in_polygon_out;

  assign polygon_xs[0] = 100;
  assign polygon_xs[1] = 200;
  assign polygon_xs[2] = 200;
  assign polygon_xs[3] = 100;

  assign polygon_ys[0] = 100;
  assign polygon_ys[1] = 100;
  assign polygon_ys[2] = 200;
  assign polygon_ys[3] = 200;

  assign polygon_num_sides = 4;

  in_polygon uut (
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .xs_in(polygon_xs),
    .ys_in(polygon_ys),
    .out(in_polygon_out)
  );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("in_polygon.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,in_polygon_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;
        for (vcount_in = 0; vcount_in<750; vcount_in = vcount_in + 1) begin
          for (hcount_in = 0; hcount_in<1650; hcount_in = hcount_in + 1) begin
            #10;
          end
        end
        #100;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire

