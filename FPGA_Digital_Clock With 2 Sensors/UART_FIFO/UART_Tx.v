`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/15
// Design Name      : Project_UART_FIFO
// Module Name      : UART_Tx
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : UART_Tx Mode FSM Controller
//
// Revision         : 2025/07/16    Add Tick_Counter
//                    2028/07/17    Add Shift_Reg 
//////////////////////////////////////////////////////////////////////////////////

module UART_Tx(
    input           iClk,
    input           iRst,

    input           iB_Tick,
    input           iTx_Start,
    input   [7:0]   iTx_Data,

    output          oTx,
    output          oTx_Busy,
    output          oTx_Done
);

    // State Parameter
    parameter       p_Idle  = 0,
                    p_Wait  = 1,
                    p_Start = 2,
                    p_Data  = 3,
                    p_Stop  = 4;

    // Reg & Wire
    reg     [2:0]   rState_Cur;
    reg     [2:0]   rState_Nxt;

    reg             rTx_Cur;
    reg             rTx_Nxt;

    reg     [3:0]   rB_Tick_Cur;
    reg     [3:0]   rB_Tick_Nxt;

    reg     [2:0]   rData_Count_Cur;
    reg     [2:0]   rData_Count_Nxt;

    reg     [7:0]   rTx_Data_Cur;
    reg     [7:0]   rTx_Data_Nxt;

    /***********************************************
    // FSM 
    ***********************************************/
    // Current State Update
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            rState_Cur      <= p_Idle;
            rTx_Cur         <= 1;
            rData_Count_Cur <= 0;
            rB_Tick_Cur     <= 0;
            rTx_Data_Cur    <= 0;
        end else
        begin
            rState_Cur      <= rState_Nxt;
            rTx_Cur         <= rTx_Nxt;
            rData_Count_Cur <= rData_Count_Nxt;
            rB_Tick_Cur     <= rB_Tick_Nxt;
            rTx_Data_Cur    <= rTx_Data_Nxt;
        end
    end

    // Next State Decision
    always  @(*)
    begin
        rState_Nxt      = rState_Cur;
        rTx_Nxt         = rTx_Cur;
        rData_Count_Nxt = rData_Count_Cur;
        rB_Tick_Nxt     = rB_Tick_Cur;
        rTx_Data_Nxt    = rTx_Data_Cur;

        case (rState_Cur)
            p_Idle  :
            begin
                rTx_Nxt     = 1;
                rB_Tick_Nxt = 0;

                if  (iTx_Start)
                begin
                    rState_Nxt  = p_Wait;
                    rTx_Data_Nxt   = iTx_Data;
                end else
                    rState_Nxt  = rState_Cur;
            end

            p_Wait  :
            begin
                if  (iB_Tick)
                    rState_Nxt  = p_Start;
                else
                    rState_Nxt  = rState_Cur;
            end

            p_Start :
            begin
                rTx_Nxt = 0;

                if  (iB_Tick)
                begin
                    if  (rB_Tick_Cur == 15)
                    begin
                        rState_Nxt  = p_Data;
                        rB_Tick_Nxt = 0;
                    end else
                        rB_Tick_Nxt = rB_Tick_Cur + 1;
                end else
                    rState_Nxt  = rState_Cur;
            end

            p_Data  :
            begin
                rTx_Nxt = rTx_Data_Cur[0];

                if  (iB_Tick)
                begin
                    if  (rB_Tick_Cur == 15)
                    begin
                        rTx_Data_Nxt    = rTx_Data_Cur >> 1;
                        rB_Tick_Nxt     = 0;

                        if  (rData_Count_Cur == 3'b111)
                        begin
                            rData_Count_Nxt = 0;
                            rState_Nxt      = p_Stop;
                        end else
                        begin
                            rState_Nxt      = p_Data;
                            rData_Count_Nxt = rData_Count_Cur + 1;
                        end
                    end else
                        rB_Tick_Nxt = rB_Tick_Cur + 1;
                end else
                    rState_Nxt  = rState_Cur;
            end

            p_Stop  :
            begin
                rTx_Nxt = 1;

                if  (iB_Tick)
                begin
                    if  (rB_Tick_Cur == 15)
                    begin
                        rState_Nxt  = p_Idle;
                        rB_Tick_Nxt = 0;
                    end else
                        rB_Tick_Nxt = rB_Tick_Cur + 1;
                end else
                    rState_Nxt  = rState_Cur;
            end
             
            default :
                    rState_Nxt  = rState_Cur; 
        endcase
    end

    // Output Decision
        assign  oTx         =    rTx_Cur;

        assign  oTx_Busy    =   (rState_Cur == p_Idle)          ? 0 : 1;

        assign  oTx_Done    =   (rState_Cur     == p_Stop)  &&
                                (rB_Tick_Cur    == 15    )  &&
                                (iB_Tick        == 1     )      ? 1 : 0;  

endmodule
