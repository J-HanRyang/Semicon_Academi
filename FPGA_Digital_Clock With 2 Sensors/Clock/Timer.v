`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/13
// Design Name      : Project_Clock
// Module Name      : Timer
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Timer
//
// Revision         : 2025/07/14    --Finish--
//////////////////////////////////////////////////////////////////////////////////

module Timer(
    // Clock & Reset
    input           iClk,
    input           iRst,
    input           iTimer,

    // Timer Interface
    input           iSet,

    input           iBtn_U,
    input           iBtn_D,
    input           iBtn_L,
    input           iBtn_R,

    // MUX_FND Interface
    output  [1:0]   oSet,

    output  [6:0]   omSec,
    output  [5:0]   oSec,
    output  [5:0]   oMin,
    output  [4:0]   oHour,

    output          oEnd
    );


    /***********************************************
    // Reg & Wire
    ***********************************************/
    wire            wSet;
    wire            wRun_Stop;
    wire            wClear;
    wire            wDown;

    wire            wHour_Up;
    wire            wHour_Down;
    wire            wMin_Up;
    wire            wMin_Down;
    wire            wSec_Up;
    wire            wSec_Down;


    wire            wSet_Hour;
    wire            wSet_Min;
    wire            wSet_Sec;

    wire            wEnd;

    // Output
    assign  oSet    =   (wSet_Hour) ? 2'b10 :
                        (wSet_Min ) ? 2'b01 :
                        (wSet_Sec ) ? 2'b11 : 2'b00;  
    
    assign  wSet    =   (iTimer && iSet);


    /***********************************************
    // Instantiation
    ***********************************************/
    // Timer_Controller
    Timer_Ctrl      U_Timer_Ctrl    (
        .iClk           (iClk),
        .iRst           (iRst),
        .iTimer         (iTimer),
        .iSet           (wSet),
        .iEnd           (wEnd),
        .iBtn_U         (iBtn_U),
        .iBtn_D         (iBtn_D),
        .iBtn_L         (iBtn_L),
        .iBtn_R         (iBtn_R),
        .oRun_Stop      (wRun_Stop),
        .oClear         (wClear),
        .oDown          (wDown),
        .oHour_Up       (wHour_Up),
        .oHour_Down     (wHour_Down),
        .oMin_Up        (wMin_Up),
        .oMin_Down      (wMin_Down),
        .oSec_Up        (wSec_Up),
        .oSec_Down      (wSec_Down),
        .oSet_Hour      (wSet_Hour),
        .oSet_Min       (wSet_Min),
        .oSet_Sec       (wSet_Sec),
        .oEnd           (oEnd)
    );

    // Timer_DataPath
    Timer_DP        U_Timer_DP      (
        .iClk           (iClk),
        .iRst           (iRst),
        .iRun_Stop      (wRun_Stop),
        .iClear         (wClear),
        .iDown          (wDown),
        .iHour_Up       (wHour_Up),
        .iHour_Down     (wHour_Down),
        .iMin_Up        (wMin_Up),
        .iMin_Down      (wMin_Down),
        .iSec_Up        (wSec_Up),
        .iSec_Down      (wSec_Down),
        .omSec          (omSec),
        .oSec           (oSec),
        .oMin           (oMin),
        .oHour          (oHour),
        .oEnd           (wEnd)
    );

endmodule