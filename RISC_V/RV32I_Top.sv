`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/09/19
// Design Name      : RV32I
// Module Name      : RV32I_Top
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : ROM + CPU_Core
//////////////////////////////////////////////////////////////////////////////////

module RV32I_Top(
    // Clock & Reset
    input   logic   iClk,
    input   logic   iRst
    );


    /***********************************************
    // Reg & Wire - Logic
    ***********************************************/
    logic   [31:0]  wRdData;
    logic   [31:0]  wData_RdData;
    logic   [31:0]  wRdAddr;
    logic           wData_WrEn;
    logic   [31:0]  wData_Addr;
    logic   [31:0]  wData_WrData;

    logic   [2:0]   wFunct3;

    /***********************************************
    // Instantiation
    ***********************************************/	
    Inst_ROM    U_ROM   (
        .iRdAddr    (wRdAddr),
        .oRdData    (wRdData)
    )   ;

    RV32I_Core  U_RV32I_CPU (
        .iClk           (iClk),
        .iRst           (iRst),
        .iInst_Code     (wRdData),
        .iData_RdData   (wData_RdData),
        .oFunct3        (wFunct3),
        .oInst_RdAddr   (wRdAddr),
        .oData_WrEn     (wData_WrEn),
        .oData_Addr     (wData_Addr),
        .oData_WrData   (wData_WrData)
    );

    Data_RAM    U_RAM   (
        .iClk           (iClk),
        .iFunct3        (wFunct3),
        .iData_WrEn     (wData_WrEn),
        .iData_Addr     (wData_Addr),
        .iData_WrData   (wData_WrData),
        .oData_RdData   (wData_RdData)
    );

endmodule