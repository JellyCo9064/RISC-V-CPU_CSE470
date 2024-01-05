module pc_ctrl #(
        parameter word_width = 32, reset_pc = 32'b0, BRANCH_OP = 7'b0, JAL_OP = 7'b0
                  , BEQ = 3'b0, BNE = 3'b0, BLT = 3'b0
                  , BGE = 3'b0, BLTU = 3'b0, BGEU = 3'b0
    )(
        output logic [word_width-1:0] next_inst_addr
        ,input instruction curr_inst
        ,input logic [word_width-1:0] alu_result
        ,input alu_signal signal
        ,input logic reset
    );

    always_comb begin
        if (reset) begin
            next_inst_addr = reset_pc;
        end else if (opcode == BRANCH_OP
                            && (curr_inst.funct3 == BEQ && signal.zero
                                || curr_inst.funct3 == BNE && ~signal.zero
                                || curr_inst.funct3 == BLT && signal.negative
                                || curr_inst.funct3 == BGE && ~signal.negative
                                || curr_inst.funct3 == BLTU && signal.overflow
                                || curr_inst.funct3 == BGEU && ~signal.overflow
                                )
                        || curr_inst.opcode == JAL_OP
                    ) begin
            next_inst_addr = curr_inst.inst_addr + curr_inst.imm;
        end else if (curr_inst.opcode == JALR_OP) begin
            next_inst_addr = alu_result;
        end else begin
            next_inst_addr = curr_inst.inst_addr + 4;
        end
    end

endmodule  // pc_ctrl
