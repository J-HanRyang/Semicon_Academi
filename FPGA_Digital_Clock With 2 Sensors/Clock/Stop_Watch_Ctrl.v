`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/11
// Design Name      : Project_Clock
// Module Name      : Stop_Watch_Ctrl
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Stop_Watch_Controller FSM_Model
//
// Revision         : 2025/7/12     Add FSM_Top Controller Connection
//                                  --Finish--
//////////////////////////////////////////////////////////////////////////////////

module Stop_Watch_Ctrl(
    input           iClk,
    input           iRst,
    input           iStop_Watch,

    input           iBtn_L,
    input           iBtn_R,


    output          oRun_Stop,
    output          oClear
    );


    // Parameter / State
    parameter       p_Stop  = 2'b00,
                    p_Run   = 2'b01,
                    p_Clear = 2'b10;

    
    // Reg & Wire
    reg     [1:0]   rState_Cur;
    reg     [1:0]   rState_Nxt;

    reg             rClear_Current;
    reg             rClear_next;


    /***********************************************
    // FSM 
    ***********************************************/
    // Current State Update
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            rState_Cur      <= p_Stop;
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
            p_Stop :
            begin
                    rClear_next = 1'b0;

                if      (iBtn_L && iStop_Watch)
                    rState_Nxt  = p_Clear;
                else if (iBtn_R && iStop_Watch)
                    rState_Nxt  = p_Run;
                else
                    rState_Nxt  = rState_Cur;
            end

                
            p_Run   :
            begin
                if      (iBtn_R && iStop_Watch)
                    rState_Nxt  = p_Stop;
                else
                    rState_Nxt  = rState_Cur;
            end

            p_Clear :
            begin
                    rState_Nxt  = p_Stop;
                    rClear_next = 1'b1;
            end

            default :
            begin
                    rState_Nxt  = rState_Cur;
                    rClear_next = rClear_Current;
            end
        endcase
    end

    // Output Decision
    assign  oRun_Stop   = (rState_Cur == p_Run) ? 1'b1 : 1'b0;
    assign  oClear      =  rClear_Current       ? 1'b1 : 1'b0;
    
    endmodule

