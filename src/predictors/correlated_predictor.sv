module correlated_predictor #(
        parameter ghr_width = 2, counter_width = 2
    )(
        output logic pred
        ,input logic update, taken, clk, reset
    );

    logic [ghr_width-1:0] global_history;
    logic [(1<<ghr_width)-1:0] pattern_history_mux;
    logic [(1<<ghr_width)-1:0] update_mux;

    genvar i;
    generate
        for (i = 0; i < 2**(ghr_width); i++) begin
            saturating_counter #(
                .n(counter_width)
            ) tbs (
                .pred(pattern_history_mux[i])
                ,.update(update_mux[i])
                ,.taken(taken)
                ,.clk(clk)
                ,.reset(reset)
            );
        end
    endgenerate

    assign pred = pattern_history_mux[global_history];
    assign update_mux = {{((1<<ghr_width)-1){1'b0}}, update} << global_history;

    always_ff @(posedge clk) begin
        if (reset) begin
            global_history <= '0;
        end else if (update) begin
            global_history <= {global_history[ghr_width-2:0], taken};
        end
    end

    initial begin
        if ($test$plusargs("trace") != 0) begin
            $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
            $dumpfile("logs/correlated_predictor_testbench_wave.vcd");
            $dumpvars();
        end
        $display("[%0t] Model running...\n", $time);  
    end

endmodule  // correlated_predictor