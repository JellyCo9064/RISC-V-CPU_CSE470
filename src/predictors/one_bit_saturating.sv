module one_bit_saturating (
        output logic pred
        ,input logic update, taken, clk, reset
    );

    typedef enum logic { s_not_taken, s_taken } pred_state;

    pred_state curr_pred, next_pred;

    always_comb begin
        next_pred = curr_pred;

        if (update) begin
            if (taken & curr_pred == s_not_taken) begin
                next_pred = s_taken;
            end else if (~taken & curr_pred == s_taken) begin
                next_pred = s_not_taken;
            end
        end

        case (curr_pred)
            s_not_taken:
                pred = '0;
            s_taken:
                pred = '1;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            curr_pred <= s_not_taken;
        end else begin
            curr_pred <= next_pred;
        end
    end

endmodule  // one_bit_saturating