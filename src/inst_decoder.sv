import structs::*;
import opcodes::*;

module inst_decoder #(
    parameter word_width = 32
    )(
    output instruction inst_decoded
    ,input logic [1+word_width-1:0] inst
    ,input logic [word_width-1:0] inst_addr
    ,input logic inst_valid
    );

    always_comb begin
    
        inst_decoded.is_pred_branch = inst[word_width];
        inst_decoded.inst_addr = inst_addr; 
        inst_decoded.opcode = inst[6:0];

        if (inst_decoded.opcode == STORE_OP || inst_decoded.opcode == BRANCH_OP) begin
            inst_decoded.rd = '0;
        end else begin
            inst_decoded.rd = inst[11:7];
        end

        if (inst_decoded.opcode == LUI_OP
            || inst_decoded.opcode == AUIPC_OP
            || inst_decoded.opcode == JAL_OP) begin
           inst_decoded.funct3 = '0; 
           inst_decoded.rs1 = '0;
        end else begin
            inst_decoded.funct3 = inst[14:12];
            inst_decoded.rs1 = inst[19:15];
        end

        if (inst_decoded.opcode == BRANCH_OP
            || inst_decoded.opcode == STORE_OP
            || inst_decoded.opcode == IRR_OP) begin
            inst_decoded.rs2 = inst[24:20];
        end else begin
            inst_decoded.rs2 = '0;
        end

        if ((inst_decoded.opcode == IRI_OP
            && (inst_decoded.funct3 == 3'b001
                || inst_decoded.funct3 == 3'b101))
            || inst_decoded.opcode == IRR_OP) begin
            inst_decoded.funct7 = inst[31:25];
        end else begin
            inst_decoded.funct7 = '0;
        end
        
        if (inst_decoded.opcode == IRI_OP
            && (inst_decoded.funct3 == 3'b001
                || inst_decoded.funct3 == 3'b101)) begin
            inst_decoded.imm = {27'b0, inst[24:20]};
        end else if (inst_decoded.opcode == IRR_OP) begin  // R-type
            inst_decoded.imm = '0;
        end else if (inst_decoded.opcode == IRI_OP
                     || inst_decoded.opcode == LOAD_OP 
                     || inst_decoded.opcode == JALR_OP) begin  // I-type
            inst_decoded.imm = {{21{inst[31]}}, inst[30:20]};
        end else if (inst_decoded.opcode == STORE_OP) begin  // S-type
            inst_decoded.imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
        end else if (inst_decoded.opcode == BRANCH_OP) begin  // B-type
            inst_decoded.imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        end else if (inst_decoded.opcode == JAL_OP) begin  // J-type
            inst_decoded.imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
        end else if (inst_decoded.opcode == LUI_OP || inst_decoded.opcode == AUIPC_OP) begin  // U-type
            inst_decoded.imm = {inst[31:12], 12'b0};
        end else begin
            inst_decoded.imm = '0;
        end

        if (~inst_valid) begin
            inst_decoded = 'x;
        end
    end

//    initial begin
//        $dumpfile("logs/vlt_dump.vcd");
//        $dumpvars();
//    end
endmodule  // inst_decoder

