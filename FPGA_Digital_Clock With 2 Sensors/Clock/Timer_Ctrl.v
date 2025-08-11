`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/13
// Design Name      : Project_Clock
// Module Name      : Timer_Ctrl
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Timer Controller FSM
//
// Revision         : 2025/07/14
//                    2025/07/21    --Finish--
//////////////////////////////////////////////////////////////////////////////////

module Timer_Ctrl(
    input           iClk,
    input           iRst,
    input           iTimer,
    input           iSet,
    input           iEnd,

    input           iBtn_U,
    input           iBtn_D,
    input           iBtn_L,
    input           iBtn_R,

    output          oRun_Stop,
    output          oClear,
    output          oDown,

    output          oHour_Up,
    output          oHour_Down,
    output          oMin_Up,
    output          oMin_Down,
    output          oSec_Up,
    output          oSec_Down,

    output          oSet_Hour,
    output          oSet_Min,
    output          oSet_Sec,

    output          oEnd
);


    // Parameter / State
    parameter       p_Timer = 3'b000,
                    p_Run   = 3'b001,
                    p_Clear = 3'b010,
                    p_Hour  = 3'b011,
                    p_Min   = 3'b100,
                    p_Sec   = 3'b101,
                    p_End   = 3'b110;

    
    // Reg & Wire
    reg     [2:0]   rState_Cur;
    reg     [2:0]   rState_Nxt;

    reg             rClear_Current;
    reg             rClear_next;

    reg     [2:0]   rBlink_Counter;


    /***********************************************
    // FSM 
    ***********************************************/
    // Current State Update
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            rState_Cur      <= p_Timer;
            rClear_Current  <= 1'b0;
        end
        else
        begin
            rState_Cur      <= rState_Nxt;
            rClear_Current  <= rClear_next;
        end
    end

    // Next State Decision
    always  @(*)
    begin
        rState_Nxt  = rState_Cur;
        rClear_next = rClear_Current;

        case (rState_Cur)
            p_Timer :
            begin
                    rClear_next = 1'b0;
                if      (iSet   && iTimer)
                    rState_Nxt  = p_Sec;
                else if (iBtn_L && iTimer)
                    rState_Nxt  = p_Clear;
                else if (iBtn_R && iTimer)
                    rState_Nxt  = p_Run;
                else
                    rState_Nxt  = rState_Cur;
            end
                
            p_Run   :
            begin
                if      (iBtn_R && iTimer)
                    rState_Nxt  = p_Timer;
                else if (iEnd)
                    rState_Nxt  = p_End;
                else
                    rState_Nxt  = rState_Cur;
            end

            p_Clear :
            begin
                    rState_Nxt  = p_Timer;
                    rClear_next = 1'b1;
            end

            p_Hour  :
            begin
                if      (iBtn_R)
                    rState_Nxt  = p_Min;
                else if (!iSet  && iTimer)
                    rState_Nxt  = p_Timer;
                else
                    rState_Nxt  = rState_Cur;
            end

            p_Min   :
            begin
                if      (iBtn_R)
                    rState_Nxt  = p_Sec;
                else if (iBtn_L)
                    rState_Nxt  = p_Hour;
                else if (!iSet  && iTimer)
                    rState_Nxt  = p_Timer;
                else
                    rState_Nxt  = rState_Cur;
            end

            p_Sec   :
            begin
                if      (iBtn_L)
                    rState_Nxt  = p_Min;
                else if (!iSet  && iTimer)
                    rState_Nxt  = p_Timer;
                else
                    rState_Nxt  = rState_Cur;
            end

            p_End   :
            begin
                if      (iBtn_U)
                    rState_Nxt  = p_Timer;
                else
                    rState_Nxt  = rState_Cur;
            end


            default :
            begin
                    rState_Nxt  = rState_Cur;
                    rClear_next = rClear_Current;
            end
        endcase
    end

    // Output Decision
    assign  oRun_Stop   =  (rState_Cur == p_Run)                            ? 1'b1 : 1'b0;
    assign  oClear      =   rClear_Current                                  ? 1'b1 : 1'b0;
    assign  oDown       =  (rState_Cur == p_Run)                            ? 1'b1 : 1'b0;          

    assign  oHour_Up    = ((rState_Cur == p_Hour)   && iBtn_U   && iTimer)  ? 1'b1 : 1'b0;
    assign  oHour_Down  = ((rState_Cur == p_Hour)   && iBtn_D   && iTimer)  ? 1'b1 : 1'b0;

    assign  oMin_Up     = ((rState_Cur == p_Min)    && iBtn_U   && iTimer)  ? 1'b1 : 1'b0;
    assign  oMin_Down   = ((rState_Cur == p_Min)    && iBtn_D   && iTimer)  ? 1'b1 : 1'b0;

    assign  oSec_Up     = ((rState_Cur == p_Sec)    && iBtn_U   && iTimer)  ? 1'b1 : 1'b0;
    assign  oSec_Down   = ((rState_Cur == p_Sec)    && iBtn_D   && iTimer)  ? 1'b1 : 1'b0;

    assign  oSet_Hour   =  (rState_Cur == p_Hour)                           ? 1'b1 : 1'b0;
    assign  oSet_Min    =  (rState_Cur == p_Min)                            ? 1'b1 : 1'b0;
    assign  oSet_Sec    =  (rState_Cur == p_Sec)                            ? 1'b1 : 1'b0;
    
    assign  oEnd        =  (rState_Cur == p_End)                            ? 1'b1 : 1'b0;

    endmodule