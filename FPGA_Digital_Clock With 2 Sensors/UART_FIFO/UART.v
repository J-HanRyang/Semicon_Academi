`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han, Jubin Hwang
// 
// Create Date	    : 2025/07/15
// Design Name      : Project_UART_FIFO
// Module Name      : UART_Top
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : UART Top Module
//////////////////////////////////////////////////////////////////////////////////

module UART(
    // Clock & Reset
    input           iClk,
    input           iRst,

    //  Rx Signal
    input           iTx_Start,
    input   [7:0]   iTx_Data,
    input           iRx,

    output          oTx,
    output          oTx_Busy,
    output          oTx_Done,
    output  [7:0]   oRx_Data,
    output          oRx_Busy,
    output          oRx_Done
    );


    /***********************************************
    // Reg & Wire
    ***********************************************/
    wire            wB_Tick;


    /***********************************************
    // Instantiation
    ***********************************************/
    // 9600Hz Signal
    Baud_Tick_Gen   U_Baud      (
        .iClk       (iClk),
        .iRst       (iRst),
        .oB_Tick    (wB_Tick)
    );

    // UART_Rx
    UART_Rx         U_UART_RX (
        .iClk       (iClk),
        .iRst       (iRst),
        .iB_Tick    (wB_Tick),
        .iRx        (iRx),
        .oRx_Data   (oRx_Data),
        .oRx_Busy   (oRx_Busy),
        .oRx_Done   (oRx_Done)
    );

    // UART_Tx
    UART_Tx         U_UART_Tx   (
        .iClk       (iClk),
        .iRst       (iRst),
        .iB_Tick    (wB_Tick),
        .iTx_Start  (iTx_Start),
        .iTx_Data   (iTx_Data),
        .oTx_Busy   (oTx_Busy),
        .oTx_Done   (oTx_Done),
        .oTx        (oTx)
    );

endmodule
