`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/21
// Design Name      : Project_UART_FIFO
// Module Name      : Decoder
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : ASCII Decoder
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////


module Decoder(
    input           iClk,
    input           iRst,

    input   [7:0]   iAscii,

    output          oSet,
    output  [4:0]   oMode,
    output          oBtn_U,
    output          oBtn_D,
    output          oBtn_L,
    output          oBtn_R,

    output          oTime_En
    );

    // Reg & Wire
    reg             rSet_Cur;
    reg             rSet_Nxt;

    reg     [3:0]   rMode_Cur;
    reg     [3:0]   rMode_Nxt;

    reg             rFND_Mode_Cur;
    reg             rFND_Mode_Nxt;

    reg     [3:0]   rBtn_Cur;
    reg     [3:0]   rBtn_Nxt;

    wire            wMode_0;


    always @(posedge iClk, posedge iRst)
    begin
        if (iRst)
        begin
            rSet_Cur        <= 1'b0;
            rMode_Cur       <= 3'b000;
            rFND_Mode_Cur   <= 1'b0;
            rBtn_Cur        <= 4'b0000;

        end else
        begin
            rSet_Cur        <= rSet_Nxt;
            rMode_Cur       <= rMode_Nxt;
            rFND_Mode_Cur   <= rFND_Mode_Nxt;
            rBtn_Cur        <= rBtn_Nxt;
        end
    end

    always  @(*)
    begin
        rSet_Nxt        = rSet_Cur;
        rMode_Nxt       = rMode_Cur;
        rFND_Mode_Nxt   = rFND_Mode_Cur;
        rBtn_Nxt        = rBtn_Cur;

        // Mode Select
        case (iAscii)
            8'h43     : rMode_Nxt = 4'b0000;
            8'h57     : rMode_Nxt = 4'b0001;
            8'h54     : rMode_Nxt = 4'b0010;
            8'h55     : rMode_Nxt = 4'b0100;
            8'h44     : rMode_Nxt = 4'b1000;
            default : rMode_Nxt = rMode_Cur;
        endcase

        // Butten Select
        case (iAscii)
            "u"     : rBtn_Nxt = 4'b1000;
            "d"     : rBtn_Nxt = 4'b0100;
            "l"     : rBtn_Nxt = 4'b0010;
            "r"     : rBtn_Nxt = 4'b0001;
            default : rBtn_Nxt = 4'b0;
        endcase

        // Fnd Mode Select      // M
        if      ((rFND_Mode_Cur == 0)   && (iAscii == "M"))
            rFND_Mode_Nxt   = 1'b1;
        else if ((rFND_Mode_Cur == 1)   && (iAscii == "M"))
            rFND_Mode_Nxt   = 1'b0;
        else
            rFND_Mode_Nxt   = rFND_Mode_Cur;

        // Set Mode Select      // S
        if      ((rSet_Cur      == 0)   && (iAscii == "S"))
            rSet_Nxt        = 1'b1;
        else if ((rSet_Cur      == 1)   && (iAscii == "S"))
            rSet_Nxt        = 1'b0;
        else
            rSet_Nxt        = rSet_Cur;

    end

    assign  oSet    =   rSet_Cur;
    assign  wMode_0 =   rFND_Mode_Cur;
    assign  oMode   =   {rMode_Cur,wMode_0};

    assign  oBtn_U  =   rBtn_Cur[3];
    assign  oBtn_D  =   rBtn_Cur[2];
    assign  oBtn_L  =   rBtn_Cur[1];
    assign  oBtn_R  =   rBtn_Cur[0];

endmodule
