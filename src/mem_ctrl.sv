import structs::*;
import opcodes::*;

// Instruction memory - 4 KB (2^12 bytes)
// Data memory        - 1 MB (2^20 bytes)

// Instruction Memory Region    - [0x00010000, 0x0001FFFF] (actually [0x00010000, 0x00010FFF])
// Data Memory Region           - [0x00020000, 0x0011FFFF]

module mem_ctrl #(
    parameter word_width = 32, inst_mem_start = 32'h00010000, data_mem_start = 32'h00020000
             ,stdout_addr = 32'h0002FFF8, reg_addr_width = 5, halt_addr = 32'h0002FFFC
             ,start_bp_count_addr = 32'h0002FFF4, end_bp_count_addr = 32'h0002FFF0
    )(
        output logic stdout_en, inst_mem_en, data_mem_en, halt_en, start_bp_count, end_bp_count
        ,output logic mem_wren, mem_rden
        ,output logic [3:0] which_bytes
        ,output logic [word_width-1:0] mem_data_in, mem_out_mux
        ,input logic [word_width-1:0] mem_addr, wb_data, rs2_data, inst_mem_out, data_mem_out
        ,input logic [reg_addr_width-1:0] wb_data_tag, rs2_data_tag
        ,input instruction curr_inst
        ,input logic inst_valid, mem_addr_valid, wb_data_valid, rs2_data_valid
    );

    logic wb_has_rs2;
    assign wb_has_rs2 = rs2_data_valid && wb_data_valid && wb_data_tag == rs2_data_tag && wb_data_tag != '0;

    always_comb begin
        stdout_en = (mem_addr == stdout_addr) & inst_valid;
        mem_wren = (curr_inst.opcode == STORE_OP) & inst_valid;
        mem_rden = (curr_inst.opcode == LOAD_OP) & inst_valid;
        halt_en = (mem_addr == halt_addr) & curr_inst.opcode == STORE_OP & inst_valid;
        start_bp_count = (mem_addr == start_bp_count_addr) & curr_inst.opcode == STORE_OP & inst_valid;
        end_bp_count = (mem_addr == end_bp_count_addr) & curr_inst.opcode == STORE_OP & inst_valid;

        inst_mem_en = '0;
        data_mem_en = '0;
        
        if (wb_has_rs2) begin
            mem_data_in = wb_data;
        end else begin
            mem_data_in = rs2_data;
        end

        if ((mem_wren | mem_rden) & mem_addr_valid) begin
            if (mem_addr >= data_mem_start) begin
                inst_mem_en = '0;
                data_mem_en = '1;
            end else if (mem_addr >= inst_mem_start) begin
                inst_mem_en = '1;
                data_mem_en = '0;
            end
        end

        mem_out_mux = 'x;
        if (mem_rden & mem_addr_valid) begin
            if (inst_mem_en) begin
                mem_out_mux = inst_mem_out;
            end else if (data_mem_en) begin
                mem_out_mux = data_mem_out;
            end
        end

        which_bytes = 4'b0000;
        if ((curr_inst.opcode == STORE_OP || curr_inst.opcode == LOAD_OP) & inst_valid) begin
            if (curr_inst.funct3 == LS_BYTE || curr_inst.funct3 == LS_UBYTE)
                which_bytes = 4'b0001;
            else if (curr_inst.funct3 == LS_HALF || curr_inst.funct3 == LS_UHALF)
                which_bytes = 4'b0011;
            else if (curr_inst.funct3 == LS_WORD)
                which_bytes = 4'b1111;
        end
    end

endmodule  // mem_map
