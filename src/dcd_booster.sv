`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2023 11:07:44 PM
// Design Name: 
// Module Name: dcd_booster
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dcd_booster #(
        parameter word_width = 32, reg_addr_width = 5
    )(
        output logic [word_width-1:0] rs1_pipe_data, rs2_pipe_data
        ,input logic [word_width-1:0] reg_data_out_0, reg_data_out_1, wb_data
        ,input logic [reg_addr_width-1:0] rs1_tag, rs2_tag, wb_tag
        ,input logic reg_wren, wb_valid, inst_valid
    );
    
    logic wb_has_rs1, wb_has_rs2;
    assign wb_has_rs1 = reg_wren && inst_valid && rs1_tag == wb_tag && rs1_tag != '0;
    assign wb_has_rs2 = reg_wren && inst_valid && rs2_tag == wb_tag && rs2_tag != '0;
    
    always_comb begin
    
        rs1_pipe_data = reg_data_out_0;
        rs2_pipe_data = reg_data_out_1;
    
        if (wb_has_rs1) begin
            rs1_pipe_data = wb_data;
        end
        
        if (wb_has_rs2) begin
            rs2_pipe_data = wb_data;
        end
    
    end
    
endmodule
