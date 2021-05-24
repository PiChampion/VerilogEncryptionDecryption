module proj2(clk, rst, start, private_key, public_key, message_val, cal_done, cal_val);

	input clk, start, rst;
	input [15:0]private_key, public_key, message_val;
	output reg cal_done;
	output reg [15:0]cal_val;
	
	reg [3:0]state;
	reg [15:0]private, public, message;
	reg ldexp, ldmod;
	reg [15:0] Amod, Bmod;
	reg [15:0] Aexp, Bexp;
	wire [15:0] Omod;
	wire [31:0] Oexp;
	
	parameter Capture_State=4'b0000;
	parameter Exponent_state1=4'b0001;
	parameter Exponent_state2=4'b0010;
	parameter Exponent_state3=4'b0011;
	parameter Mod_state1=4'b0100;
	parameter Mod_state2=4'b0101;
	parameter Mod_state3=4'b0110;
	parameter Cal_done_state1=4'b0111;
	parameter Cal_done_state2=4'b1000;
	parameter Cal_done_state3=4'b1001;

	myexpo exp(clk, rst, ldexp, Aexp, Bexp, Oexp);
	mymodulo mod(clk, rst, ldmod, Amod, Bmod, Omod);

	always@(posedge clk) begin
		if(rst) begin
			cal_val<=0;
			cal_done<=0;
			private<=0;
			public<=0;
			message<=0;
			ldexp<=0;
			ldmod<=0;
			Amod<=0;
			Bmod<=0;
			Aexp<=0;
			Bexp<=0;
			state<=Capture_State;
		end
		else begin
			case(state)
				Capture_State: begin
					if(start) begin
						cal_val<=0;
						cal_done<=0;
						private<=private_key;
						public<=public_key;
						message<=message_val;
						state<=Exponent_state1;
					end
					else begin
						state<=0;
					end
				end
				Exponent_state1: begin
					Aexp<=message;
					Bexp<=private;
					ldexp<=1;
					state<=Exponent_state2;
				end
				Exponent_state2: begin
					ldexp<=0;
					state<=Exponent_state3;
				end
				Exponent_state3: begin
					if(exp.done) state<=Mod_state1;
					else state<=Exponent_state2;
				end
				Mod_state1: begin
					Amod<=Oexp[15:0];
					Bmod<=public;
					ldmod<=1;
					state<=Mod_state2;
				end
				Mod_state2: begin
					ldmod<=0;
					state<=Mod_state3;
				end
				Mod_state3: begin
					if(mod.done) state<=Cal_done_state1;
					else state<=Mod_state2;
				end
				Cal_done_state1: begin
					cal_done<=1;
					cal_val<=Omod;
					state<=Cal_done_state2;
				end
				Cal_done_state2: begin
					cal_done<=1;
					cal_val<=Omod;
					state<=Cal_done_state3;
				end
				Cal_done_state3: begin
					cal_done<=1;
					cal_val<=Omod;
					state<=Capture_State;
				end
				default: state<=state;
			endcase
		end
	end

endmodule


module fullsubtractor (input [15:0] x, input [15:0] y, output [15:0] o);

	assign o=y-x;
	
endmodule


module mymodulo(clk, rst, ld, A, B, O);

	input clk, rst, ld;//enable
	input [15:0]A;
	input [15:0]B;
	output reg[15:0]O;//output
	
	reg state;
	reg done;
	reg [15:0] a;
	reg [15:0] b;
	wire [15:0] subtracted;
	
	fullsubtractor subtracting(b,a,subtracted);
	
always @(posedge clk or posedge rst)
begin
	if(rst) begin
		O<=16'b0;
		state<=0;
		done<=0;
	end
	else begin
		case(state)
			0:begin
				//done<=0;
				if(ld==1) begin
					a<=A;
					b<=B;
					done<=0;
					state<=1;
				end
				else begin
					state<=0;
				end
			end
			1:begin
				if(a >= b)
				begin
					//O and A go to Full subtractor
					//shifter (a,C,o);
					//full_adder (o==shifted a,O,subtracted);
					a<=subtracted;
					state<=1;
				end
				else begin
					done<=1;
					O<=a;
					state<=0;
				end
			end
			default: state <= state;
		endcase
	 end
end
endmodule

module fulladder (input [31:0] x, input [31:0] y, output [31:0] o);

	assign o=y+x;
	
endmodule

module shifter (input [15:0] in, input [3:0] n, output [31:0] o);

	reg [31:0] out_reg;
	assign o = out_reg;
	
	always @(n or in)
	case (n)
		15 : out_reg <= { in[15:0],15'b0};
		14 : out_reg <= { in[15:0],14'b0};
		13 : out_reg <= { in[15:0],13'b0};
		12 : out_reg <= { in[15:0],12'b0};
		11 : out_reg <= { in[15:0],11'b0};
		10 : out_reg <= { in[15:0],10'b0};
		9 : out_reg <= { in[15:0],9'b0};
		8 : out_reg <= { in[15:0],8'b0};
		7 : out_reg <= { in[15:0],7'b0};
		6 : out_reg <= { in[15:0],6'b0};
		5 : out_reg <= { in[15:0],5'b0};
		4 : out_reg <= { in[15:0],4'b0};
		3 : out_reg <= { in[15:0],3'b0};
		2 : out_reg <= { in[15:0],2'b0};
		1 : out_reg <= { in[15:0],1'b0};
		0 : out_reg <= in[15:0];
	endcase
	
endmodule

module myexpo(clk, rst, ld, A, B, O);

	input clk, rst, ld;//enable
	input [15:0]A;
	input [15:0]B;
	output reg[31:0]O;//output
	
	reg [3:0]C;//counter
	reg [15:0]E;
	reg [2:0]state;
	reg done;
	reg [15:0] a;
	reg [15:0] b;
	reg [31:0] o;
	wire [31:0] shifted; 
	wire [31:0] added;
	
	shifter shifting(a,C,shifted);
	fulladder adding(o,O,added);
	
always @(posedge clk or posedge rst)
begin
	if(rst) begin
		O<=16'b0;
		state<=0;
	end
	else begin
		case(state)
			0:begin
				//done<=0;
				if(ld==1) begin
					a<=A;
					b<=A;
					E<=B;
					C<=0;
					done<=0;
					state<=1;
				end
				else begin
					state<=0;
				end
			end
			1:begin
				if(E==0) begin
					O <= 1;
					done <= 1;
					state <= 0;
				end
				else if(E==1) begin
					O <= a;
					done <= 1;
					state <= 0;
				end
				else if(b[C]==1)
				begin
					//O and A go to Full adder/shifter
					//shifter (a,C,o);
					//full_adder (o==shifted a,O,added);
					a<=A;
					o<=shifted;
					C<=C+1;
					state<=2;
				end
				else begin
					//O and zero to fulladder
					//full_adder (o==0,O,added);
					o<=0;
					C<=C+1;
					state<=2;
				end
			end
			2:begin
				//fulladder (a, b, O);
				O<=added;
				if(C==done) begin
					state<=3;
					E<=E-1;
				end
				else
					state<=1;
			end
			3:begin
				if(E==1)
					state <= 4;
				else begin
					b<=O;
					O<=0;
					state <= 1;
				end
			end
			4:begin
				done<=1;
				state<=0;
			end
			default: state <= state;
		endcase
	 end
end
endmodule


module proj2_tb();

	reg clk, rst, start;
	reg [15:0]private_key, public_key, message_val;
	wire cal_done;
	wire [15:0]cal_val;

	proj2 dut(clk, rst, start, private_key, public_key, message_val, cal_done, cal_val);

	always #5 clk = ~clk;
	initial
	begin
		clk=0;
		rst=1'b0;
		#4 rst = 1'b1;
		#6 rst = 1'b0;
		begin
			start=1;
			message_val=9;
			private_key=3;
			public_key=33;
			#10 start=0;
			#2000 $display ("Encoding Section:\nprivate key = %0d, public key = %0d, message = %0d, encrypted value = %0d",private_key,public_key,message_val,cal_val);
			#5 rst = 1'b1;
			#5 rst = 1'b0;
			start=1;
			message_val=3;
			private_key=7;
			public_key=33;
			#10 start=0;
			#4000 $display ("Decoding Section:\nprivate key = %0d, public key = %0d, message = %0d, decrypted value = %0d",private_key,public_key,message_val,cal_val);
		end
		#100 $finish;
	end
endmodule
