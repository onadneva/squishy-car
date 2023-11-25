module update_point #(parameter DT = 1, parameter POSITION_SIZE=8, parameter VELOCITY_SIZE, parameter FORCE_SIZE =8, parameter NUM_VERTICES=5, parameter NUM_OBSTACLES=5)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire [POSITION_SIZE-1:0] obstacles_in [1:0][NUM_VERTICES][NUM_OBSTACLES],
  input  wire [POSITION_SIZE-1:0] num_vertices_in [NUM_OBSTACLES], //array of num_vertices
  input wire [POSITION_SIZE-1:0] num_obstacles_in,
  input  wire [POSITION_SIZE-1:0] pos_x_in,
  input  wire [POSITION_SIZE-1:0] pos_y_in,
  input  wire [VELOCITY_SIZE-1:0] vel_x_in,
  input  wire [VELOCITY_SIZE-1:0] vel_y_in,
  output logic [POSITION_SIZE-1:0] new_pos_x,
  output logic [POSITION_SIZE-1:0] new_pos_y,
  output logic [VELOCITY_SIZE-1:0] new_vel_x,
  output logic [VELOCITY_SIZE-1:0] new_vel_y,
  output logic result_out
);

collisions #(DT, POSITION_SIZE, NUM_OBSTACLES, NUM_VERTICES) collisions_handler (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(collision_begin),
    .obstacles_in(obstacles),
    .num_vertices_in(num_vertices),
    .num_obstacles_in(num_obstacles),
    .pos_x_in(pos_x_in),
    .pos_y_in(pos_y_in),
    .dx_in(dx),
    .dy_in(dy),
    //.ready(ready),
    .result_out(collision_result),
    .x_new_out(collision_new_x),
    .y_new_out(collision_new_y)
  );

  typedef enum {IDLE = 0, COLLISIONS = 1, FORCES = 2} update_state;

  update_state state = IDLE;

  logic [FORCE_SIZE - 1:0] force_x, force_y;
  logic [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES];
  logic [POSITION_SIZE-1:0] num_vertices [NUM_OBSTACLES]; //array of num_vertices
  logic [POSITION_SIZE-1:0] num_obstacles;

  logic  [POSITION_SIZE-1:0] pos_x, pos_y;
  logic  [VELOCITY_SIZE-1:0] vel_x, vel_y;

  logic is_collision;

  logic  [POSITION_SIZE-1:0] dx, dy;
  logic [POSITION_SIZE-1:0] collision_new_x, collision_new_y;

  always_ff @(posedge clk_in) begin
	
	if (rst_in == 1) begin
		state <= IDLE;
	end else begin
		case (state)
			IDLE: begin
				result_out <= 0;
				if (begin_in == 1) begin
					state <= COLLISIONS;
					pos_x <= pos_x_in;
					pos_y <= pos_y_in;
					vel_x <= vel_x_in;
					vel_y <= vel_y_in;

					obstacles <= obstacles_in;
					num_obstacles <= num_obstacles_in;
					num_vertices <= num_vertices_in;
					collision_begin <= 1;

          			dx <= vel_x * DT;
					dy <= vel_y * DT;
				end
			end
			COLLISIONS: begin
				collisions_begin <= 0;
				if (collision_result == 1) begin
					state <= FORCES;
					pos_x <= collision_new_x;
					pos_y <= collision_new_y;
				end
			end
			FORCES: begin
				state <= IDLE;
				new_pos_x <= pos_x;
				new_pos_y <= pos_y;
				new_vel_x <= vel_x;
				new_vel_y <= vel_y;
				result_out <= 1;
			end
		endcase
	end
  end
endmodule