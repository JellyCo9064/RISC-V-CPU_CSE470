import structs::*;

package predictors;

    function static logic [word_width-1:0] get_imm(logic [word_width-1:0] inst);
        return {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    endfunction

    function static logic forward_only(logic [word_width-1:0] inst);
        logic signed [word_width-1:0] imm = get_imm(inst);
        return imm > 0;
    endfunction

    function static logic backward_only(logic [word_width-1:0] inst);
        return ~forward_only(inst);
    endfunction

endpackage  // predictors.sv