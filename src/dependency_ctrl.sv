import structs::*;

module dependency_ctrl #(
        parameter word_width = 32, reg_addr_width = 5
    )(
        output logic [word_width-1:0] rs1, rs2
        ,output logic exec_stall, save_mw_reg_rs1, save_mw_reg_rs2
        ,input logic [word_width-1:0] em_reg_result_data, de_reg_rs1_data, de_reg_rs2_data, reg_wr_data
        ,input logic [reg_addr_width-1:0] em_reg_result_tag, de_reg_rs1_tag, de_reg_rs2_tag, reg_wr_data_tag
        ,input logic inst_valid, em_reg_result_valid, de_reg_rs1_valid, de_reg_rs2_valid, reg_wr_data_valid
        ,input logic mem_load
    );

    logic mem_has_rs1, wb_has_rs1, mem_has_rs2, wb_has_rs2;
    assign mem_has_rs1 = em_reg_result_valid && de_reg_rs1_valid && em_reg_result_tag == de_reg_rs1_tag && em_reg_result_tag != '0;
    assign wb_has_rs1 = reg_wr_data_valid && de_reg_rs1_valid && reg_wr_data_tag == de_reg_rs1_tag && reg_wr_data_tag != '0;
    assign mem_has_rs2 = em_reg_result_valid && de_reg_rs2_valid && em_reg_result_tag == de_reg_rs2_tag && em_reg_result_tag != '0;
    assign wb_has_rs2 = reg_wr_data_valid && de_reg_rs2_valid && reg_wr_data_tag == de_reg_rs2_tag && reg_wr_data_tag != '0;

    always_comb begin
        rs1 = de_reg_rs1_data;
        rs2 = de_reg_rs2_data;
        exec_stall = '0;
        save_mw_reg_rs1 = '0;
        save_mw_reg_rs2 = '0;

        if (inst_valid) begin

            // Check E/M reg for rs1/rs2 data
            if (mem_has_rs1) begin
                if (mem_load) begin
                    // Pipe NOP into mem
                    exec_stall = '1;
                end else begin
                    // Route em_reg_result_data into alu op
                    rs1 = em_reg_result_data;
                end
            end
            
            if (mem_has_rs2) begin
                if (mem_load) begin
                    // Pipe NOP into mem
                    exec_stall = '1;
                end else begin
                    // Route em_reg_result_data into alu op
                    rs2 = em_reg_result_data;
                end
            end
            
            // Check M/W reg for rs1/rs2 data
            if (wb_has_rs1 & ~mem_has_rs1) begin
                if (exec_stall) begin
                    // Save mw_reg_rs2_data into D/E reg
                    save_mw_reg_rs1 = '1;
                end else begin
                    rs1 = reg_wr_data;
                end
            end

            if (wb_has_rs2 & ~mem_has_rs2) begin
                if (exec_stall) begin
                    save_mw_reg_rs2 = '1;
                end else begin
                    rs2 = reg_wr_data;
                end
            end

        end
    end

endmodule  // dependecy_ctrl
