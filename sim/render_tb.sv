`timescale 1ns / 1ps
`default_nettype none

module render_tb;

  //make logics for inputs and outputs!
  logic clk_in;
  logic rst_in;
  logic [11:0] pixel_out;
  logic [10:0] hcount_in;
  logic [9:0] vcount_in;
  logic [7:0] red_out, green_out, blue_out;
  logic [23:0] color_out;

  render # (
    .PIXEL_SCALE(1)     // how much to zoom in (bigger scale means bigger zoom)
  ) uut (
		.rst_in(rst_in),
		.clk_in(clk_in),
		.hcount_in(hcount_in),
		.vcount_in(vcount_in),
		.start_in(hcount_in == 1280 && vcount_in == 720),
		.color_out(color_out)
  );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("render.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,render_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in=0;
        #10;
        for (int i = 0; i < 5; i = i + 1) begin
          for (vcount_in = 0; vcount_in<750; vcount_in = vcount_in + 1) begin
            for (hcount_in = 0; hcount_in<1650; hcount_in = hcount_in + 1) begin
              #10;
            end
          end
        end
        #100;
        $display("Finishing Sim"); //print nice message
        $finish;

    end
endmodule //counter_tb

`default_nettype wire

