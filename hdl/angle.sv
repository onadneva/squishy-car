`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module angle_approx (
  input wire signed [31:0] x,
  input wire signed [31:0] y,
  output logic signed [31:0] angle
);

  logic signed [31:0] temp_angle;
  logic signed [31:0] signed_ratio;
  logic signed [31:0] abs_ratio;
  logic x_bigger;

  assign x_bigger = (x < 0 ? -x : x) > (y < 0 ? -y : y);
  assign signed_ratio = x_bigger ? (x << 2) / y : (y << 2) / x;
  assign abs_ratio = signed_ratio > 0 ? signed_ratio : -signed_ratio;

  always_comb begin
    if (abs_ratio == 4) begin
      temp_angle = 45;
    end else if (abs_ratio == 5) begin
      temp_angle = x_bigger ? 39 : 51;
    end else if (abs_ratio == 6) begin
      temp_angle = x_bigger ? 34 : 56;
    end else if (abs_ratio == 7) begin
      temp_angle = x_bigger ? 30 : 60;
    end else if (abs_ratio == 8) begin
      temp_angle = x_bigger ? 27 : 63;
    end else if (abs_ratio <= 10) begin
      temp_angle = x_bigger ? 22 : 68;
    end else if (abs_ratio <= 12) begin
      temp_angle = x_bigger ? 18 : 72;
    end else if (abs_ratio <= 16) begin
      temp_angle = x_bigger ? 14 : 76;
    end else if (abs_ratio <= 24) begin
      temp_angle = x_bigger ? 9 : 81;
    end else if (abs_ratio <= 48) begin
      temp_angle = x_bigger ? 5 : 85;
    end else begin
      temp_angle = x_bigger ? 0 : 90;
    end

    if (x > 0 && y > 0) begin
      // quadrant 1
      angle = temp_angle;
    end else if (x < 0 && y > 0) begin
      // quadrant 2
      angle = 180 - temp_angle;
    end else if (x < 0) begin
      // quadrant 3
      angle = 180 + temp_angle;
    end else begin
      // quadrant 4
      angle = 360 - temp_angle;
    end
  end
  
  
endmodule

`default_nettype wire