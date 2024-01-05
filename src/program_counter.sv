module program_counter #(
    parameter word_width = 32, reset_addr = 32'h00000000
    )(
    output logic [word_width-1:0] inst_addr_q
    ,input logic [word_width-1:0] branch_addr, pred_branch_addr
    ,input logic wren, branch, pred_branch, stall, halt, clk, reset
    );

    always_ff @(posedge clk) begin
        if (reset | halt) begin
            inst_addr_q <= reset_addr;
        end else if (pred_branch) begin
            inst_addr_q <= pred_branch_addr;
        end else if (wren) begin
            if (stall) begin
                inst_addr_q <= inst_addr_q;
            end else if (branch) begin
                inst_addr_q <= branch_addr;
            end else begin
                inst_addr_q <= inst_addr_q + 4;
            end
        end else begin
            inst_addr_q <= inst_addr_q;
        end
    end

endmodule  // program_counter
