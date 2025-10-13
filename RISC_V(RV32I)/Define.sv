`timescale 1ns / 1ps

// R_TYPE ALU Command {Funct7[5], Funct3}
`define ADD     4'b0000
`define SUB     4'b1000
`define SLL     4'b0001
`define SRL     4'b0101
`define SRA     4'b1101
`define SLT     4'b0010
`define SLTU    4'b0011
`define XOR     4'b0100
`define AND     4'b0111
`define OR      4'b0110

// B_Type
`define BEQ     3'b000
`define BNE     3'b001
`define BLT     3'b100
`define BGE     3'b101
`define BLTU    3'b110
`define BGEU    3'b111


// DPCODE
`define OP_R_TYPE   7'b011_0011 // RD = RS1 + RS1
`define OP_S_TYPE   7'b010_0011 // SW, SH, SB
`define OP_IL_TYPE  7'b000_0011 // LW, LH, LB, LBU, HU
`define OP_I_TYPE   7'b001_0011 // RD = RS1 + IMM
`define OP_B_TYPE   7'b110_0011 // BEQ, BNE, BLT, BGE, BLTU, BGEU
`define OP_U1_TYPE  7'b011_0111 // LUI
`define OP_U2_TYPE  7'b001_0111 // AUIPC
`define OP_J1_TYPE  7'b110_1111 // JAL
`define OP_J2_TYPE  7'b110_0111 // JALR
