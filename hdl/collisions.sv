
module collisions #(DT = 1, POSITION_SIZE = 8,NUM_OBSTACLES = 5, NUM_VERTICES = 5)( //all obstacles
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire [POSITION_SIZE-1:0] obstacles_in [1:0][NUM_VERTICES][NUM_OBSTACLES],
  input  wire [POSITION_SIZE-1:0] num_vertices_in [NUM_OBSTACLES], //array of num_vertices
  input wire [POSITION_SIZE-1:0] num_obstacles_in,
  input  wire [POSITION_SIZE-1:0] pos_x_in,
  input  wire [POSITION_SIZE-1:0] pos_y_in,
  input  wire [POSITION_SIZE-1:0] dx_in,
  input  wire [POSITION_SIZE-1:0] dy_in,
  output logic ready,
  output logic result_out,
  output logic [POSITION_SIZE-1:0] x_new_out,
  output logic [POSITION_SIZE-1:0] y_new_out

);


typedef enum {IDLE = 0, COLLISIONS = 1} collisions_state;
collisions_state state = IDLE;

logic [POSITION_SIZE-1:0] num_vertices, pos_x,pos_y;
logic [POSITION_SIZE-1:0] dx,dy, x_new,y_new;
logic [POSITION_SIZE-1:0] obstacle [1:0][NUM_VERTICES];
logic [NUM_OBSTACLES-1:0] obstacle_count;
logic collision_result, was_collision, begin_do;

do_collision #(DT, POSITION_SIZE, NUM_VERTICES) collision_doer (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .begin_in(begin_do),
    .obstacle_in(obstacle),
    .num_vertices(num_vertices),
    .pos_x_in(pos_x),
    .pos_y_in(pos_y),
    .dx_in(dx),
    .dy_in(dy),
    //.ready(ready),
    .result_out(collision_result),
    .x_new(x_new),
    .y_new(y_new),
	.was_collision(was_collision)
  );

  always_ff @(posedge clk_in) begin
	
	if (rst_in == 1) begin
		state <= IDLE;
		begin_do <= 0;
	end else begin
		case (state)
			IDLE: begin
				begin_do <= 0;
				result_out <= 0;
				if (begin_in) begin 
				   state <= COLLISIONS;
					for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
						obstacle[0][i] <= obstacles_in[0][i][0];
						obstacle[1][i] <= obstacles_in[1][i][0];
  					end
				   num_vertices <= num_vertices_in[0];
				   obstacle_count <= 1;
				   begin_do <= 1; //start the doer module
				   pos_x <= pos_x_in;
				   pos_y <= pos_y_in;
				   dx <= dx_in;
				   dy <= dy_in;
				end
			end
			COLLISIONS: begin
				if (collision_result == 1) begin
					begin_do <= 1;
					if (was_collision == 1) begin
						obstacle_count <= 1;
						for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
							obstacle[0][i] <= obstacles_in[0][i][0];
							obstacle[1][i] <= obstacles_in[1][i][0];
  						end
				   		num_vertices <= num_vertices_in[0];
						pos_x <= x_new;
				   		pos_y <= y_new;
					end else begin
						obstacle_count <= obstacle_count + 1;
						for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
							obstacle[0][i] <= obstacles_in[0][i][obstacle_count];
							obstacle[1][i] <= obstacles_in[1][i][obstacle_count];
  						end


						num_vertices <= num_vertices_in[obstacle_count];
					end

					if (obstacle_count == num_obstacles_in) begin //no more collisions
						result_out <= 1;
						x_new_out <= pos_x;
						y_new_out <= pos_y;
					end
				end else begin
					begin_do <= 0;
				end
			end

		endcase
	end
  end


endmodule



module do_collision #(DT = 1, POSITION_SIZE = 8, NUM_VERTICES = 5)( //one obstacle
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire [POSITION_SIZE-1:0] obstacle_in [1:0][NUM_VERTICES-1:0],
  input  wire [POSITION_SIZE-1:0] num_vertices,
  input  wire [POSITION_SIZE-1:0] pos_x_in,
  input  wire [POSITION_SIZE-1:0] pos_y_in,
  input  wire [POSITION_SIZE-1:0] dx_in,
  input  wire [POSITION_SIZE-1:0] dy_in,
  output logic ready,
  output logic result_out,
  output logic [POSITION_SIZE-1:0] x_new,
  output logic [POSITION_SIZE-1:0] y_new,
  output logic was_collision
);

typedef enum {IDLE = 0, CALCULATE = 1, RESULT=2} do_collision_state;
do_collision_state state = IDLE;

logic signed [POSITION_SIZE-1:0] v1 [1:0];
logic signed [POSITION_SIZE-1:0] v2 [1:0];
logic collision;
collision_checker#(POSITION_SIZE) collision_check (
		.clk_in(clk_in),
  		.rst_in(rst_in),
		.v1(v1),
		.v2(v2),
		.pos_x_in(pos_x),
		.pos_y_in(pos_y),
		.dx_in(dx_in),
		.dy_in(dy_in),
		.x_new(x_new),
		.y_new(y_new),
		.collision(collision)
);
logic signed [POSITION_SIZE-1:0] obstacle [1:0][NUM_VERTICES-1:0]; //current obstacle
logic [POSITION_SIZE-1:0] vertex_num; // the current vertex we're on (can make smaller)
logic signed [POSITION_SIZE-1:0] pos_x,pos_y;
//assume sequential, can parallize later

  always_ff @(posedge clk_in) begin
	
	if (rst_in == 1) begin
		state <= IDLE;
	end else begin
		case (state)
			IDLE: begin
				was_collision <= 0;
				result_out <= 0;
				if (begin_in) begin 
					state <= CALCULATE;

					for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
						obstacle[0][i] <= obstacle_in[0][i];
						obstacle[1][i] <= obstacle_in[1][i];
  					end
					vertex_num <= 1;
					pos_x <= pos_x_in;
					pos_y <= pos_y_in;
					//grab first two vertices
					v1[0] <= obstacle_in[0][0];
					v1[1] <= obstacle_in[1][0];
					v2[0] <= obstacle_in[0][1];
					v2[1] <= obstacle_in[1][1];
				end
			end
			CALCULATE: begin
				vertex_num  <= vertex_num + 1;
				if (vertex_num == num_vertices -1) begin
					v1[0] <= obstacle[0][num_vertices - 1];
					v1[1] <= obstacle[1][num_vertices - 1];
					v2[0] <= obstacle[0][0];
					v2[1] <= obstacle[1][0];
				end else begin
					v1[0] <= obstacle[0][vertex_num];
					v1[1] <= obstacle[1][vertex_num];
					v2[0] <= obstacle[0][vertex_num+1];
					v2[1] <= obstacle[1][vertex_num+1];
				end
				if (collision == 1) begin //assumes that you don't move too far off the screen
					vertex_num <= 0;
					pos_x <= x_new;
					pos_y <= y_new;
					was_collision <= 1;
				end
				if (vertex_num == num_vertices) begin
					state <= RESULT;

				end
			end
			RESULT: begin
				result_out <= 1;
				state <= IDLE;
			end
		endcase
	end
  end



			

endmodule


module collision_checker #(parameter POSITION_SIZE=8)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire signed [POSITION_SIZE-1:0] v1 [1:0],
  input  wire signed [POSITION_SIZE-1:0] v2 [1:0],
  input  wire signed [POSITION_SIZE-1:0] pos_x_in,
  input  wire signed [POSITION_SIZE-1:0] pos_y_in,
  input  wire signed [POSITION_SIZE-1:0] dx_in,
  input  wire signed [POSITION_SIZE-1:0] dy_in,
  output logic collision,
  output logic signed [POSITION_SIZE - 1:0] x_new,
  output logic signed [POSITION_SIZE - 1:0] y_new
);
	typedef enum {IDLE = 0, CALC = 1} coll_state;

	//logic signed [2 * POSITION_SIZE:0] t1;
	//logic signed [2 * POSITION_SIZE:0] t2;
	//logic signed [(2 * POSITION_SIZE+1)*POSITION_SIZE + 1 - 1] x_num, y_num;

	logic coll;
	coll_state state = IDLE;
	assign denom = dy_in*(v2[0]-v1[0])-dx_in*(v2[1]-v1[1]);
	assign t1 = (dy_in*pos_x_in-dx_in*pos_y_in);
	assign t2 = (v2[0]*v1[1] - v1[0]*v2[1]);
	assign x_num = (v2[0]-v1[0])*t1 + dx_in*t2;
	assign y_num = t2*dy_in - t1*(v2[1] - v1[0]);
	always_comb begin
		coll = (denom * pos_x_in < x_num && denom * (pos_x_in + dx_in) > x_num) && (denom * pos_y_in < y_num && denom * (pos_y_in + dy_in) > y_num);
		x_new = (x_num * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1])) + 2 * (denom * (dy_in + pos_y_in) - y_num) * (v2[1]-v1[1]) * (v2[0]-v1[0]) + (denom * (dx_in + pos_x_in) - x_num) * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1]))) / (denom * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1])));
		y_new = (y_num * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1])) + 2 * (denom * (dx_in + pos_x_in) - x_num) * (v2[1]-v1[1]) * (v2[0]-v1[0]) + (denom * (dy_in + pos_y_in) - y_num) * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1]))) / (denom * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1])));
	end
	
	always_ff @(posedge clk_in) begin
		collision <= coll;
		/*
		if (rst_in) begin
			collision <= 0;
			state <= IDLE;
		end else begin
			case(state)
				IDLE: begin 
					collision <= 0;
					if (valid_in == 1) begin
						state <= CALC;
					end
				end
				CALC: begin
					if (coll == 1) begin
						collision <= 1;
						state <= IDLE;
					end
				end
			endcase
		end */
		
	end
	
endmodule