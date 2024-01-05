`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/27/2023 09:42:37 PM
// Design Name: 
// Module Name: opcodes
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

package opcodes;

    localparam LUI_OP    = 7'b0110111;
    localparam AUIPC_OP  = 7'b0010111;
    localparam JAL_OP    = 7'b1101111;
    localparam JALR_OP   = 7'b1100111;
    localparam BRANCH_OP = 7'b1100011;
    localparam LOAD_OP   = 7'b0000011;
    localparam STORE_OP  = 7'b0100011;
    localparam IRI_OP    = 7'b0010011;
    localparam IRR_OP    = 7'b0110011;

    localparam BEQ = 3'b000;
    localparam BNE = 3'b001;
    localparam BLT = 3'b100;
    localparam BGE = 3'b101;
    localparam BLTU = 3'b110;
    localparam BGEU = 3'b111;

    localparam LS_BYTE = 3'b000;
    localparam LS_HALF = 3'b001;
    localparam LS_WORD = 3'b010;
    localparam LS_UBYTE = 3'b100;
    localparam LS_UHALF = 3'b101;

    localparam NOP = 32'h00000013;
    
    localparam HALT_OP = 7'b1111111;

endpackage
