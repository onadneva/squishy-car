`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );
  
  logic [4:0] one_counter;
  
  always_comb begin
    one_counter = 0;
    for (int i = 0; i < 8; i = i + 1) begin
      if (data_in[i] == 1) begin
        one_counter = one_counter + 1;
      end else begin
        one_counter = one_counter;
      end
    end
    qm_out = { 8'b0000_0000, data_in[0] };
    if (one_counter > 4 || (one_counter == 4 && data_in[0] == 0)) begin
      // encoding scheme 2
      for (int i = 1; i < 8; i = i + 1) begin
        qm_out[i] = ~(data_in[i] ^ qm_out[i-1]);
      end
      qm_out[8] = 0;
    end else begin
      // encoding scheme 1
      for (int i = 1; i < 8; i = i + 1) begin
        qm_out[i] = data_in[i] ^ qm_out[i-1];
      end
      qm_out[8] = 1;
    end
  end

endmodule //end tm_choice

`default_nettype wire