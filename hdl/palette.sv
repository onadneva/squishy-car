`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"data/X`"
`endif  /* ! SYNTHESIS */

module palette (
  input wire clk_in,
  input wire rst_in,
  input wire [3:0] idx_in,
  output logic [23:0] color_out
);

  always_ff @(posedge clk_in) begin
    case (idx_in)
      4'b0000: color_out = 24'h000000;
      4'b0001: color_out = 24'h9d9d9d;
      4'b0010: color_out = 24'hffffff;
      4'b0011: color_out = 24'hbe2633;
      4'b0100: color_out = 24'he06f8b;
      4'b0101: color_out = 24'h493c2b;
      4'b0110: color_out = 24'ha46422;
      4'b0111: color_out = 24'heb8931;
      4'b1000: color_out = 24'hf7e26b;
      4'b1001: color_out = 24'h2f484e;
      4'b1010: color_out = 24'h44891a;
      4'b1011: color_out = 24'ha3ce27;
      4'b1100: color_out = 24'h1b2632;
      4'b1101: color_out = 24'h005784;
      4'b1110: color_out = 24'h31a2f2;
      4'b1111: color_out = 24'hb2dcef;
    endcase
  end

  // xilinx_single_port_ram_read_first #(
  //   .RAM_WIDTH(24),
  //   .RAM_DEPTH(16),
  //   .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
  //   .INIT_FILE(`FPATH(palette.mem))
  // ) palette_reader (
  //   .addra(idx_in),
  //   .dina(1'b0),
  //   .clka(clk_in),
  //   .wea(1'b0),
  //   .ena(1'b1),
  //   .rsta(rst_in),
  //   .regcea(1'b1),
  //   .douta(color_out)
  // );

endmodule

`default_nettype wire