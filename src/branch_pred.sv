import structs::*;
import opcodes::*;
import predictors::*;

module branch_pred #(
        parameter which_strategy
    )(
        output logic branch_predicted
        ,output logic [word_width-1:0] branch_addr
        ,input logic [word_width-1:0] inst_in, inst_addr
        ,input logic save_inst_addr, handling_pred, branch_taken, clk, reset
    );

    logic [word_width-1:0] saved_inst_addr;

    // Instantiate predictors
    logic obs_pred;
    saturating_counter #(
        .n(1)
    ) obs (
        .pred(obs_pred)
        ,.update(handling_pred)
        ,.taken(branch_taken)
        ,.clk(clk)
        ,.reset(reset)
    );

    logic tbs_pred;
    saturating_counter #(
        .n(2)
    ) tbs (
        .pred(tbs_pred)
        ,.update(handling_pred)
        ,.taken(branch_taken)
        ,.clk(clk)
        ,.reset(reset)
    );

    logic cp_pred;
    correlated_predictor #(
        .ghr_width(2)
        ,.counter_width(2)
    ) cp (
        .pred(cp_pred)
        ,.update(handling_pred)
        ,.taken(branch_taken)
        ,.clk(clk)
        ,.reset(reset)
    );

    logic test;
    // Assign output
    always_comb begin
        branch_predicted = inst_in[6:0] == BRANCH_OP;
        branch_addr = 'x;

        case (which_strategy)

            0: begin
                test = 0;
            end
            1: begin
                test = 1;
            end
            2: begin
                test = forward_only(inst_in);
            end
            3: begin
                test = backward_only(inst_in);
            end
            4: begin
                test = obs_pred;
            end
            5: begin
                test = tbs_pred;
            end
            6: begin
                test = cp_pred;
            end

        endcase

        branch_predicted &= test;

        if (branch_predicted) begin
            branch_addr = saved_inst_addr + get_imm(inst_in);
        end
    end

    always_ff @(posedge clk) begin
        if (save_inst_addr) begin
            saved_inst_addr <= inst_addr;
        end
    end

endmodule  // branch_pred
