`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/09/19
// Design Name      : RV32I
// Module Name      : Control_Unit
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Control_Unit of RISC-V 32I
//
// Revision 	    : 2025/09/22    Modify oALU_Control 
//                                  Add S-Type, Funct3 output
//                    2025/09/24    Add I-Type
//                    2025/09/25    Add B_Type
//                    2025/09/26    Add U, L_Type
//////////////////////////////////////////////////////////////////////////////////

`include "Define.sv"

module Control_Uint(
    input   logic   [31:0]  iInst_Code,
    input   logic           iBtaken,

    output  logic   [2:0]   oFunct3,
    output  logic   [3:0]   oALU_Control,
    output  logic   [1:0]   oRegWrDataSel,
    output  logic           oALUSrcMuxSel1,
    output  logic           oALUSrcMuxSel2,
    output  logic           oWrEn,
    output  logic           oData_WrEn,
    output  logic   [1:0]   oPC_Sel
    );

    // Reg & Wire - Logic
    logic   [6:0]   wFunct7;
    logic   [2:0]   wFunct3;
    logic   [6:0]   wOPcode;
    logic   [7:0]   wControl;


    assign  wFunct7 = iInst_Code[31:25];
    assign  wFunct3 = iInst_Code[14:12];
    assign  wOPcode = iInst_Code[6:0];

    assign  oFunct3 = wFunct3;

    // Function
    always_comb
    begin
        oALU_Control    = `ADD;
        oRegWrDataSel   = 2'b0;
        oALUSrcMuxSel1  = 1'b0;
        oALUSrcMuxSel2  = 1'b0;
        oWrEn           = 1'b0;
        oData_WrEn      = 1'b0;
        oPC_Sel         = 2'b0;

        case (wOPcode)
            `OP_R_TYPE  :   // R-Type
            begin
                oALU_Control    = {wFunct7[5], wFunct3};
                oWrEn           = 1'b1;
            end

            `OP_S_TYPE  :   // S-Type
            begin
                oALUSrcMuxSel2  = 1'b1;
                oData_WrEn      = 1'b1;
            end

            `OP_IL_TYPE :   // I-Type1
            begin
                oALUSrcMuxSel2  = 1'b1;
                oWrEn           = 1'b1;
                oRegWrDataSel   = 2'b01;

            end

            `OP_I_TYPE  :   // I-Type2 (I+R)
            begin
                if (wFunct3 == 3'b101)
                    oALU_Control    = {wFunct7[5], wFunct3};
                else
                    oALU_Control    = {1'b0, wFunct3};

                oALUSrcMuxSel2  = 1'b1;
                oWrEn           = 1'b1;
            end

            `OP_B_TYPE  :   //B_Type
            begin
                oALU_Control    = {1'b0, wFunct3};

                if (iBtaken)
                    oPC_Sel = 2'b01;
            end

            `OP_U1_TYPE :   // LUI
            begin
                oWrEn           = 1'b1;
                oRegWrDataSel   = 2'b10;
            end

            `OP_U2_TYPE :   // AUIPC
            begin
                oALUSrcMuxSel1  = 1'b1;
                oALUSrcMuxSel2  = 1'b1;
                oWrEn           = 1'b1;
                
            end

            `OP_J1_TYPE :   //JAL
            begin
                oWrEn           = 1'b1;
                oRegWrDataSel   = 2'b11;
                oPC_Sel         = 2'b01;
                
            end

            `OP_J2_TYPE :   // JALR
            begin
                oRegWrDataSel   = 2'b11;
                oALUSrcMuxSel2  = 1'b1;
                oWrEn           = 1'b1;
                oPC_Sel         = 2'b10;
            end

            default     :   ;
        endcase
    end
    
endmodule
