`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/11
// Design Name      : Project_Clock
// Module Name      : Clock_Ctrl
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Control_Clock_Mode FSM_Model
//
// Revision 	    : 2025/07/11    --Start--
//                  : 2025/07/12    Delete Sec, mSec
//                                  Add FSM_Top Controller Connection
//                                  --Finish--
//////////////////////////////////////////////////////////////////////////////////

module Clock_Ctrl(
    input           iClk,
    input           iRst,
    input           iClock,

    input           iSet,

    input           iBtn_U,
    input           iBtn_D,
    input           iBtn_L,
    input           iBtn_R,

    output          oHour_Up,
    output          oHour_Down,
    output          oMin_Up,
    output          oMin_Down,

    output          oSet_Hour,
    output          oSet_Min
);

    
    // Paramter
    parameter       p_Clock = 2'b00,
                    p_Hour  = 2'b01,
                    p_Min   = 2'b10;

    
    // Reg & Wire
    reg     [1:0]   rState_Cur;
    reg     [1:0]   rState_Nxt;

    

    /***********************************************
    // FSM 
    ***********************************************/
    // Current State Update
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
            rState_Cur  <= p_Clock;
        else
            rState_Cur  <= rState_Nxt;
    end

    // Next State Decision
    always  @(*)
    begin
        rState_Nxt  = rState_Cur;

        case (rState_Cur)
            p_Clock : begin
                if  (iSet)
                    rState_Nxt  = p_Hour;
                else
                    rState_Nxt  = rState_Cur;
            end

            p_Hour  : begin
                if      (iBtn_R)
                    rState_Nxt  = p_Min;
                else if (!iSet)
                    rState_Nxt  = p_Clock;
                else
                    rState_Nxt  = rState_Cur;
            end

            p_Min   : begin
                if      (iBtn_L)
                    rState_Nxt  = p_Hour;
                else if (!iSet)
                    rState_Nxt  = p_Clock;
                else
                    rState_Nxt  = rState_Cur;
            end

            default :
                    rState_Nxt  = rState_Cur;
        endcase
    end

    // Output Decision
    assign  oHour_Up    = ((rState_Cur == p_Hour)   && iBtn_U   && iClock)  ? 1'b1 : 1'b0;
    assign  oHour_Down  = ((rState_Cur == p_Hour)   && iBtn_D   && iClock)  ? 1'b1 : 1'b0;

    assign  oMin_Up     = ((rState_Cur == p_Min)    && iBtn_U   && iClock)  ? 1'b1 : 1'b0;
    assign  oMin_Down   = ((rState_Cur == p_Min)    && iBtn_D   && iClock)  ? 1'b1 : 1'b0;

    assign  oSet_Hour   =  (rState_Cur == p_Hour)                           ? 1'b1 : 1'b0;
    assign  oSet_Min    =  (rState_Cur == p_Min)                            ? 1'b1 : 1'b0;

endmodule