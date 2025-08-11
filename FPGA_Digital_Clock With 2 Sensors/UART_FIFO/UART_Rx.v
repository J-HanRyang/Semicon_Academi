`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/17
// Design Name      : UART_FIFO
// Module Name      : UART_Rx
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : UART_Rx Mode FSM Controller
//////////////////////////////////////////////////////////////////////////////////

module UART_Rx(
    input           iClk,
    input           iRst,
    
    input           iB_Tick,
    input           iRx,

    output  [7:0]   oRx_Data,
    output          oRx_Busy,
    output          oRx_Done
    );

    // State Parameter
    parameter       p_Idle  = 0,
                    p_Start = 1,
                    p_Data  = 2,
                    p_Stop  = 3;

    // Reg & Wire
    reg     [1:0]   rState_Cur;
    reg     [1:0]   rState_Nxt;

    reg     [3:0]   rB_Tick_Cur;
    reg     [3:0]   rB_Tick_Nxt;

    reg     [2:0]   rData_Count_Cur;
    reg     [2:0]   rData_Count_Nxt;

    reg     [7:0]   rRx_Data_Cur;
    reg     [7:0]   rRx_Data_Nxt;

    reg             rRx_Busy;
    reg             rRx_Done;

    /***********************************************
    // FSM 
    ***********************************************/
    // Current State Update
    always  @(posedge iClk,  posedge iRst)
    begin
        if  (iRst)
        begin
            rState_Cur      <= 0;
            rB_Tick_Cur     <= 0;
            rData_Count_Cur <= 0;
            rRx_Data_Cur    <= 0;
        end else
        begin
            rState_Cur      <= rState_Nxt;
            rB_Tick_Cur     <= rB_Tick_Nxt;
            rData_Count_Cur <= rData_Count_Nxt;
            rRx_Data_Cur    <= rRx_Data_Nxt;
        end
    end

    // Next State Decision
    always  @(*)
    begin
        rState_Nxt      = rState_Cur;
        rB_Tick_Nxt     = rB_Tick_Cur;
        rData_Count_Nxt = rData_Count_Cur;
        rRx_Data_Nxt    = rRx_Data_Cur;

        case (rState_Cur)
            p_Idle  :
            begin
                rB_Tick_Nxt     = 0;
                rData_Count_Nxt = 0;
                rRx_Done        = 0;
                rRx_Busy        = 0;

                if  (!iRx)
                    rState_Nxt  = p_Start;
                else
                    rState_Nxt  = rState_Cur;
            end

            p_Start :
            begin
                rRx_Busy    = 1;
                if  (iB_Tick)
                begin
                    if  (rB_Tick_Cur == 7)
                    begin
                        rState_Nxt  = p_Data;
                        rB_Tick_Nxt = 0;
                    end else
                    begin
                        rState_Nxt  = p_Start;
                        rB_Tick_Nxt = rB_Tick_Cur + 1;
                    end
                end else
                    rState_Nxt  = rState_Cur;
            end

            p_Data  :
            begin
                if  (iB_Tick)
                begin
                    if  (rB_Tick_Cur == 15)
                    begin
                        rRx_Data_Nxt    = {iRx,rRx_Data_Cur[7:1]};
                        rB_Tick_Nxt     = 0;

                        if  (rData_Count_Cur == 7)
                        begin
                            rState_Nxt      = p_Stop;
                            rData_Count_Nxt = 0;                            
                        end else
                        begin
                            rState_Nxt      = p_Data;
                            rData_Count_Nxt = rData_Count_Cur + 1;
                        end
                    end else
                    begin
                        rState_Nxt  = p_Data;
                        rB_Tick_Nxt = rB_Tick_Cur + 1;
                    end
                end else
                    rState_Nxt  = rState_Cur;
            end

            p_Stop  :
            begin
                if  (iB_Tick)
                begin
                    if  (rB_Tick_Cur == 15)
                    begin
                        rState_Nxt  = p_Idle;
                        rB_Tick_Nxt = 0;
                        rRx_Busy    = 0;
                        rRx_Done    = 1;
                    end else
                    begin
                        rState_Nxt  = p_Stop;
                        rB_Tick_Nxt = rB_Tick_Cur + 1;
                    end
                end else
                    rState_Nxt  = rState_Cur;
            end

            default :
                    rState_Nxt  = rState_Cur;
        endcase
    end

    // Output Decision
    assign  oRx_Data    =    rRx_Data_Cur;

    assign  oRx_Busy    =   (rState_Cur     == p_Idle)      ? 0 : 1;

    assign  oRx_Done    =   (rState_Cur     == p_Stop)  &&
                            (rB_Tick_Cur    == 15    )  &&
                            (iB_Tick        == 1     )      ? 1 : 0;

endmodule
