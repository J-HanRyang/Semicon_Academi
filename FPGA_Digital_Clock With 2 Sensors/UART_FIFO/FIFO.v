`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han, Jubin Hwang
// 
// Create Date	    : 2025/07/18
// Design Name      : Project_UART_FIFO
// Module Name      : FIFO
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : FIFO Module
//
// Revision 	    : 2025/07/19   Register_File edit
//////////////////////////////////////////////////////////////////////////////////

module FIFO(
    input           iClk,
    input           iRst,

    input           iPush,
    input           iPop,
    input   [7:0]   iWrData,

    output          oFull,
    output          oEmpty,
    output  [7:0]   oRdData    
);

    /***********************************************
    // Reg & Wire
    ***********************************************/
    wire    [4:0]   wWrAddr;
    wire    [4:0]   wRdAddr;


    /***********************************************
    // Instantiation
    ***********************************************/
    // Register File
    Register_File   U_Reg_File  (
        .iClk       (iClk),
        .iWr        (!oFull & iPush),
        .iWrAddr    (wWrAddr),
        .iWrData    (iWrData),
        .iRd        (!oEmpty & iPop),
        .iRdAddr    (wRdAddr),
        .oRdData    (oRdData)
    );

    // FIFO Controller
    FIFO_Ctrl       U_FIFO_Ctrl (
        .iClk       (iClk),
        .iRst       (iRst),
        .iPush      (iPush),
        .iPop       (iPop),
        .oFull      (oFull),
        .oEmpty     (oEmpty),
        .oWrAddr    (wWrAddr),
        .oRdAddr    (wRdAddr)
    );

endmodule
