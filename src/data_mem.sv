module data_mem #(
    parameter word_width = 32, data_addr_width = 19, num_col = 4, col_width = 8
    )(
    output logic [word_width-1:0] data_out
    ,input logic [word_width-1:0] data_in, word_ld_data, word_ld_addr
    ,input logic [num_col-1:0] which_bytes
    ,input logic [word_width-1:0] mem_addr
    ,input logic wren, rden, lden, clk, reset
    );

    logic [word_width-1:0] memory [0:(1 << (data_addr_width-2))-1];

    logic [word_width-1:0] mem_addr_aligned, data_out_temp, word_ld_addr_aligned;
    logic [num_col-1:0] col_en;
    integer i, j;
    
    assign mem_addr_aligned = (mem_addr >> 2);
    assign col_en = (which_bytes << mem_addr[1:0]);
    assign word_ld_addr_aligned = (word_ld_addr >> 2);
    
    // initial begin
    //     $readmemh("data.mem", memory);
    // end

    mem_shifter shifter (
        .shifted_data(data_out)
        ,.ram_read_data(data_out_temp)
        ,.rd_addr(mem_addr)
        ,.which_bytes(which_bytes)
    );
    
    always_ff @(posedge clk) begin
    
        if (lden) begin
            memory[word_ld_addr_aligned] <= word_ld_data;
        end else if (wren) begin
            j = 0;
            for (i = 0; i < num_col; i++) begin
                if (col_en[i]) begin
                    memory[mem_addr_aligned][i * col_width +: col_width] <= data_in[j * col_width +: col_width];
                    j++;
                end
            end
        end
        
        if (rden) begin
            data_out_temp <= memory[mem_addr_aligned];
        end
        
        if (reset) begin
            data_out_temp <= '0;
        end
    end

endmodule  // data_mem

`timescale 1 ns / 1 ns
module data_mem_testbench();

    logic [31:0] data_out, monitor;
    logic [31:0] data_in;
    logic [3:0] which_bytes;
    logic [31:0] mem_addr;
    logic wren, rden, clk;
    
    data_mem dut (.*);
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;
    end
    
    initial begin
        @(posedge clk) data_in <= 32'hdeadbeef; which_bytes = 4'b1111; mem_addr = 32'h0007ffb8;
        @(posedge clk) wren <= 1'b1;
        @(posedge clk) wren <= 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); rden <= 1'b1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        
        $stop;
    end
endmodule
