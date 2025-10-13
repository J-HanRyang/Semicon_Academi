`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/09/22
// Design Name      : RV32I
// Module Name      : RV32I_Core
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Ctrl + DP
//////////////////////////////////////////////////////////////////////////////////

module RV32I_Core(
    input   logic           iClk,
    input   logic           iRst,

    input   logic   [31:0]  iInst_Code,
    input   logic   [31:0]  iData_RdData,

    output  logic   [2:0]   oFunct3,
    output  logic   [31:0]  oInst_RdAddr,
    output  logic           oData_WrEn,
    output  logic   [31:0]  oData_Addr,
    output  logic   [31:0]  oData_WrData
    );


    /***********************************************
    // Reg & Wire - Logic
    ***********************************************/
    logic   [3:0]   wALU_Control;
    logic   [1:0]   wRegWrDataSel;
    logic           wALUSrcMuxSel1;
    logic           wALUSrcMuxSel2;
    logic           wWrEn;
    logic   [1:0]   wPC_Sel;
    logic           wBtaken;
    

    /***********************************************
    // Instantiation
    ***********************************************/
    Control_Uint    U_Ctrl  (
        .iInst_Code     (iInst_Code),
        .iBtaken        (wBtaken),
        .oFunct3        (oFunct3),
        .oALU_Control   (wALU_Control),
        .oRegWrDataSel  (wRegWrDataSel),
        .oALUSrcMuxSel1 (wALUSrcMuxSel1),
        .oALUSrcMuxSel2 (wALUSrcMuxSel2),
        .oWrEn          (wWrEn),
        .oData_WrEn     (oData_WrEn),
        .oPC_Sel        (wPC_Sel)
    );

    DataPath    U_DP    (
        .iClk           (iClk),
        .iRst           (iRst),
        .iInst_Code     (iInst_Code),
        .iData_RdData   (iData_RdData),
        .iALU_Control   (wALU_Control),
        .iRegWrDataSel  (wRegWrDataSel),
        .iALUSrcMuxSel1 (wALUSrcMuxSel1),
        .iALUSrcMuxSel2 (wALUSrcMuxSel2),
        .iWrEn          (wWrEn),
        .iPC_Sel        (wPC_Sel),
        .oBtaken        (wBtaken),
        .oInst_RdAddr   (oInst_RdAddr),
        .oData_Addr     (oData_Addr),
        .oData_WrData   (oData_WrData)
    );

endmodule