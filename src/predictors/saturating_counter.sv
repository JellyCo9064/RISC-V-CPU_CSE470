module saturating_counter #(
        parameter n
    ) (
        output logic pred
        ,input logic update, taken, clk, reset
    );

    logic [n-1:0] counter;

    assign pred = counter[n-1];

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= '0;
        end else if (update) begin
            if (taken & counter != {(n){1'b1}}) begin
                counter <= counter + 1'b1;
            end else if (~taken & counter != {(n){1'b0}}) begin
                counter <= counter - 1'b1;
            end
        end
    end

endmodule  // saturating_counter