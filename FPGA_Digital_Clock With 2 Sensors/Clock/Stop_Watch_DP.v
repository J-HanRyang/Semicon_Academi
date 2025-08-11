`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/09
// Design Name      : Project_Clock
// Module Name      : Stop_Watch_DP
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Stop_Watch_DataPath
//
// Revision 	    : 2025/07/09    --Start--
// Revision         : 2025/07/11    --Finish--
//////////////////////////////////////////////////////////////////////////////////

module Stop_Watch_DP(
    // Clock & Reset
    input           iClk,
    input           iRst,

    // Control_SW Interface

    input           iRun_Stop,
    input           iClear,

    // Fnd_Controller Interface
    output  [6:0]   omSec,
    output  [5:0]   oSec,
    output  [5:0]   oMin,
    output  [4:0]   oHour
);


    /***********************************************
    // Reg & Wire
    ***********************************************/

    wire            wTick_100Hz;
    wire            wTick_mSec;
    wire            wTick_Sec;
    wire            wTick_Min;


    /***********************************************
    // Instantiation
    ***********************************************/
    
    // Tick_gen
    Tick_gen_100Hz  U_Tick_SW_100Hz (
        .iClk       (iClk),
        .iRst       (iRst),
        .iRun_Stop  (iRun_Stop),
        .iClear     (iClear),
        .oTick      (wTick_100Hz)
    );

    // Counter
    Tick_Counter    #   (
        .TICK_COUNT (100),
        .WIDTH      ($clog2(100)),
        .INIT_TIME  (0)
    )   U_SW_mSec   (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (iClear),
        .iDown      (1'b0),
        .iInc       (),
        .iDec       (),
        .iTick      (wTick_100Hz),
        .oTime      (omSec),
        .oTick      (wTick_mSec)
    );

    Tick_Counter    #   (
        .TICK_COUNT (60),
        .WIDTH      ($clog2(60)),
        .INIT_TIME  (0)
    )   U_SW_Sec    (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (iClear),
        .iDown      (1'b0),
        .iInc       (),
        .iDec       (),
        .iTick      (wTick_mSec),
        .oTime      (oSec),
        .oTick      (wTick_Sec)
    );

    Tick_Counter    #   (
        .TICK_COUNT (60),
        .WIDTH      ($clog2(60)),
        .INIT_TIME  (0)
    )   U_SW_Min    (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (iClear),
        .iDown      (1'b0),
        .iInc       (),
        .iDec       (),
        .iTick      (wTick_Sec),
        .oTime      (oMin),
        .oTick      (wTick_Min)
    );

    Tick_Counter    #   (
        .TICK_COUNT (24),
        .WIDTH      ($clog2(24)),
        .INIT_TIME  (0)
    )   U_SW_Hour   (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (iClear),
        .iDown      (1'b0),
        .iInc       (),
        .iDec       (),
        .iTick      (wTick_Min),
        .oTime      (oHour),
        .oTick      ()
    );

endmodule

    
/***********************************************
// Sub_Module
***********************************************/

// Tick_gen
 module Tick_gen_100Hz   (
    input       iClk,
    input       iRst,

    input       iRun_Stop,
    input       iClear,

    output      oTick
);

    // Parameter
    parameter   COUNT = (1_000_000 - 1);
    
    // Reg & Wire
    reg     [$clog2(COUNT) : 0]   rCounter;
    reg                           rTick;

    //
    always @(posedge iClk, posedge iRst)
    begin
        if (iRst)
        begin
            rCounter    <= 0;
            rTick       <= 0;
        end else
        begin
            if      (iRun_Stop)
            begin
                if  (rCounter == COUNT)
                begin
                    rCounter    <= 0;
                    rTick       <= 1;
                end else
                begin
                    rCounter    <= rCounter + 1;
                    rTick       <= 0;
                end
            end
            else if (iClear)
                rCounter    <= 0;
            else
                rTick   <= 0;

        end
    end

    assign  oTick   = rTick;

endmodule


// Tick_Counter
module Tick_Counter     #(
    parameter           TICK_COUNT  = 100,
                        WIDTH       = $clog2(TICK_COUNT),
                        INIT_TIME   = 0
)   (
    input               iClk,
    input               iRst,

    input               iClear,
    input               iDown,
    input               iInc,
    input               iDec,
    input               iTick,

    output  [WIDTH-1:0] oTime,
    output              oTick
);

    // Reg & Wire
    reg     [WIDTH-1:0] rCounter_Cur;
    reg     [WIDTH-1:0] rCounter_Nxt;

    reg                 rTick_Cur;
    reg                 rTick_Nxt;

    // Reset & Initial
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            rCounter_Cur    <= INIT_TIME;
            rTick_Cur       <= 0;
        end else
        begin
            rCounter_Cur    <= rCounter_Nxt;
            rTick_Cur       <= rTick_Nxt;
        end
    end

    // Counter Comb.
    always  @(*)
    begin
        rCounter_Nxt    =   rCounter_Cur;
        rTick_Nxt       =   rTick_Cur;

        if  (iTick)
        begin
            if      (iDown)
            begin
                if  (rCounter_Cur == 0)
                begin
                    rCounter_Nxt    = TICK_COUNT - 1;
                    rTick_Nxt       = 1;
                end
                else
                begin
                    rCounter_Nxt    = rCounter_Cur - 1;
                    rTick_Nxt       = 0;
                end
            end
            else if (!iDown)
            begin
                if  (rCounter_Cur == (TICK_COUNT-1))
                begin
                    rCounter_Nxt    = 0;
                    rTick_Nxt       = 1;
                end else
                begin
                    rCounter_Nxt    = rCounter_Cur + 1;
                    rTick_Nxt       = 0;
                end
            end
        end
        else
            rTick_Nxt   = 0;  

        if      (iClear)
            rCounter_Nxt = 0; 
        else if (iInc)
        begin
            if  (rCounter_Cur == (TICK_COUNT-1))
                rCounter_Nxt = 0;
            else
                rCounter_Nxt = rCounter_Cur + 1;
        end
        else if (iDec)
        begin
            if  (rCounter_Cur == 0)
                rCounter_Nxt = (TICK_COUNT-1);
            else
                rCounter_Nxt = rCounter_Cur - 1;
        end
    end

    assign  oTime   = rCounter_Cur;
    assign  oTick   = rTick_Cur;

endmodule