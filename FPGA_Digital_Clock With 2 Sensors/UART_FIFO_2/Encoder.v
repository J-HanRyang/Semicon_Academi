`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/22
// Design Name      : Project_UART_FIFO
// Module Name      : Encoder
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : ASCII Encoder
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////


module Encoder(
    input           iClk,
    input           iRst,

    input   [3:0]   iDec,

    output  [7:0]   oAscii
    );

    reg     [7:0]   rAscii;

    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
            rAscii  <= 0;
        else
        begin
            if  (iDec <= 4'h9)
                rAscii  = iDec + 8'h30;
            else
                rAscii  = 8'h30;
        end
    end

    assign  oAscii  = rAscii;

endmodule