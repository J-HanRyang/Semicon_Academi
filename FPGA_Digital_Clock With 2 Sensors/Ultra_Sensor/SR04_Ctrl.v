`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date      : 2025/07/24
// Design Name      : Ultra_Sensor
// Module Name      : SR04_Ctrl
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : SR04 Ultrasonic Sensor Controller
//
// Revision         : 2025/07/25    Add Error State
//                                  Auto Loop
//////////////////////////////////////////////////////////////////////////////////

module SR04_Ctrl(
    input           iClk,
    input           iRst,

    input           iUltra,
    input           iStart,
    input           iTick,
    input           imSec,
    input           iEcho,

    output          oTrig,
    output  [8:0]   oDistance
    );

    // Parameter
    parameter       p_Idle      = 0,
                    p_Start     = 1,
                    p_Detect    = 2,
                    p_End       = 3,
                    p_Error     = 4;

    parameter       TICK        = $clog2(400*58),
                    DISTANCE    = $clog2(400),
                    TIMEOUT     = $clog2(100), // 새로 추가
                    AUTOSTART   = $clog2(500);
   
    // Reg & Wire
    reg     [2:0]           rState_Cur;
    reg     [2:0]           rState_Nxt;

    reg     [TICK-1:0]      rTick_Cur;
    reg     [TICK-1:0]      rTick_Nxt;

    reg     [5:0]           rmSec_Cur;
    reg     [5:0]           rmSec_Nxt;

    reg                     rEcho_Prev;
    reg     [8:0]           rDistance_Cur;
    reg     [8:0]           rDistance_Nxt;

    reg     [TIMEOUT-1:0]   rTimeout_Cur; // 새로 추가
    reg     [TIMEOUT-1:0]   rTimeout_Nxt; // 새로 추가
    reg     [AUTOSTART-1:0] rAutostart_Cur; // 새로 추가
    reg     [AUTOSTART-1:0] rAutostart_Nxt; // 새로 추가
    
    /***********************************************
    // FSM 
    ***********************************************/
    // Current State Update
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            rState_Cur      <= p_Idle;
            rTick_Cur       <= 0;
            rmSec_Cur       <= 0;
            rEcho_Prev      <= 0;
            rTimeout_Cur    <= 0; // 새로 추가
            rAutostart_Cur  <= 0; // 추가
            rDistance_Cur   <= 0;
        end else
        begin
            rState_Cur      <= rState_Nxt;
            rTick_Cur       <= rTick_Nxt;
            rmSec_Cur       <= rmSec_Nxt;
            rEcho_Prev      <= iEcho;
            rTimeout_Cur    <= rTimeout_Nxt; // 새로 추가
            rAutostart_Cur  <= rAutostart_Nxt; // 추가
            rDistance_Cur   <= rDistance_Nxt;
        end    
    end

    // Next State Decision
    always  @(*)
    begin
        rState_Nxt     = rState_Cur;
        rTick_Nxt      = rTick_Cur;
        rmSec_Nxt      = rmSec_Cur;
        rTimeout_Nxt   = rTimeout_Cur; // 새로 추가
        rAutostart_Nxt = rAutostart_Cur;
        rDistance_Nxt   = rDistance_Cur;

        case (rState_Cur)
            p_Idle      :
            begin
                if  (iUltra && iStart)
                    rState_Nxt  = p_Start;
                else if (imSec)
                begin
                    if  (rAutostart_Cur >= 50)
                    begin
                        rState_Nxt     = p_Start;
                        rAutostart_Nxt = 0;
                    end
                    else
                        rAutostart_Nxt = rAutostart_Cur + 1;
                end
                else
                    rState_Nxt  = rState_Cur;
            end

            p_Start     :
            begin
                if  (iTick)
                begin
                    if  (rTick_Cur == 10)
                    begin
                        rState_Nxt  = p_Detect;
                        rTick_Nxt   = 0;
                        rTimeout_Nxt = 0;
                    end else
                    begin
                        rTick_Nxt   = rTick_Cur + 1;
                    end
                end else
                    rState_Nxt  = rState_Cur;

                if  (imSec)
                begin
                    rTimeout_Nxt = rTimeout_Cur + 1;
                    if  (rTimeout_Cur >= 10)
                    begin
                        rState_Nxt      = p_Error;
                        rTick_Nxt       = 0;
                        rTimeout_Nxt    = 0; 
                    end
                end
            end

            p_Detect    :
            begin
                if  (iTick && iEcho)
                    rTick_Nxt   = rTick_Cur + 1;
                else if (rEcho_Prev && !iEcho)
                begin
                    rState_Nxt  = p_End;
                    rTimeout_Nxt = 0;
                end else
                    rState_Nxt  = rState_Cur;
                
                if  (imSec)
                begin
                    rTimeout_Nxt = rTimeout_Cur + 1;
                    if  (rTimeout_Cur >= 10)
                    begin
                        rState_Nxt      = p_Error;
                        rTick_Nxt       = 0;
                        rTimeout_Nxt    = 0; 
                    end
                end
            end

            p_End       :
            begin
                rDistance_Nxt   = (rTick_Cur / 58);

                if  (imSec)
                begin
                    if  (rmSec_Cur == 59)
                    begin
                        rState_Nxt  = p_Start;
                        rmSec_Nxt   = 0;
                        rTick_Nxt   = 0;
                    end else
                        rmSec_Nxt   = rmSec_Cur + 1;     
                end else
                    rState_Nxt  = rState_Cur;

            end

            p_Error:
            begin
                if (imSec)
                begin
                    if (rAutostart_Cur >= 50)
                    begin
                        rState_Nxt     = p_Start;
                        rAutostart_Nxt = 0;
                        rmSec_Nxt   = 0;
                        rTick_Nxt   = 0;
                    end
                    else
                        rAutostart_Nxt = rAutostart_Cur + 1;
                end
            end

            default     :
                    rState_Nxt  = rState_Cur;
        endcase
    end


    // Output Decision
    //wire    [DISTANCE-1:0]  wDistance   = (rTick_Cur / 58);

    assign  oTrig       =   (rState_Cur == p_Start) ? 1'b1      : 1'b0;
    //assign  oDistance   =   (rState_Cur == p_End)   ? wDistance : wDistance;
    assign  oDistance   = rDistance_Cur;
    
endmodule