module reg32 #(
    parameter word_width = 32
    )(
    output logic [word_width-1:0] data_out
    ,input logic [word_width-1:0] data_in
    ,input logic wren, clk, reset
    );

    logic [word_width-1:0] memory;

    always_ff @(posedge clk) begin
        if (reset) begin
            memory <= 32'b0;
        end else if (wren) begin
            memory <= data_in;
        end else begin
            memory <= memory;
        end
        data_out <= memory;
    end

endmodule  // reg32

