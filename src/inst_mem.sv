module inst_mem #(
    parameter word_width = 32, inst_addr_width = 12, num_col = 4, col_width = 8
    )(
    output logic [word_width-1:0] pc_inst_out, alt_inst_out
    ,input logic [word_width-1:0] inst_in, inst_ld_data, inst_ld_addr
    ,input logic [num_col - 1:0] which_bytes
    ,input logic [word_width-1:0] pc_inst_addr, alt_inst_addr
    ,input logic wren, rden, lden, clk, reset
    );

    logic [word_width-1:0] memory [(1 << (inst_addr_width-2))-1:0];

    // initial begin
    //     $readmemh("code.mem", memory, 0);
    // end

    logic [word_width-1:0] pc_inst_addr_aligned, alt_inst_addr_aligned, alt_inst_out_temp, inst_ld_addr_aligned;
    logic [num_col - 1:0] col_en;
    integer i, j;
    
    assign col_en = (which_bytes << alt_inst_addr[1:0]);
    
    assign pc_inst_addr_aligned = (pc_inst_addr >> 2);
    assign alt_inst_addr_aligned = (alt_inst_addr >> 2);
    assign inst_ld_addr_aligned = (inst_ld_addr >> 2);

    mem_shifter shifter (
        .shifted_data(alt_inst_out)
        ,.ram_read_data(alt_inst_out_temp)
        ,.rd_addr(alt_inst_addr)
        ,.which_bytes(which_bytes)
    );

    always_ff @(posedge clk) begin
    
        pc_inst_out <= memory[pc_inst_addr_aligned];
    
        if (lden) begin
            memory[inst_ld_addr_aligned] <= inst_ld_data;
        end else if (wren) begin
            j = 0;
            for (i = 0; i < num_col; i++) begin
                if (col_en[i]) begin
                    memory[alt_inst_addr_aligned][i * col_width +: col_width] <= inst_in[j * col_width +: col_width];
                    j++;
                end
            end
        end
        
        if (rden) begin
            alt_inst_out_temp <= memory[alt_inst_addr_aligned];
        end
        
        if (reset) begin
            alt_inst_out_temp <= '0;
        end
    end

endmodule  // inst_mem
