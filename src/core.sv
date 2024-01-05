import structs::*;
import opcodes::*;

`timescale 1 ps / 1 ps
module core #(
    parameter reset_pc = 32'h00010000, inst_addr_width = 12, data_addr_width = 14
              ,word_width = 32, little_endian = 1, big_endian = 0
              ,alu_op_width = 4, inst_mem_start = reset_pc, data_mem_start = 32'h00020000
              ,uart_clk_freq = 10000000, baud = 9600, halt_word = 32'h69deadff, stdout_addr = 32'h0002FFF8
              ,blinker_clk_freq = 10000000, which_strategy = 6
              ,start_bp_count_addr = 32'h0002FFF4, end_bp_count_addr = 32'h0002FFF0
    )(
    input logic RxD, clk, im_lden, dm_lden, start, reset
    ,input logic [word_width-1:0] inst_ld_data, inst_ld_addr, word_ld_data, word_ld_addr
    ,output logic TxD, handling_branch_op_out, is_branching, bp_count_en
    ,output logic halted, led0, led1, led2, led3, led0_b, led1_b, led2_b, led3_b
    );

    typedef enum logic [1:0] { s_do = 2'b0, s_save, s_halt, s_load } pipeline_state;
    logic halt;
    pipeline_state ps, ns;
    
    // logic clk;
    // assign clk = CLK100MHZ;

    logic pipeline_save, pipeline_do;
    assign pipeline_save = (ps == s_save);
    assign pipeline_do = (ps == s_do);

    logic branch, exec_stall;
    logic is_pred_branch;
    logic handling_branch_op;

    assign handling_branch_op_out = handling_branch_op & pipeline_save;

    assign is_branching = branch & pipeline_save;

    logic [word_width-1:0] branch_addr, pred_branch_addr, inst_addr;
    program_counter #(
        .word_width(word_width), .reset_addr(reset_pc)
    ) pc (
         .inst_addr_q(inst_addr)
        ,.branch_addr(branch_addr)
        ,.pred_branch_addr(pred_branch_addr)
        ,.wren(pipeline_do)
        ,.branch(branch)
        ,.pred_branch(is_pred_branch)
        ,.stall(exec_stall)
        ,.halt(halted)
        ,.clk(clk)
        ,.reset(reset)
    );
    
    logic [word_width-1:0] saved_inst_addr;
    pipeline_reg #(
        .data_width(word_width)
    ) save_inst_addr_reg (
        .valid_out()
        ,.data_out(saved_inst_addr)
        ,.tag_out()
        ,.set_valid(1'b1)
        ,.branch(1'b0)
        ,.stall(exec_stall)
        ,.halt(halted)
        ,.data_in(inst_addr)
        ,.tag_in()
        ,.clk(clk)
        ,.reset(reset)
        ,.enable(pipeline_do)
    );
    
    logic [word_width-1:0] curr_inst, inst_mem_out, reg_data_out_0, reg_data_out_1, mem_data_in;
    logic [word_width-1:0] em_reg_result_data;
    logic [(word_width / 8) - 1:0] which_bytes;
    logic mem_wren, mem_rden;
    logic inst_mem_en, data_mem_en;
    inst_mem #(
        .word_width(word_width), .inst_addr_width(inst_addr_width)
        ,.num_col(4) ,.col_width(8)
    ) im (
        .pc_inst_out(curr_inst)
        ,.alt_inst_out(inst_mem_out)
        ,.inst_in(mem_data_in)
        ,.inst_ld_data(inst_ld_data)
        ,.inst_ld_addr(inst_ld_addr)
        ,.which_bytes(which_bytes)
        ,.pc_inst_addr(
            (is_pred_branch ? pred_branch_addr : inst_addr) - inst_mem_start
        )
        ,.alt_inst_addr(em_reg_result_data - inst_mem_start)
        ,.wren(mem_wren & inst_mem_en)
        ,.rden(mem_rden & inst_mem_en)
        ,.lden(im_lden)
        ,.clk(clk)
        ,.reset(reset)
    );

    logic ipb, branch_taken;
    assign is_pred_branch = ipb & pipeline_save & ~branch;

    branch_pred #(
        .which_strategy(which_strategy)
    ) bp (
        .branch_predicted(ipb)
        ,.branch_addr(pred_branch_addr)
        ,.inst_in(curr_inst)
        ,.inst_addr(inst_addr)
        ,.save_inst_addr(pipeline_do)
        ,.handling_pred(handling_branch_op & pipeline_save)
        ,.branch_taken(branch_taken)
        ,.clk(clk)
        ,.reset(reset)
    );

    logic decode_inst_valid;
    logic [word_width:0] fd_reg_inst_data;
    pipeline_reg #(
        .data_width(1 + word_width)
    ) fd_reg_inst (
        .valid_out(decode_inst_valid)
        ,.data_out(fd_reg_inst_data)
        ,.tag_out()
        ,.set_valid(1'b1)
        ,.branch(branch)
        ,.stall(exec_stall)
        ,.halt(halted)
        ,.data_in({ is_pred_branch, curr_inst })
        ,.tag_in()
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );
    
    logic fd_reg_inst_addr_valid;
    logic [word_width-1:0] fd_reg_inst_addr_data;
    pipeline_reg #(
        .data_width(word_width)
    ) fd_reg_inst_addr (
        .valid_out(fd_reg_inst_addr_valid)
        ,.data_out(fd_reg_inst_addr_data)
        ,.tag_out()
        ,.set_valid(1'b1)
        ,.branch(branch)
        ,.stall(exec_stall)
        ,.halt(halted)
        ,.data_in(saved_inst_addr)
        ,.tag_in()
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    instruction decode_inst;
    inst_decoder #(
        .word_width(word_width)
    ) id (
        .inst_decoded(decode_inst)
        ,.inst(fd_reg_inst_data)
        ,.inst_addr(fd_reg_inst_addr_data)
        ,.inst_valid(decode_inst_valid)
    );

    logic [word_width-1:0] reg_data_in;
	logic reg_wren;
    reg_file #(
        .word_width(word_width), .reg_addr_width(reg_addr_width)
    ) rf (
        .data_out_0(reg_data_out_0)
        ,.data_out_1(reg_data_out_1)
        ,.data_in(reg_data_in)
        ,.wr_addr(wb_inst.rd)
        ,.rd_addr_0(decode_inst.rs1)
        ,.rd_addr_1(decode_inst.rs2)
        ,.wren(reg_wren)
        ,.clk(clk)
        ,.reset(reset)
    );
    
    logic [word_width-1:0] rs1_pipe_data, rs2_pipe_data;
    logic wb_inst_valid;
    dcd_booster #(
        .word_width(word_width), .reg_addr_width(reg_addr_width)
    ) db (
        .rs1_pipe_data(rs1_pipe_data)
        ,.rs2_pipe_data(rs2_pipe_data)
        ,.reg_data_out_0(reg_data_out_0)
        ,.reg_data_out_1(reg_data_out_1)
        ,.wb_data(reg_data_in)
        ,.rs1_tag(decode_inst.rs1)
        ,.rs2_tag(decode_inst.rs2)
        ,.wb_tag(wb_inst.rd)
        ,.reg_wren(reg_wren)
        ,.wb_valid(reg_wren)
        ,.inst_valid(decode_inst_valid)
    );

    logic exec_inst_valid;
    instruction exec_inst;
    pipeline_reg #(
        .data_width(instruction_width)
    ) de_reg_inst (
        .valid_out(exec_inst_valid)
        ,.data_out(exec_inst)
        ,.tag_out()
        ,.set_valid(decode_inst_valid)
        ,.branch(branch)
        ,.stall(exec_stall)
        ,.halt(halted)
        ,.data_in(decode_inst)
        ,.tag_in()
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    logic save_mw_reg_rs1, save_mw_reg_rs2;

    logic de_reg_rs1_valid;
    logic [word_width-1:0] de_reg_rs1_data;
    logic [reg_addr_width-1:0] de_reg_rs1_tag;
    pipeline_reg #(
        .data_width(word_width), .tag_width(reg_addr_width)
    ) de_reg_rs1 (
        .valid_out(de_reg_rs1_valid)
        ,.data_out(de_reg_rs1_data)
        ,.tag_out(de_reg_rs1_tag)
        ,.set_valid(decode_inst_valid)
        ,.branch(branch)
        ,.stall(exec_stall & ~save_mw_reg_rs1)
        ,.halt(halted)
        ,.data_in(
            save_mw_reg_rs1 ? reg_data_in :
                              rs1_pipe_data
        )
        ,.tag_in(
            save_mw_reg_rs1 ? wb_inst.rd :
                              decode_inst.rs1
        )
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    logic de_reg_rs2_valid;
    logic [word_width-1:0] de_reg_rs2_data;
    logic [reg_addr_width-1:0] de_reg_rs2_tag;
    pipeline_reg #(
        .data_width(word_width), .tag_width(reg_addr_width)
    ) de_reg_rs2 (
        .valid_out(de_reg_rs2_valid)
        ,.data_out(de_reg_rs2_data)
        ,.tag_out(de_reg_rs2_tag)
        ,.set_valid(decode_inst_valid)
        ,.branch(branch)
        ,.stall(exec_stall & ~save_mw_reg_rs2)
        ,.halt(halted)
        ,.data_in(
            save_mw_reg_rs2 ? reg_data_in :
                              rs2_pipe_data
        )
        ,.tag_in(
            save_mw_reg_rs2 ? wb_inst.rd :
                              decode_inst.rs2
        )
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    logic em_reg_result_valid;
    logic [reg_addr_width-1:0] em_reg_result_tag;
    logic [word_width-1:0] rs1_data, rs2_data;
    dependency_ctrl #(
        .word_width(word_width), .reg_addr_width(reg_addr_width)
    ) dc (
        .rs1(rs1_data)
        ,.rs2(rs2_data)
        ,.exec_stall(exec_stall)
        ,.save_mw_reg_rs1(save_mw_reg_rs1)
        ,.save_mw_reg_rs2(save_mw_reg_rs2)
        ,.de_reg_rs1_data(de_reg_rs1_data)
        ,.de_reg_rs2_data(de_reg_rs2_data)
        ,.em_reg_result_data(em_reg_result_data)
        ,.reg_wr_data(reg_data_in)
        ,.de_reg_rs1_tag(de_reg_rs1_tag)
        ,.de_reg_rs2_tag(de_reg_rs2_tag)
        ,.em_reg_result_tag(em_reg_result_tag)
        ,.reg_wr_data_tag(wb_inst.rd)
        ,.inst_valid(exec_inst_valid)
        ,.de_reg_rs1_valid(de_reg_rs1_valid)
        ,.de_reg_rs2_valid(de_reg_rs2_valid)
        ,.em_reg_result_valid(em_reg_result_valid)
        ,.reg_wr_data_valid(reg_wren)
        ,.mem_load(mem_rden)
    );

    logic [word_width-1:0] alu_a, alu_b;
    logic [alu_op_width-1:0] alu_op;
    exec_ctrl #(
        .word_width(word_width), .alu_op_width(alu_op_width)
    ) ec (
        .alu_a(alu_a)
        ,.alu_b(alu_b)
        ,.alu_op(alu_op)
        ,.curr_inst(exec_inst)
        ,.inst_valid(exec_inst_valid)
        ,.pc_addr(exec_inst.inst_addr)
        ,.reg_data_out_0(rs1_data)
        ,.reg_data_out_1(rs2_data)
    );

    logic [word_width-1:0] alu_result;
    alu_signal signal;
    logic zero, overflow, negative, alu_valid;
    alu #(
        .word_width(word_width), .op_width(alu_op_width)
    ) exec (
        .result(alu_result)
        ,.signal(signal)
        ,.valid(alu_valid)
        ,.a(alu_a)
        ,.b(alu_b)
        ,.op(alu_op)
        ,.clk(clk)
        ,.reset(reset)
    );

    logic mem_inst_valid;
    instruction mem_inst;
    pipeline_reg #(
        .data_width(instruction_width)
    ) em_reg_inst (
        .valid_out(mem_inst_valid)
        ,.data_out(mem_inst)
        ,.tag_out()
        ,.set_valid(exec_inst_valid & ~exec_stall)
        ,.branch(branch)
        ,.stall('0)
        ,.halt(halted)
        ,.data_in(
            exec_stall ? {33'bx, NOP, 32'bx} :
                    exec_inst
        )
        ,.tag_in()
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    pipeline_reg #(
        .data_width(word_width), .tag_width(reg_addr_width)
    ) em_reg_result (
        .valid_out(em_reg_result_valid)
        ,.data_out(em_reg_result_data)
        ,.tag_out(em_reg_result_tag)
        ,.set_valid(alu_valid & ~exec_stall)
        ,.branch(branch)
        ,.stall('0)
        ,.halt(halted)
        ,.data_in(alu_result)
        ,.tag_in(exec_inst.rd)
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    logic em_reg_rs2_valid;
    logic [word_width-1:0] em_reg_rs2_data;
    logic [reg_addr_width-1:0] em_reg_rs2_tag;
    pipeline_reg #(
        .data_width(word_width), .tag_width(reg_addr_width)
    ) em_reg_rs2 (
        .valid_out(em_reg_rs2_valid)
        ,.data_out(em_reg_rs2_data)
        ,.tag_out(em_reg_rs2_tag)
        ,.set_valid(de_reg_rs2_valid)
        ,.branch(branch)
        ,.stall('0)
        ,.halt(halted)
        ,.data_in(rs2_data)
        ,.tag_in(exec_inst.rs2)
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    logic em_reg_signal_valid;
    alu_signal em_reg_signal_data;
    pipeline_reg #(
        .data_width(3)
    ) em_reg_signal (
        .valid_out(em_reg_signal_valid)
        ,.data_out(em_reg_signal_data)
        ,.tag_out()
        ,.set_valid(alu_valid)
        ,.branch(branch)
        ,.stall('0)
        ,.halt(halted)
        ,.data_in(signal)
        ,.tag_in()
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    branch_ctrl #(
        .word_width(word_width)
    ) bc (
        .branch_addr(branch_addr)
        ,.branch(branch)
        ,.is_branch_op(handling_branch_op)
        ,.branch_taken(branch_taken)
        ,.curr_inst(mem_inst)
        ,.alu_result(em_reg_result_data)
        ,.signal(em_reg_signal_data)
        ,.inst_valid(mem_inst_valid)
        ,.result_valid(em_reg_result_valid)
        ,.signal_valid(em_reg_signal_valid)
        ,.halt(halted)
    );
   
    logic stdout_en, halt_en;
    logic [word_width-1:0] mem_out_mux, data_mem_out;
    mem_ctrl #(
        .word_width(word_width), .inst_mem_start(inst_mem_start)
        ,.data_mem_start(data_mem_start), .stdout_addr(stdout_addr)
        ,.bp_count_addr(bp_count_addr)
    ) mc (
        .stdout_en(stdout_en)
        ,.inst_mem_en(inst_mem_en)
        ,.data_mem_en(data_mem_en)
        ,.halt_en(halt_en)
        ,.start_bp_count(start_bp_count)
        ,.end_bp_count(end_bp_count)
        ,.mem_wren(mem_wren)
        ,.mem_rden(mem_rden)
        ,.which_bytes(which_bytes)
        ,.mem_data_in(mem_data_in)
        ,.mem_out_mux(mem_out_mux)
        ,.mem_addr(em_reg_result_data)
        ,.wb_data(reg_data_in)
        ,.rs2_data(em_reg_rs2_data)
        ,.inst_mem_out(inst_mem_out)
        ,.data_mem_out(data_mem_out)
        ,.wb_data_tag(wb_inst.rd)
        ,.rs2_data_tag(em_reg_rs2_tag)
        ,.curr_inst(mem_inst)
        ,.inst_valid(mem_inst_valid)
        ,.mem_addr_valid(em_reg_result_valid)
        ,.wb_data_valid(reg_wren)
        ,.rs2_data_valid(em_reg_rs2_valid)
    );

    data_mem #(
        .word_width(word_width), .data_addr_width(data_addr_width)
        ,.num_col(4), .col_width(8)
    ) dm (
        .data_out(data_mem_out)
        ,.data_in(mem_data_in)
        ,.word_ld_data(word_ld_data)
        ,.word_ld_addr(word_ld_addr)
        ,.which_bytes(which_bytes)
        ,.mem_addr(em_reg_result_data - data_mem_start)
        ,.wren(mem_wren & data_mem_en)
        ,.rden(mem_rden & data_mem_en)
        ,.lden(dm_lden)
        ,.clk(clk)
        ,.reset(reset)
    );

    logic [7:0] size;
    logic u_zero, uart_txd_out;
    uart #(
        .uart_clk_freq(uart_clk_freq), .baud(baud)
    ) u (
         .uart_txd(uart_txd_out)
        ,.uart_rxd(RxD)
        ,.uart_txd_data(mem_data_in[7:0])
        ,.uart_txd_enable(stdout_en & mem_wren & pipeline_save)
        ,.clk(clk)
        ,.reset(reset)
        ,.size(size)
        ,.zero(u_zero)
    );
    
    blinker #(
        .char_duration_sec(1), .clk_freq(2500000)
    ) led_blinker (
        .curr_blink({led3, led2, led1, led0, led3_b, led2_b, led1_b, led0_b})
        ,.data_in(mem_data_in[7:0])
        ,.enable(stdout_en & mem_wren & pipeline_save)
        ,.clk(clk)
        ,.reset(reset)
    );

    instruction wb_inst;
    pipeline_reg #(
        .data_width(instruction_width)
    ) mw_reg_inst (
        .valid_out(wb_inst_valid)
        ,.data_out(wb_inst)
        ,.tag_out()
        ,.set_valid(mem_inst_valid)
        ,.branch('0)
        ,.stall('0)
        ,.halt(halted)
        ,.data_in(mem_inst)
        ,.tag_in()
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    logic mw_reg_read_valid;
    logic [word_width-1:0] mw_reg_read_data;
    logic [reg_addr_width-1:0] mw_reg_read_tag;
    pipeline_reg #(
        .data_width(word_width), .tag_width(reg_addr_width)
    ) mw_reg_read (
        .valid_out(mw_reg_read_valid)
        ,.data_out(mw_reg_read_data)
        ,.tag_out(mw_reg_read_tag)
        ,.set_valid(mem_rden)
        ,.branch('0)
        ,.stall('0)
        ,.halt(halted)
        ,.data_in(mem_out_mux)
        ,.tag_in(mem_inst.rd)
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    logic mw_reg_alu_valid;
    logic [word_width-1:0] mw_reg_alu_data;
    logic [reg_addr_width-1:0] mw_reg_alu_tag;
    pipeline_reg #(
        .data_width(word_width), .tag_width(reg_addr_width)
    ) mw_reg_alu (
        .valid_out(mw_reg_alu_valid)
        ,.data_out(mw_reg_alu_data)
        ,.tag_out(mw_reg_alu_tag)
        ,.set_valid(em_reg_result_valid)
        ,.branch('0)
        ,.stall('0)
        ,.halt(halted)
        ,.data_in(em_reg_result_data)
        ,.tag_in(mem_inst.rd)
        ,.clk(clk)
        ,.enable(pipeline_save)
        ,.reset(reset)
    );

    reg_wb_ctrl #(
        .word_width(word_width)
    ) rwbc (
        .reg_data_in(reg_data_in)
        ,.reg_wren(reg_wren)
        ,.curr_inst(wb_inst)
        ,.mem_read_data(mw_reg_read_data)
        ,.alu_result(mw_reg_alu_data)
        ,.inst_valid(wb_inst_valid)
        ,.alu_result_valid(mw_reg_alu_valid)
    );

    always_comb begin

        case (ps)
            s_do:  ns = s_save;
            s_save: ns = s_do;
            s_halt: ns = s_halt;
            s_load: begin
                if (start) begin
                    ns = s_do;
                end else begin
                    ns = s_load;
                end
            end
            default: ns = s_halt;
        endcase

        if (wb_inst.opcode == HALT_OP && wb_inst_valid || halt_en) ns = s_halt;
        
        halt = (ps == s_halt);
    end

    always_ff @(posedge clk) begin
//        if (reset) begin
//            {led3, led2, led1, led0, led3_b, led2_b, led1_b, led0_b} <= 8'b0;
//        end else if (stdout_en & mem_wren & pipeline_do) begin
//            $display(mem_data_in[7:0]);
//            {led3, led2, led1, led0, led3_b, led2_b, led1_b, led0_b} <= mem_data_in[7:0];
//        end
    
        if (reset) begin
            ps <= s_load;
//            led3 <= 1'b0;
//            {led3, led2, led1, led0, led3_g, led2_g, led1_g, led0_g} <= 8'b0;
            halted <= '1;
            
        end else begin
            ps <= ns;

//            if (size[6:0] > {led2, led1, led0, led3_g, led2_g, led1_g, led0_g})
//                {led2, led1, led0, led3_g, led2_g, led1_g, led0_g} <= size[6:0];
                
//            if (u_zero) begin
//                led3 <= 1'b1;
//            end else begin
//                led3 <= led3;
//            end
            if (start) begin
                halted <= '0;
            end else if (halt) begin
                halted <= '1;
            end
        end
        
        TxD <= uart_txd_out;
    end

//    initial begin
//        $dumpfile("logs/core_testbench_wave.vcd");
//        $dumpvars();
//    end
    initial begin
        if ($test$plusargs("trace") != 0) begin
            $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
            $dumpfile("logs/core_testbench_wave.vcd");
            $dumpvars();
        end
        $display("[%0t] Model running...\n", $time);  
    end

endmodule  // core

`timescale 1 ps / 1 ps
module core_testbench();

    logic RxD, TxD, CLK100MHZ, reset, halted, stdouted, stdouted2;
    logic clk, led0, led1, led2, led3, led0_b, led1_b, led2_b, led3_b;
    
    assign CLK100MHZ = clk;
    
    core #(.baud(12500000), .blinker_clk_freq(8)) dut (.*);
    
    parameter CLOCK_PERIOD = 100;
    initial begin
        clk <= 0;
        forever #(CLOCK_PERIOD / 2) clk <= ~clk;
    end
    
    initial begin
        integer i;
        @(posedge clk) reset <= 1'b1;
        @(posedge clk) reset <= 1'b0;
        for (i = 0; i < 50000; i++) begin
        
            @(posedge clk);
        end
        
        $stop;
    end

endmodule  // core_testbench
