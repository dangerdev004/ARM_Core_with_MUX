`timescale 1ps/1ps

module mac #(
	parameter X = 32,
	parameter Y = 32
) (
	input clk, rst, en,
	input signed [X-1:0] M,
	input signed [Y-1:0] Q,
	output reg signed [X+Y-1:0] P
);
	wire signed [X+Y-1:0] AB;
	wire signed [X+Y-1:0] sum;
	wire signed [X+Y-1:0] P_reg;

	booth #(.X(X), .Y(Y)) booth_inst (
		.M(M),
		.Q(Q),
		.P(AB)
	);

	conditional_adder #(.N(X+Y)) adder_inst (
		.a(P),
		.b(AB),
		.cin(1'b0),
		.sum(sum),
		.cout()
	);

	mux #(.n(1), .w(X+Y)) mux_inst (
		.in({sum, P}),
		.sel(en),
		.out(P_reg)
	);

	always @(posedge clk or posedge rst)
	begin
		if (rst)
			P <= 0;
		else
			P <= P_reg;
	end

endmodule


module booth #(
	parameter X = 32,
	parameter Y = 32
	) (
	input  signed [X-1:0] M,
	input  signed [Y-1:0] Q,
	output signed [X+Y-1:0] P
);
	integer i;
	reg signed [X+Y+3:0] A, S, P_t;

	always @(*)
	begin

		A   =  $signed(M) <<< (Y+1);
		S   = -($signed(M) <<< (Y+1));
		P_t = {{X{1'b0}}, Q, 1'b0};

		for (i = 0; i < Y/2; i = i + 1)
		begin
			case (P_t[2:0])
				3'b001, 3'b010: P_t = P_t + A;
				3'b011: P_t = P_t + (A <<< 1);
				3'b100: P_t = P_t + (S <<< 1);
				3'b101, 3'b110: P_t = P_t + S;
				default: P_t = P_t + {(X+Y+4){1'b0}};
			endcase

			P_t = P_t >>> 2;
		end
	end


	assign P = P_t[X+Y:1];

endmodule

module conditional_adder #(
	parameter N = 32
)(
	input signed [N-1:0]a, b,
	input cin,
	output signed [N-1:0]sum,
	output cout
);

	wire [N-1:0]out1, out2;
	wire out3, out4;

	rca rca1(a, b, 1'b0, out1, out3);
	rca rca2(a, b, 1'b1, out2, out4);

	mux #(.n(1), .w(N+1)) mux1 ({{out4, out2}, {out3, out1}}, cin, {cout, sum});

endmodule

module rca #(
	parameter N = 32
)(
	input signed [N-1:0]a, b,
	input cin,
	output signed [N-1:0]sum,
	output cout
);

	wire [N:0] carry;
	assign carry[0] = cin;

	genvar i;
	generate
	for (i = 0; i < N; i = i + 1) begin : FA
		adder fa_inst (
		.a   (a[i]),
		.b   (b[i]),
		.cin (carry[i]),
		.sum (sum[i]),
		.cout(carry[i+1])
	);
	end
	endgenerate

	assign cout = carry[N];

endmodule

module adder(
	input a, b, cin,
	output sum, cout
);
	wire out1, out2, out3, out4;

	mux mux1({~cin, cin}, b, out1);
	mux mux2({b, ~b}, cin, out2);
	mux mux3({out2, out1}, a, sum);

	mux mux4({1'b1, cin}, b, out3);
	mux mux5({b, 1'b0}, cin, out4);
	mux mux6({out3, out4}, a, cout);
endmodule

module mux #(
	parameter n = 1,
	parameter w = 1
)(
	input  [(1 << n)*w - 1:0] in,
	input  [n - 1:0] sel,
	output reg [w-1:0] out
);

	always @(*)
	begin
		out = in[sel*w +: w];
	end

endmodule
