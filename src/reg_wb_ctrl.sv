import structs::*;
import opcodes::*;

module reg_wb_ctrl #(
        parameter word_width = 32, reg_addr_width = 5
    )(
        output logic [word_width-1:0] reg_data_in
        ,output logic reg_wren
        ,input instruction curr_inst
        ,input logic [word_width-1:0] mem_read_data, alu_result
        ,input logic inst_valid, alu_result_valid
    );

    always_comb begin
        reg_wren = (curr_inst.opcode != BRANCH_OP && curr_inst.opcode != STORE_OP) & inst_valid;

        reg_data_in = alu_result;
        
        if (curr_inst.opcode == LUI_OP) begin
            reg_data_in = curr_inst.imm;
        end else if (curr_inst.opcode == JAL_OP || curr_inst.opcode == JALR_OP) begin
            reg_data_in = curr_inst.inst_addr + 4;
        end else if (curr_inst.opcode == LOAD_OP) begin
            if (curr_inst.funct3 == LS_BYTE) begin
                reg_data_in = {{(word_width - 8){mem_read_data[7]}}, mem_read_data[7:0]};
            end else if (curr_inst.funct3 == LS_HALF) begin
                reg_data_in = {{(word_width - 16){mem_read_data[15]}}, mem_read_data[15:0]};
            end else if (curr_inst.funct3 == LS_WORD) begin
                reg_data_in = mem_read_data;
            end else if (curr_inst.funct3 == LS_UBYTE) begin
                reg_data_in = {{(word_width - 8){1'b0}}, mem_read_data[7:0]};
            end else if (curr_inst.funct3 == LS_UHALF) begin
                reg_data_in = {{(word_width - 16){1'b0}}, mem_read_data[15:0]};
            end
        end

        if (~inst_valid | ~alu_result_valid) begin
            reg_data_in = 'x;
        end
    end

endmodule  // reg_wb_ctrl
