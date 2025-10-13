`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/09/19
// Design Name      : RV32I
// Module Name      : Datapath
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Datapath of RISC-V 32I
//
// Revision 	    : 2025/09/22    Update ALU (ADD Define File)
//                    2025/09/23    Add IL_Type
//                    2025/09/24    Add I_Type
//                    2025/09/25    Add B_Type
//                    2025/09/26    Add U, L_Type
//////////////////////////////////////////////////////////////////////////////////

`include "Define.sv"

module DataPath(
    input   logic           iClk,
    input   logic           iRst,

    input   logic   [31:0]  iInst_Code,
    input   logic   [31:0]  iData_RdData,
    input   logic   [3:0]   iALU_Control,
    input   logic   [1:0]   iRegWrDataSel,
    input   logic           iALUSrcMuxSel1,
    input   logic           iALUSrcMuxSel2,
    input   logic           iWrEn,
    input   logic   [1:0]   iPC_Sel,

    output  logic           oBtaken,
    output  logic   [31:0]  oInst_RdAddr,
    output  logic   [31:0]  oData_Addr,
    output  logic   [31:0]  oData_WrData
);

    /***********************************************
    // Reg & Wire - Logic
    ***********************************************/
    logic   [31:0]  wRegfile_RdData1;
    logic   [31:0]  wRegfile_RdData2;
    logic   [31:0]  wRegWrDataOut;
    logic   [31:0]  wALU_Result;
    logic   [31:0]  wImm_Ext;
    logic   [31:0]  wALUSrcMuxOut1;
    logic   [31:0]  wALUSrcMuxOut2;
    logic   [31:0]  wPCMuxOut;
    logic   [31:0]  wPC_4;
    logic   [31:0]  wPC_Imm;
    logic   [31:0]  wPC_Nxt;

    /***********************************************
    // Instantiation
    ***********************************************/
    Mux_4x1 U_PC_MUX    (
        .iSel   (iPC_Sel),
        .iX0    (wPC_4),
        .iX1    (wPC_Imm),
        .iX2    (wALU_Result),
        .iX3    (32'bx),
        .oY     (wPC_Nxt)
    );

    Adder   U_PC_4  (
        .iA     (oInst_RdAddr),
        .iB     (32'd4),
        .oSum   (wPC_4)
    );

    Adder   U_PC_Imm    (
        .iA     (oInst_RdAddr),
        .iB     (wImm_Ext),
        .oSum   (wPC_Imm)
    );

    Program_Counter U_PC(
        .iClk       (iClk),
        .iRst       (iRst),
        .iPC_Nxt    (wPC_Nxt),
        .oPC        (oInst_RdAddr)
    );

    Register_File   U_Reg_File  (
        .iClk       (iClk),
        .iWrEn      (iWrEn),
        .iWrAddr    (iInst_Code[11:7]),
        .iWrData    (wRegWrDataOut),
        .iRdAddr1   (iInst_Code[19:15]),
        .iRdAddr2   (iInst_Code[24:20]),
        .oRdData1   (wRegfile_RdData1),
        .oRdData2   (wRegfile_RdData2)
    );

    Entend  U_Extend    (
        .iInst_Code (iInst_Code),
        .oImm_Ext   (wImm_Ext)
    );
    
    Mux_2x1 U_ALUSrcMux1    (
        .iSel   (iALUSrcMuxSel1),
        .iX0    (wRegfile_RdData1),
        .iX1    (oInst_RdAddr),
        .oY     (wALUSrcMuxOut1)
    );

    Mux_2x1 U_ALUSrcMux2    (
        .iSel   (iALUSrcMuxSel2),
        .iX0    (wRegfile_RdData2),
        .iX1    (wImm_Ext),
        .oY     (wALUSrcMuxOut2)
    );

    ALU U_ALU   (
        .iALU_Control   (iALU_Control),
        .iA             (wALUSrcMuxOut1),
        .iB             (wALUSrcMuxOut2),
        .oALU_Result    (wALU_Result),
        .oBtaken        (oBtaken)
    );

    Mux_4x1 U_RegWrDataMux  (
        .iSel   (iRegWrDataSel),
        .iX0    (wALU_Result),
        .iX1    (iData_RdData),
        .iX2    (wImm_Ext),
        .iX3    (wPC_4),
        .oY     (wRegWrDataOut)
    );


    assign  oData_Addr      = wALU_Result;
    assign  oData_WrData    = wRegfile_RdData2;
    
endmodule


/***********************************************
// Sub Modules
***********************************************/
module Adder (
    input   logic   [31:0]  iA,
    input   logic   [31:0]  iB,

    output  logic   [31:0]  oSum
);

    assign  oSum    = iA + iB;

endmodule

module Program_Counter (
    input   logic           iClk,
    input   logic           iRst,
    input   logic   [31:0]  iPC_Nxt,

    output  logic   [31:0]  oPC
);

    Register    U_PC_REG    (
        .iClk   (iClk),
        .iRst   (iRst),
        .iD     (iPC_Nxt),
        .oQ     (oPC)
);

endmodule

module Register (
    input   logic           iClk,
    input   logic           iRst,

    input   logic   [31:0]  iD,

    output  logic   [31:0]  oQ
);

    always_ff @(posedge iClk, posedge iRst )
    begin
        if (iRst)
            oQ  <= 0;
        else
            oQ  <= iD;
    end

endmodule

module Register_File (
    input   logic           iClk,

    input   logic           iWrEn,
    input   logic   [4:0]   iWrAddr,
    input   logic   [31:0]  iWrData,

    input   logic   [4:0]   iRdAddr1,
    input   logic   [4:0]   iRdAddr2,
    output  logic   [31:0]  oRdData1,
    output  logic   [31:0]  oRdData2
);

    // Reg & Wire - Logic
    logic   [31:0]  rReg_File[0:31];

    initial
    begin
         rReg_File[0]    = 32'd0;
    //     rReg_File[1]    = 32'd1;
    //     rReg_File[2]    = 32'd2;
    //     rReg_File[3]    = 32'd3;
    //     rReg_File[4]    = 32'd4;
    //     rReg_File[5]    = 32'd5;
    //     rReg_File[6]    = 32'd6;
    //     rReg_File[7]    = 32'd7;
    //     rReg_File[8]    = 32'd8;
    //     rReg_File[9]    = 32'd9;
    //     rReg_File[10]   = 32'hf0_00_00_00;
    //     rReg_File[11]   = 32'hff_00_00_00;
    //     rReg_File[14]   = 32'd14;
    //     rReg_File[15]   = 32'd15;
    //     rReg_File[16]   = 32'd16;
    //     rReg_File[17]   = 32'd17;
    //     rReg_File[18]   = 32'hdd_dd_dd_dd;
    //     rReg_File[19]   = 32'h00_00_ee_ee;
    //     rReg_File[20]   = 32'h00_00_00_ff;
    end

    always_ff @(posedge iClk)
    begin
        if (iWrEn)
            rReg_File[iWrAddr]  <= iWrData;
    end

    assign  oRdData1    = (iRdAddr1 != 0) ? rReg_File[iRdAddr1] : 0;
    assign  oRdData2    = (iRdAddr2 != 0) ? rReg_File[iRdAddr2] : 0;

endmodule

module ALU (
    input   logic   [3:0]   iALU_Control,
    input   logic   [31:0]  iA,
    input   logic   [31:0]  iB,
    
    output  logic   [31:0]  oALU_Result,
    output  logic           oBtaken
);

    always_comb
    begin
        case (iALU_Control)
            `ADD    : oALU_Result   = iA + iB;
            `SUB    : oALU_Result   = iA - iB;
            `SLL    : oALU_Result   = iA << iB[4:0]; 
            `SRL    : oALU_Result   = iA >> iB[4:0];
            `SRA    : oALU_Result   = $signed(iA) >>> iB[4:0];
            `SLT    : oALU_Result   = $signed(iA) < $signed(iB);
            `SLTU   : oALU_Result   = iA < iB;
            `XOR    : oALU_Result   = iA ^ iB;
            `OR     : oALU_Result   = iA | iB;
            `AND    : oALU_Result   = iA & iB;
            default : oALU_Result   = 32'bx;
        endcase    
    end

    // Branch
    always_comb
    begin
        case (iALU_Control[2:0])
            `BEQ    : oBtaken   = ($signed(iA) == $signed(iB));
            `BNE    : oBtaken   = ($signed(iA) != $signed(iB));
            `BLT    : oBtaken   = ($signed(iA) <  $signed(iB));
            `BGE    : oBtaken   = ($signed(iA) >= $signed(iB));
            `BLTU   : oBtaken   = ($unsigned(iA) <  $unsigned(iB));
            `BGEU   : oBtaken   = ($unsigned(iA) >= $unsigned(iB));
            default : oBtaken   = 1'b0;
        endcase    
    end
endmodule

module Entend (
    input   logic   [31:0]  iInst_Code,
    
    output  logic   [31:0]  oImm_Ext
);

    // Reg & Wire
    logic   [6:0]   wOPcode;
    logic   [2:0]   wFunct3;
    logic   [6:0]   wFunct7;

    assign  wOPcode = iInst_Code[6:0];
    assign  wFunct3 = iInst_Code[14:12];
    assign  wFunct7 = iInst_Code[31:25];

    always_comb
    begin
        case (wOPcode)
            `OP_R_TYPE  : oImm_Ext  = 32'bx;
            `OP_S_TYPE  : oImm_Ext  = {{20{iInst_Code[31]}}, iInst_Code[31:25], iInst_Code[11:7]};
            `OP_IL_TYPE : oImm_Ext  = {{20{iInst_Code[31]}}, iInst_Code[31:20]};
            `OP_I_TYPE  : oImm_Ext  = {{20{iInst_Code[31]}}, iInst_Code[31:20]};
            `OP_B_TYPE  : oImm_Ext  = {{20{iInst_Code[31]}}, iInst_Code[7], iInst_Code[30:25], iInst_Code[11:8], 1'b0};
            `OP_U1_TYPE : oImm_Ext  = {iInst_Code[31:12],   {12{1'b0}}};
            `OP_U2_TYPE : oImm_Ext  = {iInst_Code[31:12],   {12{1'b0}}};
            `OP_J1_TYPE : oImm_Ext  = {{12{iInst_Code[31]}}, iInst_Code[19:12], iInst_Code[20], iInst_Code[30:21], 1'b0};
            `OP_J2_TYPE : oImm_Ext  = {{20{iInst_Code[31]}}, iInst_Code[31:20]};
            default     : oImm_Ext  = 32'bx;
        endcase
    end

endmodule

module Mux_2x1 (
    input   logic           iSel,
    input   logic   [31:0]  iX0,
    input   logic   [31:0]  iX1,

    output  logic   [31:0]  oY
);

    assign  oY = iSel ? iX1 : iX0;

endmodule

module Mux_4x1 (
    input   logic   [1:0]   iSel,
    input   logic   [31:0]  iX0,    // 0 : Alu_Result
    input   logic   [31:0]  iX1,    // 1 : Data_RdData
    input   logic   [31:0]  iX2,    // 2 : Imm[31:0]
    input   logic   [31:0]  iX3,    // 3 : PC+4

    output  logic   [31:0]  oY
);

    always_comb
    begin
        case (iSel)
            2'b00   : oY = iX0;
            2'b01   : oY = iX1;
            2'b10   : oY = iX2;
            2'b11   : oY = iX3;
            default : oY = iX0;
        endcase
    end

endmodule