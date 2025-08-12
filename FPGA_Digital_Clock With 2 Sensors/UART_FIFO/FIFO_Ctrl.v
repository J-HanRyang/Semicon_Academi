`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/18
// Design Name      : Project_UART_FIFO
// Module Name      : FIFO_Ctrl
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : FIFO Controller
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////

module FIFO_Ctrl(
    input           iClk,
    input           iRst,

    input           iPush,
    input           iPop,

    output          oFull,
    output          oEmpty,
    output  [4:0]   oWrAddr,
    output  [4:0]   oRdAddr    
    );

    // Reg & Wire
    reg     [4:0]   rWrPtr_Cur;
    reg     [4:0]   rWrPtr_Nxt;

    reg     [4:0]   rRdPtr_Cur;
    reg     [4:0]   rRdPtr_Nxt;

    reg             rFull_Cur;
    reg             rFull_Nxt;

    reg             rEmpty_Cur;
    reg             rEmpty_Nxt;

    /***********************************************
    // FSM 
    ***********************************************/
    // Current Update
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            rWrPtr_Cur  <= 0;
            rRdPtr_Cur  <= 0;
            rFull_Cur   <= 0;
            rEmpty_Cur  <= 1;
        end else
        begin
            rWrPtr_Cur  <= rWrPtr_Nxt;
            rRdPtr_Cur  <= rRdPtr_Nxt;
            rFull_Cur   <= rFull_Nxt;
            rEmpty_Cur  <= rEmpty_Nxt;
        end
    end

    // Next Decision
    always  @(*)
    begin
        rWrPtr_Nxt  = rWrPtr_Cur;
        rRdPtr_Nxt  = rRdPtr_Cur;
        rFull_Nxt   = rFull_Cur;
        rEmpty_Nxt  = rEmpty_Cur;

        case ({iPush, iPop})
            2'b00   : ; // Reset

            2'b01   :
            begin
                if          (!rEmpty_Cur)
                begin
                    rRdPtr_Nxt  = rRdPtr_Cur + 1;
                    rFull_Nxt   = 0;

                    if  (rWrPtr_Cur == rRdPtr_Nxt)
                        rEmpty_Nxt  = 1;
                    else
                        rEmpty_Nxt  = rEmpty_Cur;
                end else
                    rRdPtr_Nxt  = rRdPtr_Cur;
            end

            2'b10   :
            begin
                if          (!rFull_Cur)
                begin
                    rWrPtr_Nxt  = rWrPtr_Cur + 1;
                    rEmpty_Nxt  = 0;

                    if  (rWrPtr_Nxt == rRdPtr_Cur)
                        rFull_Nxt   = 1;
                    else
                        rFull_Nxt   = 0;
                end else
                    rWrPtr_Nxt  = rWrPtr_Cur;   
                
            end

            2'b11   :
            begin
                if          (rEmpty_Cur)
                begin
                    rWrPtr_Nxt  = rWrPtr_Cur + 1;
                    rEmpty_Nxt  = 0;
                end else if (rFull_Cur)
                begin
                    rRdPtr_Nxt  = rRdPtr_Cur + 1;
                    rFull_Nxt   = 0;
                end else
                begin
                    rRdPtr_Nxt  = rRdPtr_Cur + 1;
                    rWrPtr_Nxt  = rWrPtr_Cur + 1;
                end
            end
        endcase
    end

    // Output Decision
    assign  oWrAddr = rWrPtr_Cur;
    assign  oRdAddr = rRdPtr_Cur;
    assign  oFull   = rFull_Cur;
    assign  oEmpty  = rEmpty_Cur;

endmodule
