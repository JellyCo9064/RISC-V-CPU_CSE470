import structs::*;
import opcodes::*;

module exec_ctrl #(
        parameter word_width = 32, alu_op_width = 4
    )(
        output logic [word_width-1:0] alu_a, alu_b
        ,output logic [alu_op_width-1:0] alu_op
        ,input instruction curr_inst
        ,input logic inst_valid
        ,input logic [word_width-1:0] pc_addr
        ,input logic [word_width-1:0] reg_data_out_0, reg_data_out_1
    );

    always_comb begin
        if (curr_inst.opcode == BRANCH_OP) begin
            alu_op = 4'b0001;
        end else if (curr_inst.opcode == LOAD_OP
                     || curr_inst.opcode == STORE_OP
                     || curr_inst.opcode == LUI_OP) begin
            alu_op = 4'b0000;
        end else begin
            alu_op = {curr_inst.funct3
                     , ((curr_inst.opcode == IRR_OP
                            || curr_inst.opcode == IRI_OP 
                                && (curr_inst.funct3 == 3'b001
                                    || curr_inst.funct3 == 3'b101))
                            && curr_inst.funct7 != 0)
                     };
        end

        if (curr_inst.opcode == AUIPC_OP) begin
            alu_a = pc_addr;
        end else if (curr_inst.opcode == LUI_OP) begin
            alu_a = '0;
        end else begin
            alu_a = reg_data_out_0;
        end

        if (~(curr_inst.opcode == IRR_OP || curr_inst.opcode == BRANCH_OP)) begin
            alu_b = curr_inst.imm;
        end else begin
            alu_b = reg_data_out_1;
        end

        if (~inst_valid) begin
            alu_op = 'x;
        end
    end

endmodule  // exec_ctrl
