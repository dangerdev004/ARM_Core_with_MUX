`timescale 1ns/1ps

module alu #(
	parameter N = 32
)(
	input  [N-1:0] a, b,
	input  [3:0] opcode,
	input  carry_in,
	output reg [N-1:0] result,
	output reg cout
);

	wire [N-1:0] add_out, sub_out, adc_out;
	wire [N-1:0] and_out, or_out, xor_out, bic_out, rsb_out, sbc_out;
	wire add_cout, sub_cout, adc_cout, rsb_cout, sbc_cout;

 	conditional_adder add_block (a, b, 1'b0, add_out, add_cout);
	conditional_adder sub_block (a, ~b, 1'b1, sub_out, sub_cout);
	conditional_adder adc_block (a, b, carry_in, adc_out, adc_cout);
	conditional_adder rsb_block (b, ~a, 1'b1, rsb_out, rsb_cout);
	conditional_adder sbc_block (a, ~b, carry_in, sbc_out, sbc_cout);
	and_N #(N) and_block (a, b, and_out);
	or_N  #(N) or_block  (a, b, or_out);
	xor_N #(N) xor_block (a, b, xor_out);
	and_N #(N) bic_block (a, ~b, bic_out);

	always @(*)
	begin
		result = 0;
		cout = carry_in;
		case (opcode)
			4'b0000: begin result = add_out; cout = add_cout; end    // ADDS
			4'b0001: begin result = sub_out; cout = sub_cout; end    // SUBS
			4'b0010: begin result = adc_out; cout = adc_cout; end    // ADCS
			4'b0011: begin result = and_out; cout = 0; end           // AND
			4'b0100: begin result = or_out;  cout = 0; end           // ORR
			4'b0101: begin result = xor_out; cout = 0; end           // EOR
			4'b0110: begin result = a;  cout = 0; end                // MOV
			4'b0111: begin result = ~a; cout = 0; end                // MVN
			4'b1000: begin result = 0; cout = sub_cout; end          // CMP
			4'b1001: begin result = 0; cout = add_cout; end          // CMN
			4'b1010: begin result = bic_out; cout = 0; end           // BIC
			4'b1011: begin result = rsb_out; cout = rsb_cout; end    // RSB
			4'b1100: begin result = sbc_out; cout = sbc_cout; end    // SBC
			default: begin result = add_out; cout = add_cout; end
        	endcase
        end

endmodule

module conditional_adder #(
	parameter N = 32
)(
	input [N-1:0]a, b,
	input cin,
	output [N-1:0]sum,
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
	input [N-1:0]a, b,
	input cin,
	output [N-1:0]sum,
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

module and_N #(
	parameter N = 32
)(
	input [N-1:0] a, b,
	output [N-1:0] y
);

	genvar i;
	generate
		for (i = 0; i < N; i = i + 1) begin : GEN_AND
			mux m (
				.in({b[i], 1'b0}),
				.sel(a[i]),
				.out(y[i])
			);
		end
	endgenerate

endmodule

module or_N #(
	parameter N = 32
)(
	input [N-1:0] a, b,
	output [N-1:0] y
);

	genvar i;
	generate
		for (i = 0; i < N; i = i + 1) begin : GEN_OR
			mux m (
				.in({1'b1, b[i]}),
				.sel(a[i]),
				.out(y[i])
			);
		end
	endgenerate

endmodule

module xor_N #(
	parameter N = 32
)(
	input [N-1:0] a, b,
	output [N-1:0] y
);

	genvar i;
	generate
		for (i = 0; i < N; i = i + 1) begin : GEN_XOR
			mux m (
				.in({~b[i], b[i]}),
				.sel(a[i]),
				.out(y[i])
			);
		end
	endgenerate

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
