module collision_new_values #(POSITION_SIZE=8, VELOCITY_SIZE=8, ACCELERATION_SIZE=8,  DT = 1, FRICTION=1, RESTITUTION = 15)(
  input  wire clk_in,
  input  wire rst_in,
  input  wire input_valid,
  input  wire signed [POSITION_SIZE-1:0] v1_in [1:0],
  input  wire signed [POSITION_SIZE-1:0] v2_in [1:0],
  input  wire signed [POSITION_SIZE-1:0] pos_x,
  input  wire signed [POSITION_SIZE-1:0] pos_y,
  input  wire signed [VELOCITY_SIZE-1:0] vel_x,
  input  wire signed [VELOCITY_SIZE-1:0] vel_y,
  input  wire signed [POSITION_SIZE-1:0] dx,
  input  wire signed [POSITION_SIZE-1:0] dy,
  output logic signed [POSITION_SIZE - 1:0] x_new_out,
  output logic signed [POSITION_SIZE - 1:0] y_new_out,
  output logic signed [VELOCITY_SIZE-1:0] vx_new_out,
  output logic signed [VELOCITY_SIZE-1:0] vy_new_out,
  output logic signed [POSITION_SIZE-1:0] x_int_out,
  output logic signed [POSITION_SIZE-1:0] y_int_out,
  output logic signed [ACCELERATION_SIZE-1:0] acceleration_x_out,
  output logic signed [ACCELERATION_SIZE-1:0] acceleration_y_out,
  output logic output_valid
  
);
	typedef enum {IDLE = 0, CALCULATE = 1} coll_state;
	coll_state state = IDLE;
	//logic signed [POSITION_SIZE-1:0] dx,dy;
	logic signed [POSITION_SIZE-1:0] v1 [1:0];
	logic signed [POSITION_SIZE-1:0] v2 [1:0];
	logic signed [2 * POSITION_SIZE:0] t1;
	logic signed [2 * POSITION_SIZE:0] t2;
	logic signed [2*POSITION_SIZE + 1 - 1:0] x_num, y_num, denom;
	logic signed [POSITION_SIZE+1 -1:0] rise,run;
	logic signed [2 * POSITION_SIZE+3-1:0] v_mag;
	logic signed [POSITION_SIZE- 1:0] x_new, y_new;
  	logic signed [VELOCITY_SIZE-1:0] vx_new, vy_new;
  	logic signed [POSITION_SIZE-1:0] x_int, y_int;
	logic signed [POSITION_SIZE + VELOCITY_SIZE + 2  -1:0] v_parr, v_perp;
	logic signed [2 * POSITION_SIZE + VELOCITY_SIZE + 3 -1:0] v_parr_x,v_parr_y, v_perp_x,v_perp_y;
	logic signed [ACCELERATION_SIZE-1:0] acceleration_x, acceleration_y;
	logic signed [1:0] side_adjust; 
	logic signed [2*POSITION_SIZE + 2  -1:0] r_parr, r_perp;
	logic signed [3 * POSITION_SIZE + 3 -1:0] r_parr_x,r_parr_y, r_perp_x,r_perp_y;
    logic on_line;
	

	assign v_mag = run*run + rise * rise;
	assign rise = (v2[1]-v1[1]);
	assign run = (v2[0]-v1[0]);
	assign denom = dy*run-dx*rise;
	assign t1 = (dy*pos_x-dx*pos_y);
	assign t2 = (v2[0]*v1[1] - v1[0]*v2[1]);
	assign x_num = run*t1 + dx*t2;
	assign y_num = ~(rise*(dx*pos_y-dy*pos_x) + dy*((v2[1]*v1[0] - v1[1]*v2[0]))) + 2'sd1;//-(t2*dy - t1*(v2[1] - v1[0]));
	
	assign v_parr = vel_x * run + vel_y*rise;
	assign v_parr_x = v_parr * run;
	assign v_parr_y = v_parr * rise;
	assign v_perp = vel_x * rise - vel_y*run;
	assign v_perp_x = v_perp * rise;
	assign v_perp_y = ~(v_perp * run) + 2'sd1;
    
	//assign r_x = x + d - x_i;
	//assign r_y = x + d - x_i;

	//assign r_parr = (denom * (pos_x + dx) - x_num) * run + (denom * (pos_y + dy) - y_num) * rise;
	assign r_parr = ((pos_x + dx - x_int) * run + (pos_y + dy - y_int) * rise);
	assign r_parr_x = r_parr * run;
	assign r_parr_y = r_parr * rise;
	//assign r_perp = (denom * (pos_x + dx) - x_num) * rise - (denom * (pos_y + dy) - y_num) * run;
	assign r_perp = (pos_x + dx - x_int) * rise - (pos_y + dy - y_int) * run;

	assign r_perp_x = r_perp * rise;
	assign r_perp_y = ~(r_perp * run) + 2'sd1;

    //for testing
    logic signed [POSITION_SIZE-1:0] test1, test2;
    assign test1 = 2 * rise;
    assign test2 = 2 * run;

	always_comb begin
		//negative is right, positive left
        //on_line = (v2_in[0]-v1_in[0]) * (pos_y+dy - v2_in[1]) == (v2_in[1]-v1_in[1]) * (pos_x+dx - v2_in[0]);

		
        v1[0] = v1_in[0];
		v1[1] = v1_in[1];
		v2[0] = v2_in[0];
		v2[1] = v2_in[1];

		x_new = x_int + ((r_parr_x - r_perp_x) / v_mag);
		y_new = y_int + ((r_parr_y - r_perp_y) / v_mag );

		//x_new = (v_mag * x_num + (r_parr_x - r_perp_x)) / (v_mag * denom);
		//y_new = (v_mag * y_num + (r_parr_y - r_perp_y)) / (v_mag * denom);
		//x_new =  (3'sd2 * x_num - denom * (pos_x + dx)) / denom;
		//y_new = (3'sd2 * y_num - denom * (pos_y + dy)) / denom;

		//x_new = (x_num * (run*run + rise*rise) + 2*(denom * (dy + pos_y) - y_num)*rise*run + (denom*(dx + pos_x) - x_num)*(run*run - rise*rise)) / (denom * v_mag);
		//y_new = (y_num * (run*run + rise*rise) + 2*(denom * (dx + pos_x) -x_num)*rise*run + (denom*(dy + pos_y) - y_num)*(run*run - rise*rise)) / (denom * v_mag);
		//vx_new = (vel_x * (run*run - rise*rise) + 2*vel_y*rise*run) / v_mag;
		//vy_new = (vel_y * (run*run - rise*rise) + 2*vel_x*rise*run) / v_mag;
		//vx_new = (v_parr_x * FRICTION + v_perp_x *16)/ (v_mag * FRICTION * 16);
		//vy_new = (v_parr_y * FRICTION + v_perp_y *16)/ (v_mag * FRICTION * 16);

		//want friction that can be 0 and and increases slowly
		vx_new = (v_parr_x - v_perp_x) / v_mag;
		vy_new = (v_parr_y - v_perp_y) / v_mag;
		x_int = x_num / denom;
		y_int = y_num / denom;
		acceleration_x = (~($signed(FRICTION) * v_parr_x)+2'sd1) / (v_mag * 5'sd16);
		acceleration_y = (~($signed(FRICTION) * v_parr_y)+2'sd1) / (v_mag * 5'sd16);
	end 
	
	always_ff @(posedge clk_in) begin
        output_valid <= 0;
		case (state)
			IDLE: begin
				output_valid <= 0;
				if (input_valid) begin
					state <= CALCULATE;
				end
			end
			CALCULATE: begin
				if (1 == 1) begin	 
					x_new_out <= x_new;
					y_new_out <= y_new;
					vx_new_out <= vx_new;
					vy_new_out <= vy_new;
					x_int_out <= x_int;
					y_int_out <= y_int;
					acceleration_x_out <= acceleration_x;
					acceleration_y_out <= acceleration_y;
					output_valid <= 1;
					state <= IDLE;
				end
			end
		endcase
	end	
	
endmodule