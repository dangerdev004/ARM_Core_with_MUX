module tb;

    parameter N = 32;

    logic [N-1:0] a, b, result;
    logic [3:0] opcode;
    logic carry_in;
    logic cout;
    logic [32:0] expected;

    alu dut (a, b, opcode, carry_in, result, cout);

    class txn;
        rand bit [31:0] a, b;
        randc bit [3:0] opcode;
        rand bit carry_in;

        constraint valid_op {
            opcode <= 4'b1100;
        }
    endclass

    txn t;

    function automatic [32:0] alu_ref(
    input [31:0] a, b,
    input [3:0] opcode,
    input carry_in
);

    logic [32:0] tmp;

    case (opcode)

        // ADD
        4'b0000: tmp = a + b;

        // SUB (a - b)
        4'b0001: begin 
            tmp[31:0] = a - b;
            tmp[32]   = (a >= b);
        end
        // ADC
        4'b0010: tmp = a + b + carry_in;

        // AND
        4'b0011: tmp = {1'b0, (a & b)};

        // ORR
        4'b0100: tmp = {1'b0, (a | b)};

        // EOR
        4'b0101: tmp = {1'b0, (a ^ b)};

        // MOV
        4'b0110: tmp = {1'b0, a};

        // MVN
        4'b0111: tmp = {1'b0, ~a};

        // CMP (a - b, only cout matters)
        4'b1000: begin 
            tmp[31:0] = a - b;
            tmp[32]   = (a >= b);
        end
        // CMN (a + b)
        4'b1001: tmp = a + b;

        // BIC (a & ~b)
        4'b1010: tmp = {1'b0, (a & ~b)};

        // RSB (b - a)
        4'b1011: begin 
            tmp[31:0] = b - a;
            tmp[32]   = (b >= a);
        end
        // SBC (IMPORTANT)
        4'b1100: begin 
            tmp[31:0] = a - b - (1 - carry_in);
            tmp[32]   = (a >= (b + (1 - carry_in)));
        end
        default: tmp = a + b;

    endcase

    return tmp;

endfunction

    initial begin
        t = new();
       
        repeat (3000) begin

            assert(t.randomize());

            a = t.a;
            b = t.b;
            opcode = t.opcode;
            carry_in = t.carry_in;

            #1;

            expected = alu_ref(a, b, opcode, carry_in);
            if (opcode == 4'b1000 || opcode == 4'b1001) begin
                if (cout !== expected[32]) begin
                    $error("Flag mismatch: opcode=%0d a=%h b=%h", opcode, a, b);
                end
            end
            else begin
                if ({cout, result} !== expected) begin
                    $error("Mismatch: opcode=%0d a=%h b=%h", opcode, a, b);
                end
            end

        end
        $display("TEST COMPLETED");
        $finish;
    end

endmodule
