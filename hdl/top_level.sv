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

module top_level(
  input wire clk_100mhz, //crystal reference clock
  input wire [15:0] sw, //all 16 input slide switches
  input wire [3:0] btn, //all four momentary button switches
  output logic [15:0] led, //16 green output LEDs (located right above switches)
  output logic [2:0] rgb0, //rgb led
  output logic [2:0] rgb1, //rgb led
  output logic [2:0] hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
  output logic [2:0] hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
  output logic hdmi_clk_p, hdmi_clk_n //differential hdmi clock
  );
 
  assign led = sw; //to verify the switch values
  //shut up those rgb LEDs (active high):
  assign rgb1= 0;
  assign rgb0 = 0;
  /* have btnd control system reset */
  logic sys_rst;
  assign sys_rst = btn[0];
 
  logic clk_pixel, clk_5x; //clock lines
  logic locked; //locked signal (we'll leave unused but still hook it up)
 
  //clock manager...creates 74.25 Hz and 5 times 74.25 MHz for pixel and TMDS
  hdmi_clk_wiz_720p mhdmicw (
      .reset(0),
      .locked(locked),
      .clk_ref(clk_100mhz),
      .clk_pixel(clk_pixel),
      .clk_tmds(clk_5x));
 
  logic [10:0] hcount; //hcount of system!
  logic [9:0] vcount; //vcount of system!
  logic hor_sync; //horizontal sync signal
  logic vert_sync; //vertical sync signal
  logic active_draw; //ative draw! 1 when in drawing region.0 in blanking/sync
  logic new_frame; //one cycle active indicator of new frame of info!
  logic [5:0] frame_count; //0 to 59 then rollover frame counter
 
  //written by you! (make sure you include in your hdl)
  //default instantiation so making signals for 720p
  video_sig_gen mvg(
      .clk_pixel_in(clk_pixel),
      .rst_in(sys_rst),
      .hcount_out(hcount),
      .vcount_out(vcount),
      .vs_out(vert_sync),
      .hs_out(hor_sync),
      .ad_out(active_draw),
      .nf_out(new_frame),
      .fc_out(frame_count));
 
	logic [23:0] color_out;
  logic [7:0] red, green, blue; //red green and blue pixel values for output

  ////////////////////////////////////////////
  //
  //                 RENDER                     
  //
  ////////////////////////////////////////////

  localparam PIXEL_WIDTH = 1280;
  localparam PIXEL_HEIGHT = 720;
  localparam SCALE_LEVEL = 0;
  localparam WORLD_BITS = 32;
  localparam MAX_NUM_VERTICES = 8;
  localparam MAX_POLYGONS_ON_SCREEN = 4;
  localparam BACKGROUND_COLOR = `LBLUE;
  localparam EDGE_COLOR = `BLACK;
  localparam EDGE_THICKNESS = 3;

  logic signed [WORLD_BITS-1:0] camera_x, camera_y;
  logic signed [WORLD_BITS-1:0] polygons_xs [MAX_POLYGONS_ON_SCREEN] [MAX_NUM_VERTICES];
  logic signed [WORLD_BITS-1:0] polygons_ys [MAX_POLYGONS_ON_SCREEN] [MAX_NUM_VERTICES];
  logic [$clog2(MAX_NUM_VERTICES+1)-1:0] polygons_num_sides [MAX_POLYGONS_ON_SCREEN];
  logic [$clog2(MAX_POLYGONS_ON_SCREEN+1)-1:0] num_polygons;
  logic [3:0] polygons_colors [MAX_POLYGONS_ON_SCREEN];

  assign camera_x = 640;
  assign camera_y = 360;

  assign polygons_xs[0][0] = 100;
  assign polygons_xs[0][1] = 200;
  assign polygons_xs[0][2] = 200;
  assign polygons_xs[0][3] = 100;

  assign polygons_ys[0][0] = 100;
  assign polygons_ys[0][1] = 100;
  assign polygons_ys[0][2] = 200;
  assign polygons_ys[0][3] = 200;

  assign polygons_num_sides[0] = 4;
  assign polygons_colors[0] = `RED;

  assign polygons_xs[1][0] = 300;
  assign polygons_xs[1][1] = 400;
  assign polygons_xs[1][2] = 500;

  assign polygons_ys[1][0] = 300;
  assign polygons_ys[1][1] = 100;
  assign polygons_ys[1][2] = 300;

  assign polygons_num_sides[1] = 3;
  assign polygons_colors[1] = `GREEN;

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
  assign polygons_colors[2] = `YELLOW;
  
  assign num_polygons = 3;

  render # (
    .PIXEL_WIDTH(PIXEL_WIDTH),
    .PIXEL_HEIGHT(PIXEL_HEIGHT),
    .SCALE_LEVEL(SCALE_LEVEL),
    .WORLD_BITS(WORLD_BITS),
    .MAX_NUM_VERTICES(MAX_NUM_VERTICES),
    .MAX_POLYGONS_ON_SCREEN(MAX_POLYGONS_ON_SCREEN),
    .BACKGROUND_COLOR(BACKGROUND_COLOR),
    .EDGE_COLOR(EDGE_COLOR),
    .EDGE_THICKNESS(EDGE_THICKNESS)
  ) render_game (
    .rst_in(sys_rst),
    .clk_in(clk_pixel),
    .hcount_in(hcount),
    .vcount_in(vcount),
    .camera_x_in(camera_x),
    .camera_y_in(camera_y),
    .polygons_xs_in(polygons_xs),
    .polygons_ys_in(polygons_ys),
    .polygons_num_sides_in(polygons_num_sides),
    .num_polygons_in(num_polygons),
    .colors_in(polygons_colors),
    .color_out(color_out)
  );

	always_comb begin
		red = color_out[23:16];
		green = color_out[15:8];
		blue = color_out[7:0];
	end
 
  logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
  logic tmds_signal [2:0]; //output of each TMDS serializer!
 
  //three tmds_encoders (blue, green, red)
  //MISSING two more tmds encoders (one for green and one for blue)
  //note green should have no control signal like red
  //the blue channel DOES carry the two sync signals:
  //  * control_in[0] = horizontal sync signal
  //  * control_in[1] = vertical sync signal
 
  tmds_encoder tmds_red(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(red),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[2]));
 
  tmds_encoder tmds_green(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(green),
      .control_in(2'b0),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[1]));

  tmds_encoder tmds_blue(
      .clk_in(clk_pixel),
      .rst_in(sys_rst),
      .data_in(blue),
      .control_in({ vert_sync, hor_sync }),
      .ve_in(active_draw),
      .tmds_out(tmds_10b[0]));



  //three tmds_serializers (blue, green, red):
  //MISSING: two more serializers for the green and blue tmds signals.
  tmds_serializer red_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[2]),
      .tmds_out(tmds_signal[2]));

  tmds_serializer green_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[1]),
      .tmds_out(tmds_signal[1]));

  tmds_serializer blue_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst),
      .tmds_in(tmds_10b[0]),
      .tmds_out(tmds_signal[0]));


 
  //output buffers generating differential signals:
  //three for the r,g,b signals and one that is at the pixel clock rate
  //the HDMI receivers use recover logic coupled with the control signals asserted
  //during blanking and sync periods to synchronize their faster bit clocks off
  //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
  //the slower 74.25 MHz clock)
  OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
  OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
  OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
  OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));
 
endmodule // top_level
`default_nettype wire