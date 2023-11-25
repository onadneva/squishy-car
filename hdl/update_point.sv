module update_point #(parameter DT = 1, parameter POSITION_SIZE=8, parameter VELOCITY_SIZE, parameter FORCE_SIZE =8, parameter NUM_VERTICES=5, parameter NUM_OBSTACLES=5)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire [POSITION_SIZE-1:0] obstacles_in [1:0][NUM_VERTICES][NUM_OBSTACLES],
  input  wire [POSITION_SIZE-1:0] all_num_vertices_in [NUM_OBSTACLES], //array of num_vertices
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

  typedef enum {IDLE = 0, COLLISIONS = 1, FORCES = 2} update_state;

  update_state state = IDLE;

  logic signed [FORCE_SIZE - 1:0] force_x, force_y;
  logic [POSITION_SIZE-1:0] obstacles [1:0][NUM_VERTICES][NUM_OBSTACLES];
  logic [POSITION_SIZE-1:0] all_num_vertices [NUM_OBSTACLES]; //array of num_vertices
  logic [POSITION_SIZE-1:0] num_obstacles;

  logic  signed [POSITION_SIZE-1:0] pos_x, pos_y;
  logic  signed [VELOCITY_SIZE-1:0] vel_x, vel_y;

  logic is_collision;

  //logic  [POSITION_SIZE-1:0] dx, dy;
  //logic [POSITION_SIZE-1:0] collision_new_x, collision_new_y;

  logic [POSITION_SIZE-1:0] num_vertices;
  logic signed [POSITION_SIZE-1:0] x_new,y_new;
  logic signed [POSITION_SIZE-1:0] obstacle [1:0][NUM_VERTICES];
  logic [NUM_OBSTACLES-1:0] obstacle_count;
  logic was_collision, begin_do;
  logic any_collision;

do_collision #(DT, POSITION_SIZE,VELOCITY_SIZE, NUM_VERTICES) collision_doer (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_do),
    .obstacle_in(obstacle),
    .num_vertices(num_vertices),
    .pos_x_in(pos_x),
    .pos_y_in(pos_y),
    .vel_x_in(vel_x),
    .vel_y_in(vel_y),
    //.ready(ready),
    .result_out(collision_result),
    .x_new(x_new),
    .y_new(y_new),
	.was_collision(was_collision)
  );

  always_ff @(posedge clk_in) begin
	
	if (rst_in == 1) begin
		state <= IDLE;
	end else begin
		case (state)
			IDLE: begin
				begin_do <= 0;
				result_out <= 0;
				if (begin_in == 1) begin
					state <= COLLISIONS;
					any_collision <= 0;
					pos_x <= pos_x_in;
					pos_y <= pos_y_in;
					vel_x <= vel_x_in;
					vel_y <= vel_y_in;

					//obstacles <= obstacles_in;
					num_obstacles <= num_obstacles_in;
					for (int i = 0; i < NUM_OBSTACLES; i = i + 1) begin
						all_num_vertices[i] <= all_num_vertices_in[i];
  					end



					for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
						obstacle[0][i] <= obstacles_in[0][i][0];
						obstacle[1][i] <= obstacles_in[1][i][0];
  					end
				   num_vertices <= all_num_vertices_in[0];
				   obstacle_count <= 1;
				   begin_do <= 1; //start the doer module
				   //pos_x <= pos_x_in;
				   //pos_y <= pos_y_in;
				end
			end
			COLLISIONS: begin
				if (collision_result == 1) begin
					if (was_collision == 1) begin //was a collision, update positions and check again
						begin_do <= 1;
						any_collision <= 1;
						obstacle_count <= 1;
						for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
							obstacle[0][i] <= obstacles_in[0][i][0];
							obstacle[1][i] <= obstacles_in[1][i][0];
						end
						num_vertices <= all_num_vertices[0];
						pos_x <= x_new;
						pos_y <= y_new;
					end else begin
						if (obstacle_count == num_obstacles) begin //no collision and all obstacles checked
							state <= FORCES;
							if (any_collision == 0) begin
								pos_x <= pos_x + vel_x * DT;
								pos_y <= pos_y + vel_y * DT;
							end
						end else begin //no collision, check next obstacle
							obstacle_count <= obstacle_count + 1;
							begin_do <= 1;
							for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
								obstacle[0][i] <= obstacles_in[0][i][obstacle_count];
								obstacle[1][i] <= obstacles_in[1][i][obstacle_count];
							end
							num_vertices <= all_num_vertices[obstacle_count];
							end
						end
				end else begin
					begin_do <= 0;
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