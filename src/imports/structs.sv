`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/27/2023 09:37:06 PM
// Design Name: 
// Module Name: structs
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


package structs;

    localparam word_width = 32;
    localparam reg_addr_width = 5;
    localparam instruction_width = 97;

    typedef struct packed {
        logic is_pred_branch;
        logic [word_width-1:0] inst_addr;
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [reg_addr_width-1:0] rd;
        logic [reg_addr_width-1:0] rs1;
        logic [reg_addr_width-1:0] rs2;
        logic [6:0] funct7;
        logic [word_width-1:0] imm;
    } instruction;

    typedef struct packed {
        logic zero;
        logic overflow;
        logic negative;
    } alu_signal;

endpackage
