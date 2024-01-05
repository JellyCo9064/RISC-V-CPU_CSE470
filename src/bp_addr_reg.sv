module bp_addr_reg #(
        parameter word_width = 32
    ) (
        output logic [word_width-1:0] saved_bp_addr_q
        ,input logic [word_width-1:0] saved_bp_addr_d
        ,input logic enable, clk, reset
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            saved_bp_addr_q <= 'x;
        end else if (enable) begin
            saved_bp_addr_q <= saved_bp_addr_d;
        end
    end

endmodule  // bp_addr_reg
