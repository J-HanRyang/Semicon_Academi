`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/18
// Design Name      : Project_UART_FIFO
// Module Name      : Register_File
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : FIFO Module
//
// Revision 	    : 2025/07/19    Add iRd
//////////////////////////////////////////////////////////////////////////////////

module Register_File(
    input           iClk,

    input           iWr,
    input   [4:0]   iWrAddr,
    input   [7:0]   iWrData,

    input           iRd,
    input   [4:0]   iRdAddr,
    output  [7:0]   oRdData
);

    // Reg & Wire
    reg     [7:0]   rMem[0:31];

    always  @(posedge iClk)
    begin
        if  (iWr)
            rMem[iWrAddr]   <= iWrData;
        else
            rMem[iWrAddr]   <= rMem[iWrAddr];   
    end

    assign  oRdData = iRd ? rMem[iRdAddr] : 8'hz;

endmodule
