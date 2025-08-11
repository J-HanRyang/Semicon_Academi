`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/11
// Design Name      : Project_Clock
// Module Name      : Clock_DP
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Clock_DataPath
//
// Revision 	    : 2025/07/11    --Start--
//                  : 2025/07/12    Delete Sec, mSec
//                                  Add Hour Initial Val
//                                  --Finish--
//////////////////////////////////////////////////////////////////////////////////


module Clock_DP(
    // Clock & Reset
    input           iClk,
    input           iRst,

    // Control_Clock_Interface
    input           iSet,

    input           iHour_Up,
    input           iHour_Down,
    input           iMin_Up,
    input           iMin_Down,

    output  [6:0]   omSec,
    output  [5:0]   oSec,
    output  [5:0]   oMin,
    output  [4:0]   oHour,

    output          omSec_Tick,
    output          oSec_Tick
    );


    /***********************************************
    // Reg & Wire
    ***********************************************/

    wire            wTick_100Hz;
    wire            wTick_mSec;
    wire            wTick_Sec;
    wire            wTick_Min;


    // Assign
    assign  omSec_Tick  = wTick_100Hz;
    assign  oSec_Tick   = wTick_mSec;


    /***********************************************
    // Instantiation
    ***********************************************/
    
    // Tick_gen
    Tick_gen_100Hz  U_Tick_100Hz    (
        .iClk       (iClk),
        .iRst       (iRst),
        .iRun_Stop  (!iSet),
        .iClear     (1'b0),
        .oTick      (wTick_100Hz)
    );

    // Counter
    Tick_Counter    #   (
        .TICK_COUNT (100),
        .WIDTH      ($clog2(100)),
        .INIT_TIME  (0)
    )   U_CLK_mSec  (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (1'b0),
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
    )   U_CLK_Sec   (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (1'b0),
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
    )   U_CLK_Min   (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (1'b0),
        .iDown      (1'b0),
        .iInc       (iMin_Up),
        .iDec       (iMin_Down),
        .iTick      (wTick_Sec),
        .oTime      (oMin),
        .oTick      (wTick_Min)
    );

    Tick_Counter    #   (
        .TICK_COUNT (24),
        .WIDTH      ($clog2(24)),
        .INIT_TIME  (12)
    )   U_CLK_Hour  (
        .iClk       (iClk),
        .iRst       (iRst),
        .iClear     (1'b0),
        .iDown      (1'b0),
        .iInc       (iHour_Up),
        .iDec       (iHour_Down),
        .iTick      (wTick_Min),
        .oTime      (oHour),
        .oTick      ()
    );

endmodule
