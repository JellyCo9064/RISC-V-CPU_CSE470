module reg_file #(
    parameter word_width = 32, reg_addr_width = 5
    )(
    output logic [word_width-1:0] data_out_0, data_out_1
    ,input logic [word_width-1:0] data_in
    ,input logic [reg_addr_width-1:0] wr_addr, rd_addr_0, rd_addr_1
    ,input logic wren, clk, reset
    );

    logic [word_width-1:0] data_out_mux [(1 << reg_addr_width)-1:0];
    logic [(1 << reg_addr_width)-1:0] wren_decode;

    reg32 x0 (.data_out(data_out_mux[0]), .data_in(32'b0), .wren(0 & wren_decode[0]), .clk(clk), .reset(reset));

    genvar i;
    generate
        for (i = 1; i < (1 << reg_addr_width); i++) begin
            reg32 x (.data_out(data_out_mux[i]), .data_in(data_in), .wren(wren & wren_decode[i]), .clk(clk), .reset(reset));
        end
    endgenerate

    always_comb begin
        wren_decode = (32'b1 << wr_addr);

        data_out_0 = data_out_mux[rd_addr_0];
        data_out_1 = data_out_mux[rd_addr_1];
    end

//    initial begin
//        if ($test$plusargs("trace") != 0) begin
//            $dumpfile("logs/reg_file_testbench_wave.vcd");
//            $dumpvars();
//        end
//    end 

endmodule  // reg_file

module reg_file_testbench();
    localparam word_width = 32, reg_addr_width = 5;
    
    logic [word_width-1:0] data_out_0, data_out_1;
    logic [word_width-1:0] data_in;
    logic [reg_addr_width-1:0] wr_addr, rd_addr_0, rd_addr_1;
    logic wren, clk, reset;
    
    reg_file dut (.*);
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;
    end
    
    initial begin
    
        @(posedge clk) reset <= 1'b1;
        @(posedge clk) reset <= 1'b0; 
                       wr_addr <= 5'b10101;
                       wren <= 1'b1;
                       rd_addr_0 <= 5'b10101;
                       rd_addr_1 <= 5'b0;
                       data_in <= 32'h69;
        
        
        @(posedge clk) reset <= 1'b0; 
                       wr_addr <= 5'b10101;
                       wren <= 1'b0;
                       rd_addr_0 <= 5'b10101;
                       rd_addr_1 <= 5'b0;
                       data_in <= 32'h6900;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk) reset <= 1'b0; 
                       wr_addr <= 5'b10101;
                       wren <= 1'b1;
                       rd_addr_0 <= 5'b10101;
                       rd_addr_1 <= 5'b0;
                       data_in <= 32'h65;
        @(posedge clk) reset <= 1'b0; 
                       wr_addr <= 5'b10101;
                       wren <= 1'b1;
                       rd_addr_0 <= 5'b10101;
                       rd_addr_1 <= 5'b0;
                       data_in <= 32'h6500;
        @(posedge clk) wren <= 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
    
        $stop;
    end

endmodule  // reg_file.sv
