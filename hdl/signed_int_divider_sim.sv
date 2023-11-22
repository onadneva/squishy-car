`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module signed_int_divider_sim (
    input wire aclk,
    input wire signed [31:0] s_axis_dividend_tdata,
    input wire s_axis_dividend_tvalid,
    input wire signed [31:0] s_axis_divisor_tdata,
    input wire s_axis_divisor_tvalid,
    output logic signed [63:0] m_axis_dout_tdata,
    output logic m_axis_dout_tvalid
  );

  logic signed [63:0] div_outs [36];

  always_ff @(posedge aclk) begin
    div_outs[0] <= { s_axis_dividend_tdata / s_axis_divisor_tdata, 32'h0 };
    for (int i = 1; i < 36; i = i + 1) begin
      div_outs[i] <= div_outs[i - 1];
    end
  end

  assign m_axis_dout_tdata = div_outs[35];

endmodule

`default_nettype wire