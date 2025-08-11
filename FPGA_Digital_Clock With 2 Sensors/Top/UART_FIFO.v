`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/25
// Design Name      : Project_Sensor
// Module Name      : UART_FIFO
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : UART_FIFO Top Module
//////////////////////////////////////////////////////////////////////////////////

module UART_FIFO(
    // Clock & Reset
    input           iClk,
    input           iRst,

    // Connect PC
    input           iRx,
    output          oTx,

    // Rx
    input           iRx_Pop,
    output  [7:0]   oRx_Data,

    // Tx
    input           iTx_Push,
    input   [7:0]   iTx_Data,

    output          oTx_Busy,
    output          oTx_Full
    );


    /***********************************************
    // Reg & Wire
    ***********************************************/
    wire            wTx_Busy;
    wire            wRx_Done;
    wire            wTx_Empty;
    wire            wRx_Busy;
    wire    [7:0]   wTx_Data;
    wire    [7:0]   wRx_Data;

    /***********************************************
    // Instantiation
    ***********************************************/
    // UART
    UART             U_UART     (
        .iClk       (iClk),
        .iRst       (iRst),
        .iTx_Start  (!wTx_Empty),
        .iTx_Data   (wTx_Data),
        .iRx        (iRx),
        .oTx        (oTx),
        .oTx_Busy   (wTx_Busy),
        .oTx_Done   (),
        .oRx_Data   (wRx_Data),
        .oRx_Busy   (),
        .oRx_Done   (wRx_Done)
    );

    // FIFO
    FIFO            U_Tx_FIFO   (
        .iClk       (iClk),
        .iRst       (iRst),
        .iPush      (iTx_Push),
        .iPop       (!wTx_Busy),
        .iWrData    (iTx_Data),
        .oFull      (oTx_Full),
        .oEmpty     (wTx_Empty),
        .oRdData    (wTx_Data)
    );

    FIFO            U_Rx_FIFO   (
        .iClk       (iClk),
        .iRst       (iRst),
        .iPush      (wRx_Done),
        .iPop       (1'b1),
        .iWrData    (wRx_Data),
        .oFull      (),
        .oEmpty     (),
        .oRdData    (oRx_Data)
    );

endmodule
