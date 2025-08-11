`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/09
// Design Name      : Project_Clock
// Module Name      : Stop_Watch
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Stop_Watch
//
// Revision 	    : 2025/07/09    --Start--
//                    2025/07/11    --Finish--
//////////////////////////////////////////////////////////////////////////////////


module Stop_Watch(
    // Clock & Reset
    input           iClk,
    input           iRst,
    input           iStop_Watch,

    // Stop_Watch Interface
    input           iBtn_L,
    input           iBtn_R,

    // MUX_FND Interface 
    output  [6:0]   omSec,
    output  [5:0]   oSec,
    output  [5:0]   oMin,
    output  [4:0]   oHour
);


    /***********************************************
    // Reg & Wire
    ***********************************************/

    wire            wRun_stop;
    wire            wClear;

    /***********************************************
    // Instantiation
    ***********************************************/
    // Stop_Watch_Controller
    Stop_Watch_Ctrl U_SW_Ctrl   (
        .iClk           (iClk),
        .iRst           (iRst),
        .iStop_Watch    (iStop_Watch),
        .iBtn_L         (iBtn_L),
        .iBtn_R         (iBtn_R),
        .oRun_Stop      (wRun_stop),
        .oClear         (wClear)
    );

    // Stop_Watch_DataPath
    Stop_Watch_DP   U_SW_DP     (
        .iClk           (iClk),
        .iRst           (iRst),
        .iRun_Stop      (wRun_stop),
        .iClear         (wClear),
        .omSec          (omSec),
        .oSec           (oSec),
        .oMin           (oMin),
        .oHour          (oHour)
    );

endmodule