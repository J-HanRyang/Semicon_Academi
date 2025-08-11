`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/13
// Design Name      : Project_Clock
// Module Name      : Timer_DP
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Timer_DataPath
//
// Revision         : 2025/07/14    --Finish--
//////////////////////////////////////////////////////////////////////////////////

module Timer_DP(
    // Clock & Reset
    input           iClk,
    input           iRst,

    // Control_TIMER Interface
    input           iRun_Stop,
    input           iClear,
    input           iDown,

    input           iHour_Up,
    input           iHour_Down,
    input           iMin_Up,
    input           iMin_Down,
    input           iSec_Up,
    input           iSec_Down,

    // Fnd_Controller Interface
    output  [6:0]   omSec,
    output  [5:0]   oSec,
    output  [5:0]   oMin,
    output  [4:0]   oHour,

    output          oEnd
);


    /***********************************************
    // Reg & Wire
    ***********************************************/

    wire            wTick_100Hz;
    wire            wTick_mSec;
    wire            wTick_Sec;
    wire            wTick_Min;


    // Output Assgin
    assign  oEnd        =   (omSec == 0 &&
                             oSec  == 0 &&
                             oMin  == 0 &&
                             oHour == 0    )    == 1 ? 1'b1 : 1'b0;


    /***********************************************
    // Instantiation
    ***********************************************/
    
    // Tick_gen
    Tick_gen_100Hz  U_Tick_Timer_100Hz (
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
    )   U_TIMER_mSec    (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (iClear),
        .iDown      (iDown),
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
    )   U_TIMER_Sec     (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (iClear),
        .iDown      (iDown),
        .iInc       (iSec_Up),
        .iDec       (iSec_Down),
        .iTick      (wTick_mSec),
        .oTime      (oSec),
        .oTick      (wTick_Sec)
    );

    Tick_Counter    #   (
        .TICK_COUNT (60),
        .WIDTH      ($clog2(60)),
        .INIT_TIME  (0)
    )   U_TIMER_Min     (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (iClear),
        .iDown      (iDown),
        .iInc       (iMin_Up),
        .iDec       (iMin_Down),
        .iTick      (wTick_Sec),
        .oTime      (oMin),
        .oTick      (wTick_Min)
    );

    Tick_Counter    #   (
        .TICK_COUNT (24),
        .WIDTH      ($clog2(24)),
        .INIT_TIME  (0)
    )   U_TIMER_Hour    (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (iClear),
        .iDown      (iDown),
        .iInc       (iHour_Up),
        .iDec       (iHour_Down),
        .iTick      (wTick_Min),
        .oTime      (oHour),
        .oTick      ()
    );

endmodule
