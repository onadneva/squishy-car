`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
 
  logic [8:0] q_m;
  logic [4:0] tally;
  logic [4:0] one_count;
  logic [4:0] zero_count;
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));

  always_comb begin
    one_count = 0;
    for (int i = 0; i < 8; i = i + 1) begin
      if (q_m[i] == 1) begin
        one_count = one_count + 1;
      end
    end
  end
  
  assign zero_count = 8 - one_count;

  always_ff @( posedge clk_in ) begin
    if (rst_in) begin
      tally <= 0;
      tmds_out <= 0;
    end else if (~ve_in) begin
      tally <= 0;
      case (control_in)
        2'b00: tmds_out = 10'b1101010100;
        2'b01: tmds_out = 10'b0010101011;
        2'b10: tmds_out = 10'b0101010100;
        2'b11: tmds_out = 10'b1010101011;
      endcase
    end else begin
      if (tally == 0 || one_count == zero_count) begin
        tmds_out <= { ~q_m[8], q_m[8], q_m[8] ? q_m[7:0] : ~q_m[7:0] };
        if (q_m[8] == 0) begin
          tally <= tally + (zero_count - one_count);
        end else begin
          tally <= tally + (one_count - zero_count);
        end
      end else if ((tally[4] == 0 && one_count > zero_count) || 
                   (tally[4] == 1 && zero_count > one_count)) begin
        tmds_out <= { 1'b1, q_m[8], ~q_m[7:0] };
        tally <= tally + (q_m[8] ? 2 : 0) + (zero_count - one_count);
      end else begin
        tmds_out <= { 1'b0, q_m };
        tally <= tally - (q_m[8] ? 0 : 2) + (one_count - zero_count);
      end
    end
  end
 
endmodule
 
`default_nettype wire