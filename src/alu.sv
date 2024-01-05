import structs::*;

`timescale 1 ps / 1 ps
module alu #(
    parameter word_width = 32, op_width = 4
    )(
    output logic [word_width-1:0] result
    ,output alu_signal signal
    ,output logic valid
    ,input logic [word_width-1:0] a, b
    ,input logic [op_width-1:0] op
    ,input logic clk, reset
    );

    logic [word_width:0] result_q;
    logic signed [word_width-1:0] as, bs;
    logic z,o,n,v;
    always_comb begin
        as = a;
        bs = b;

        v = 1'b1;
        case (op[op_width-1:1]) 
            0: begin
                if (~op[0]) result_q = a + b; // Add
                else       result_q = a - b; // Sub
            end
            1: result_q = {1'b0, a << b}; // Shift Left
            2: result_q = {{(word_width){1'b0}}, (as < bs)}; // Less than
            3: result_q = {{(word_width){1'b0}}, (a < b)}; // less than unsigned
            4: result_q = {1'b0, a ^ b}; // XOR
            5: begin
                if (~op[0]) result_q = {1'b0, a >> b};
                else       result_q = {as[word_width-1], as >>> b};
            end
            6: result_q = {1'b0, a | b}; // OR
            7: result_q = {1'b0, a & b}; // AND
            default: begin
                result_q = 'x;
                v = 1'b0;
            end
        endcase
        z = (result_q == 0);
        o = result_q[word_width]; 
        n = result_q[word_width-1];
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            result <= 'x;
            signal.zero <= '0;
            signal.overflow <= '0;
            signal.negative <= '0;
            valid <= '0;
        end else begin
            result <= result_q[word_width-1:0];
            signal.zero <= z;
            signal.overflow <= o;
            signal.negative <= n;
            valid <= v;
        end
    end

//    initial begin
//        if ($test$plusargs("trace") != 0) begin
//            $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
//            $dumpfile("logs/alu_testbench_wave.vcd");
//            $dumpvars();
//        end
//        $display("[%0t] Model running...\n", $time);
//    end

endmodule  // alu

