module springs #(NUM_SPRINGS = 10, NUM_NODES = 10; POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [POSITION_SIZE-1:0] nodes [1:0][NUM_NODES],
  input  wire [$clog2(NUM_NODES)-1:0] springs [1:0][NUM_SPRINGS],
  input  wire signed [VELOCITY_SIZE-1:0] vel1_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel1_y,
  input  wire signed [VELOCITY_SIZE-1:0] vel2_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel2_y,
  output logic signed [FORCE_SIZE-1:0] spring_forces [1:0][NUM_NODES],
  output logic output_valid
  
);

state
logic [$clog2(NUM_NODES)-1:0] 
//springs: list of indeces of nodes connected by a spring
//ex) [(3,1),(5,7),(8,9)]
//logic [FORCE_SIZE-1:0] spring_forces [NUM_SPRINGS];
always_ff @(posedge clk_in) begin
    if (rst_in == 1) begin
        //rest
    end else begin
        case(state)
            IDLE: begin

            end
            CALCULATE: begin

            end
    end 
end

endmodule

"""
module should take the positions and velocities of two points and output the forces applied
to each of the points due to a spring
F = -k * x - b * v
"""

module spring #(POSITION_SIZE=8, VELOCITY_SIZE=8, FORCE_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [FORCE_SIZE-1:0] k,
  input  wire signed [FORCE_SIZE-1:0] b,
  input  wire signed [POSITION_SIZE-1:0] v1 [1:0],
  input  wire signed [POSITION_SIZE-1:0] v2 [1:0],
  input  wire signed [VELOCITY_SIZE-1:0] vel1_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel1_y,
  input  wire signed [VELOCITY_SIZE-1:0] vel2_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel2_y,
  output logic signed [FORCE_SIZE - 1:0] force_x,
  output logic signed [FORCE_SIZE - 1:0] force_y,
  //output logic signed [FORCE_SIZE - 1:0] force2_x_out,
  //output logic signed [FORCE_SIZE - 1:0] force2_y_out,
  output logic output_valid
  
);

always_comb begin
    force_x = (~(v2[0] - v1[0]) + 1) * k - (vel2_x - vel1_x)  * b;
    force_y = (~(v2[1] - v1[1]) + 1) * k - (vel2_y - vel1_y)  * b;
end

endmodule





        
