`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/11
// Design Name      : Project_Clock
// Module Name      : Clock
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Clock
//
// Revision         : 2025/07/11    --Start--
// Revision         : 2025/07/12    
//////////////////////////////////////////////////////////////////////////////////

module Clock(
    // Clock & Reset
    input           iClk,
    input           iRst,
    input           iClock,

    // Clock Interface
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

    output          omSec_Tick,
    output          oSec_Tick
    );


    /***********************************************
    // Reg & Wire
    ***********************************************/

    wire            wHour_Up;
    wire            wHour_Down;
    wire            wMin_Up;
    wire            wMin_Down;

    wire            wSet_Hour;
    wire            wSet_Min;

    wire            wSet;

    // Output
    assign  oSet =  (wSet_Hour) ? 2'b10 :
                    (wSet_Min ) ? 2'b01 : 2'b00;

    assign  wSet    = (iClock && iSet);
    /***********************************************
    // Instantiation
    ***********************************************/
    // Clock_Controller
    Clock_Ctrl      U_CLK_Ctrl  (
        .iClk           (iClk),
        .iRst           (iRst),
        .iClock         (iClock),
        .iSet           (wSet),
        .iBtn_U         (iBtn_U),
        .iBtn_D         (iBtn_D),
        .iBtn_L         (iBtn_L),
        .iBtn_R         (iBtn_R),
        .oHour_Up       (wHour_Up),
        .oHour_Down     (wHour_Down),
        .oMin_Up        (wMin_Up),
        .oMin_Down      (wMin_Down),
        .oSet_Hour      (wSet_Hour),
        .oSet_Min       (wSet_Min)
    );

    // Clock_DataPath
    Clock_DP        U_CLK_DP    (
        .iClk           (iClk),
        .iRst           (iRst),
        .iSet           (wSet),
        .iHour_Up       (wHour_Up),
        .iHour_Down     (wHour_Down),
        .iMin_Up        (wMin_Up),
        .iMin_Down      (wMin_Down),
        .omSec          (omSec),
        .oSec           (oSec),
        .oMin           (oMin),
        .oHour          (oHour),
        .omSec_Tick     (omSec_Tick),
        .oSec_Tick      (oSec_Tick)
    );

endmodule