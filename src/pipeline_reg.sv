module pipeline_reg #(
        parameter data_width = 32, tag_width = 5
    )(
        output logic valid_out
        ,output logic [data_width-1:0] data_out
        ,output logic [tag_width-1:0] tag_out
        ,input logic set_valid, branch, stall, halt
        ,input logic [data_width-1:0] data_in
        ,input logic [tag_width-1:0] tag_in
        ,input logic clk, enable, reset
    );

    always_ff @(posedge clk) begin
        if (reset | halt) begin
            valid_out <= '0;
            data_out <= 'x;
            tag_out <= 'x;
        end else if (enable) begin
            if (stall) begin
                valid_out <= valid_out;
                data_out <= data_out;
                tag_out <= tag_out;
            end else begin
                valid_out <= branch ? 1'b0 : set_valid;
                data_out <= data_in;
                tag_out <= tag_in;
            end
        end
    end

endmodule  // pipeline_reg
