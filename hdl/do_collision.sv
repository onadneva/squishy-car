module do_collision #(DT = 1, POSITION_SIZE = 8, VELOCITY_SIZE=8, ACCELERATION_SIZE = 8, NUM_VERTICES = 5)( //one obstacle
  input  wire clk_in,
  input  wire rst_in,
  input  wire begin_in,
  input  wire [POSITION_SIZE-1:0] obstacle_in [1:0][NUM_VERTICES-1:0],
  input  wire [POSITION_SIZE-1:0] num_vertices,
  input  wire [POSITION_SIZE-1:0] pos_x_in,
  input  wire [POSITION_SIZE-1:0] pos_y_in,
  input  wire [VELOCITY_SIZE-1:0] vel_x_in,
  input  wire [VELOCITY_SIZE-1:0] vel_y_in,
  input  wire [POSITION_SIZE-1:0] dx_in,
  input  wire [POSITION_SIZE-1:0] dy_in,
  //output logic ready,
  output logic result_out,
  output logic signed [POSITION_SIZE-1:0] x_new,
  output logic signed [POSITION_SIZE-1:0] y_new,
  output logic signed [VELOCITY_SIZE-1:0] vel_x_new,
  output logic signed [VELOCITY_SIZE-1:0] vel_y_new,
  output logic signed [POSITION_SIZE-1:0] x_int_out,
  output logic signed [POSITION_SIZE-1:0] y_int_out,
  output logic signed [ACCELERATION_SIZE-1:0] acceleration_x,
  output logic signed [ACCELERATION_SIZE-1:0] acceleration_y,
  output logic was_collision
);

typedef enum {IDLE = 0, COLLISION = 1, CALCULATE = 2, NEXT_VERTEX = 3, RESULT=4} do_collision_state;
do_collision_state state = IDLE;
logic signed [POSITION_SIZE-1:0] v1 [1:0];
logic signed [POSITION_SIZE-1:0] v2 [1:0];
logic signed [POSITION_SIZE-1:0] pos_x,pos_y, dx,dy,x_n,y_n, x_int,y_int;
logic signed [VELOCITY_SIZE-1:0] vel_x,vel_y, vx_n,vy_n;
logic signed [ACCELERATION_SIZE-1:0] coll_acc_x, coll_acc_y;

logic collision, new_values_result, begin_new_values;


collision_new_values #(POSITION_SIZE, VELOCITY_SIZE, ACCELERATION_SIZE, DT) new_values (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .input_valid(begin_new_values),
    .v1_in(v1),
    .v2_in(v2),
    .pos_x(pos_x),
    .pos_y(pos_y),
    .vel_x(vel_x),
    .vel_y(vel_y),
    .dx(dx),
    .dy(dy),
    .x_new_out(x_n),
    .y_new_out(y_n),
    .vx_new_out(vx_n),
    .vy_new_out(vy_n),
    .x_int_out(x_int),
    .y_int_out(y_int),
    .acceleration_x_out(coll_acc_x),
    .acceleration_y_out(coll_acc_y),
    .output_valid(new_values_result)
  );

collision_checker #(POSITION_SIZE, DT) collision_check (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .v1(v1),
    .v2(v2),
    .pos_x(pos_x),
    .pos_y(pos_y),
    .dx(dx),
    .dy(dy),
    .collision(collision)
  );

localparam VERTEX_COUNT_SIZE = NUM_VERTICES;//$clog(NUM_VERTICES);
logic [VERTEX_COUNT_SIZE-1:0] vertex_num, last_vertex_num; // the current vertex we're on (can make smaller)
logic [VERTEX_COUNT_SIZE-1:0] collision_vertex;
logic signed [POSITION_SIZE-1:0] obstacle [1:0][NUM_VERTICES-1:0]; //current obstacle
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
					state <= COLLISION;
					collision_vertex <= 0;
					last_vertex_num <= 0;
					vertex_num <= 1;

					for (int i = 0; i < NUM_VERTICES; i = i + 1) begin
						obstacle[0][i] <= obstacle_in[0][i];
						obstacle[1][i] <= obstacle_in[1][i];
  					end

					//collision variables initialization
					pos_x <= pos_x_in;
					pos_y <= pos_y_in;
					vel_x <= vel_x_in;
					vel_y <= vel_y_in;
					dx <= dx_in;
					dy <= dy_in;

					//grab first two vertices
					v1[0] <= obstacle_in[0][0];
					v1[1] <= obstacle_in[1][0];
					v2[0] <= obstacle_in[0][1];
					v2[1] <= obstacle_in[1][1];

					acceleration_x <= 0;
					acceleration_y <= 0;

				end
			end
			COLLISION: begin
				
				if (collision == 1) begin
					state <= CALCULATE;
					collision_vertex <= last_vertex_num;
					begin_new_values <= 1;
					was_collision <= 1;
				end else begin
					state <= NEXT_VERTEX;
					begin_new_values <= 0;
				end
			end
			CALCULATE: begin
				begin_new_values <= 0;
				if (new_values_result == 1) begin
					state <= NEXT_VERTEX;
					acceleration_x <= acceleration_x + coll_acc_x;
					acceleration_y <= acceleration_y + coll_acc_y;
					//output for if this is the last collision
					x_new <= x_n;
					y_new <= y_n;
					vel_x_new <= vx_n;
					vel_y_new <= vy_n;
					x_int_out <= x_int;
					y_int_out <= y_int;
					//setup for next collision check
					pos_x <= x_int;
					pos_y <= y_int;
					vel_x <= vx_n;
					vel_y <= vy_n;
					dx <= x_n - x_int;
					dy <= y_n - y_int;
				end
			end
			NEXT_VERTEX: begin
				if (collision_vertex == vertex_num) begin
					state <= RESULT;
				end else begin
					state <= COLLISION;
					vertex_num <= (vertex_num == num_vertices-1)?0:vertex_num + 1;
					last_vertex_num <= vertex_num;

					v1[0] <= obstacle[0][vertex_num];
					v1[1] <= obstacle[1][vertex_num];

					if (vertex_num == num_vertices -1) begin
						v2[0] <= obstacle[0][0];
						v2[1] <= obstacle[1][0];
					end else begin
						v2[0] <= obstacle[0][vertex_num+1];
						v2[1] <= obstacle[1][vertex_num+1];
					end
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



module collision_checker #(POSITION_SIZE=8,  DT = 1)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire signed [POSITION_SIZE-1:0] v1 [1:0],
  input  wire signed [POSITION_SIZE-1:0] v2 [1:0],
  input  wire signed [POSITION_SIZE-1:0] pos_x,
  input  wire signed [POSITION_SIZE-1:0] pos_y,
  input  wire signed [POSITION_SIZE-1:0] dx,
  input  wire signed [POSITION_SIZE-1:0] dy,
  output logic collision 
);
	typedef enum {IDLE = 0, CALCULATE = 1} coll_state;
	coll_state state = IDLE;

	logic signed [2 * POSITION_SIZE:0] t1;
	logic signed [2 * POSITION_SIZE:0] t2;
	logic signed [2*POSITION_SIZE + 1 - 1:0] x_num, y_num, denom;
	logic signed [POSITION_SIZE+1 -1:0] rise,run;
	logic coll_x,coll_y,not_start, going_inside;

	assign v_mag = run*run + rise * rise;
	assign rise = (v2[1]-v1[1]);
	assign run = (v2[0]-v1[0]);
	assign denom = dy*run-dx*rise;
	assign t1 = (dy*pos_x-dx*pos_y);
	assign t2 = (v2[0]*v1[1] - v1[0]*v2[1]);
	assign x_num = run*t1 + dx*t2;
	assign y_num = -(rise*(dx*pos_y-dy*pos_x) + dy*((v2[1]*v1[0] - v1[1]*v2[0])));

	always_comb begin
    	//collision happens if the intersection is within the line (excluding sqrt(2) from starting point)
		coll_x = ((denom * pos_x <= x_num  & denom * (pos_x + dx) >= x_num) 
			| (denom * pos_x >= x_num & denom * (pos_x + dx) <= x_num));
		coll_y = ((denom * pos_y <= y_num & denom * (pos_y + dy) >= y_num) 
			| (denom * pos_y >= y_num & denom * (pos_y+ dy) <= y_num));
		going_inside = (run * dy - rise * dx) <= 0;
		collision = denom != 0 & coll_x & coll_y & going_inside;
		//want to always negate collision if going_out
	end 
	
endmodule

//exact startpoint on line
//m * pos_x + b = pos_y
//rise * pos_x = run * pos_y - run * b
//rise * pos_x = run * pos_y + rise * v2[0]- run * v2[1]
//rise * (pos_x - v2[0]) = run * (pos_y - v2[1]) ****result
//-run * b = rise * v2[0]- run * v2[1]
// rise * v2[0] = run * v2[1] - run * b
// m * v2[0] + b = v2[1]
//startpoint within range of line
//(((denom * pos_x - x_num)*(denom * pos_x - x_num) + (denom * pos_y - y_num)*(denom * pos_y - y_num)) > (2*denom*denom));

//need the initial position for the next one to be the intersection from the last one. 
  //Problem: the update_point module needs to know the information or it needs to be stored elsewhere and signals to know when to use it.
  //1) Add new outputs for the intersection
  //  Con: rounding error from division could cause artificial collisions
  //  PRO: least signal change, parallelizing is fine
  //2) Have registers hold collision values and a new input that says whether to use old values
  //  Con: more registers, need to change logic in module, redundant or useless signalls, parallelizing becomes harder
  //  Pro: no false collisions, less signal additions

module rounded_division #(DIVIDEND_SIZE,DIVISOR_SIZE,QUOTIENT_SIZE)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire signed [DIVIDEND_SIZE-1:0] dividend,
  input  wire signed [DIVISOR_SIZE-1:0] divisor,
  input  wire signed [QUOTIENT_SIZE-1:0] quotient
);

assign quotient = ((2 * (dividend % divisor)) > dividend)?1:0;

endmodule