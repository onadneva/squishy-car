module do_collision #(DT = 1, POSITION_SIZE = 8, VELOCITY_SIZE=8, NUM_VERTICES = 5)( //one obstacle
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire [POSITION_SIZE-1:0] obstacle_in [1:0][NUM_VERTICES-1:0],
  input  wire [POSITION_SIZE-1:0] num_vertices,
  input  wire [POSITION_SIZE-1:0] pos_x_in,
  input  wire [POSITION_SIZE-1:0] pos_y_in,
  input  wire [VELOCITY_SIZE-1:0] vel_x_in,
  input  wire [VELOCITY_SIZE-1:0] vel_y_in,
  output logic ready,
  output logic result_out,
  output logic [POSITION_SIZE-1:0] x_new,
  output logic [POSITION_SIZE-1:0] y_new,
  output logic was_collision
);

typedef enum {IDLE = 0, CALCULATE = 1, RESULT=2} do_collision_state;
do_collision_state state = IDLE;
parameter COLL_LATENCY = 1;

logic signed [POSITION_SIZE-1:0] v1 [1:0];
logic signed [POSITION_SIZE-1:0] v2 [1:0];
logic collision;
collision_checker#(POSITION_SIZE, VELOCITY_SIZE, DT) collision_check (
		.clk_in(clk_in),
  		.rst_in(rst_in),
		.v1(v1),
		.v2(v2),
		.pos_x_in(pos_x),
		.pos_y_in(pos_y),
		.vel_x_in(vel_x),
		.vel_y_in(vel_y),
		.x_new(x_n),
		.y_new(y_n),
		.collision(collision)
);

logic signed [POSITION_SIZE-1:0] obstacle [1:0][NUM_VERTICES-1:0]; //current obstacle
logic [POSITION_SIZE-1:0] vertex_num; // the current vertex we're on (can make smaller)
logic signed [POSITION_SIZE-1:0] pos_x,pos_y, x_n,y_n;
logic signed [VELOCITY_SIZE-1:0] vel_x,vel_y;
logic [8:0] collision_wait;
//for testing
logic [POSITION_SIZE-1:0] v1x,v1y,v2x,v2y, o13;
assign v1x = v1[0];
assign v1y = v1[1];
assign v2x = v2[0];
assign v2y = v2[1];
assign o13 = obstacle[1][3];
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

					vel_x <= vel_x_in;
					vel_y <= vel_y_in;

					collision_wait <= 0;
					//grab first two vertices
					v1[0] <= obstacle_in[0][0];
					v1[1] <= obstacle_in[1][0];
					v2[0] <= obstacle_in[0][1];
					v2[1] <= obstacle_in[1][1];

				end
			end
			CALCULATE: begin
				if (collision_wait == COLL_LATENCY) begin
					vertex_num <= vertex_num + 1;
					collision_wait <= 0;

					if (collision == 1 || vertex_num == num_vertices) begin //assumes that you don't move too far off the screen
						if (collision == 1) begin
							x_new <= x_n;
							y_new <= y_n;
							was_collision <= 1;
						end else begin
							x_new <= pos_x + vel_x * DT;
							y_new <= pos_y + vel_y * DT;
						end

						state <= RESULT;
					end else if (vertex_num == num_vertices -1) begin
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
				end else begin
					collision_wait <= collision_wait + 1;
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


module collision_checker #(POSITION_SIZE=8, VELOCITY_SIZE=8, DT = 1)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire signed [POSITION_SIZE-1:0] v1 [1:0],
  input  wire signed [POSITION_SIZE-1:0] v2 [1:0],
  input  wire signed [POSITION_SIZE-1:0] pos_x_in,
  input  wire signed [POSITION_SIZE-1:0] pos_y_in,
  input  wire signed [VELOCITY_SIZE-1:0] vel_x_in,
  input  wire signed [VELOCITY_SIZE-1:0] vel_y_in,
  output logic collision,
  output logic signed [POSITION_SIZE - 1:0] x_new,
  output logic signed [POSITION_SIZE - 1:0] y_new
);
	typedef enum {IDLE = 0, CALC = 1} coll_state;
	logic signed [POSITION_SIZE-1:0] dx,dy;
	logic signed [2 * POSITION_SIZE:0] t1;
	logic signed [2 * POSITION_SIZE:0] t2;
	logic signed [2*POSITION_SIZE + 1 - 1:0] x_num, y_num, denom;

	logic coll;
	coll_state state = IDLE;
	assign dx = vel_x_in * DT;
	assign dy = vel_y_in * DT;
	assign denom = dy*(v2[0]-v1[0])-dx*(v2[1]-v1[1]);
	assign t1 = (dy*pos_x_in-dx*pos_y_in);
	assign t2 = (v2[0]*v1[1] - v1[0]*v2[1]);
	assign x_num = (v2[0]-v1[0])*t1 + dx*t2;
	assign y_num = -(t2*dy - t1*(v2[1] - v1[0]));
	always_comb begin
      
		collision = ((denom * pos_x_in <= x_num & denom * (pos_x_in + dx) >= x_num) | (denom * pos_x_in >= x_num & denom * (pos_x_in + dx) <= x_num)) & ((denom * pos_y_in <= y_num & denom * (pos_y_in + dy) >= y_num) | (denom * pos_y_in >= y_num & denom * (pos_y_in + dy) <= y_num));
		x_new = (x_num * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1])) + 2 * (denom * (dy + pos_y_in) - y_num) * (v2[1]-v1[1]) * (v2[0]-v1[0]) + (denom * (dx + pos_x_in) - x_num) * ((v2[0]-v1[0]) * (v2[0]-v1[0]) - (v2[1]-v1[1]) * (v2[1]-v1[1]))) / (denom * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1])));
		y_new = (y_num * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1])) + 2 * (denom * (dx + pos_x_in) - x_num) * (v2[1]-v1[1]) * (v2[0]-v1[0]) + (denom * (dy + pos_y_in) - y_num) * ((v2[0]-v1[0]) * (v2[0]-v1[0]) - (v2[1]-v1[1]) * (v2[1]-v1[1]))) / (denom * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1])));
		//x_new = (x_n um * ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1])) + 2 * (denom * (dy + pos_y_in) - y_num) * (v2[1]-v1[1]) * (v2[0]-v1[0]) + (denom * (dx + pos_x_in) - x_num) * ((v2[0]-v1[0]) * (v2[0]-v1[0]) - (v2[1]-v1[1]) * (v2[1]-v1[1]))) /  ((v2[0]-v1[0]) * (v2[0]-v1[0]) + (v2[1]-v1[1]) * (v2[1]-v1[1]));

	end 

	
	always_ff @(posedge clk_in) begin
		//collision <= coll;
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