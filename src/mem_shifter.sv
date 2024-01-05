module mem_shifter #(
        parameter word_width = 32
    )(
    output logic [word_width-1:0] shifted_data
    ,input logic [word_width-1:0] ram_read_data, rd_addr
    ,input logic [3:0] which_bytes
    );
    
    logic [word_width-1:0] mask;
    logic [3:0] col_en;
    
    always_comb begin
        col_en = (which_bytes << rd_addr[1:0]);
        mask = {{8{col_en[3]}}, {8{col_en[2]}}, {8{col_en[1]}}, {8{col_en[0]}}};
        
        shifted_data = (ram_read_data & mask) >> (rd_addr[1:0] * 8);
    end
    
endmodule  // mem_shifter
