import structs::*;
import opcodes::*;

module branch_ctrl #(
        parameter word_width = 32, reset_pc = 32'b0
    )(
        output logic [word_width-1:0] branch_addr
        ,output logic branch, is_branch_op, branch_taken
        ,input instruction curr_inst
        ,input logic [word_width-1:0] alu_result
        ,input alu_signal signal
        ,input logic inst_valid, result_valid, signal_valid, halt
    );

    always_comb begin
        branch_addr = 'x;
        branch = '0;
        branch_taken = '0;
        is_branch_op = '0;

        if (inst_valid && signal_valid) begin
            if (curr_inst.opcode == JAL_OP) begin
                branch_addr = curr_inst.inst_addr + curr_inst.imm;
                branch = '1;
            end else if (curr_inst.opcode == JALR_OP) begin
                branch_addr = alu_result;
                branch = '1;
            end else if (curr_inst.opcode == BRANCH_OP) begin
                is_branch_op = '1;
                branch_taken = (curr_inst.funct3 == BEQ && signal.zero
                                || curr_inst.funct3 == BNE && ~signal.zero
                                || curr_inst.funct3 == BLT && signal.negative
                                || curr_inst.funct3 == BGE && ~signal.negative
                                || curr_inst.funct3 == BLTU && signal.overflow
                                || curr_inst.funct3 == BGEU && ~signal.overflow);

                if (branch_taken == curr_inst.is_pred_branch) begin
                    branch = '0;
                end else if (branch_taken & ~curr_inst.is_pred_branch) begin
                    branch_addr = curr_inst.inst_addr + curr_inst.imm;
                    branch = '1;
                end else begin
                    branch_addr = curr_inst.inst_addr + 32'd4;
                    branch = '1;
                end
            end
        end
        
        if (halt) begin
            branch = '0;
        end
    end

endmodule  // branch_ctrl
