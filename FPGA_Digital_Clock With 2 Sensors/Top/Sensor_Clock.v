`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/24
// Design Name      : Project_Sensor
// Module Name      : Sensor_Clock
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Sensor+Clock
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////

module Sensor_Clock(
    // Clock & Reset
    input           iClk,
    input           iRst,

    // FPGA_SW
    input           iSet,
    input   [4:0]   iMode,

    // FPGA_Button
    input           iBtn_U,
    input           iBtn_D,
    input           iBtn_L,
    input           iBtn_R,

    // FND OUT
    output  [3:0]   oFnd_Com,
    output  [7:0]   oFnd_Data,
    output  [3:0]   oLed_Alarm,
    output  [9:0]   oLed,

    output  [3:0]   oDigit_Hour_10,
    output  [3:0]   oDigit_Hour_1,
    output  [3:0]   oDigit_Min_10,
    output  [3:0]   oDigit_Min_1,
    output  [3:0]   oDigit_Sec_10,
    output  [3:0]   oDigit_Sec_1,
    
    // Ultra Sensor
    input           iEcho,
    output          oTrig,

    // DTH Sensor
    inout           ioDHT
    );


    /***********************************************
    // Reg & Wire
    ***********************************************/
    // Mode Controller
    wire            wClock;
    wire            wStop_Watch;
    wire            wTimer;
    wire            wUltra;
    wire            wDHT;

    // Clock Wire
    wire    [1:0]   wCLK_Set;
    wire    [6:0]   wmSec_CLK;
    wire    [5:0]   wSec_CLK;
    wire    [5:0]   wMin_CLK;
    wire    [4:0]   wHour_CLK;
    wire            wmSec_Tick;
    wire            wSec_Tick;

    // Stop Watch Wire
    wire    [6:0]   wmSec_SW;
    wire    [5:0]   wSec_SW;
    wire    [5:0]   wMin_SW;
    wire    [4:0]   wHour_SW;

    // Timer Wire
    wire    [1:0]   wTIMER_Set;
    wire    [6:0]   wmSec_TIMER;
    wire    [5:0]   wSec_TIMER;
    wire    [5:0]   wMin_TIMER;
    wire    [4:0]   wHour_TIMER;

    // DHT Wire
    wire    [7:0]   wHumid_int;
    wire    [7:0]   wHumid_Dec;
    wire    [7:0]   wTemp_int;
    wire    [7:0]   wTemp_Dec;

    // Data_Mux
    wire    [23:0]  wCLK_Data   = {wHour_CLK, wMin_CLK, wSec_CLK, wmSec_CLK};
    wire    [23:0]  wSW_Data    = {wHour_SW, wMin_SW, wSec_SW, wmSec_SW};
    wire    [23:0]  wTIMER_Data = {wHour_TIMER, wMin_TIMER, wSec_TIMER, wmSec_TIMER};
    wire    [8:0]   wUltra_Data;
    wire    [31:0]  wDHT_Data   = {wHumid_int, wHumid_Dec, wTemp_int, wTemp_Dec};
    wire    [1:0]   wMode_Set;
    wire    [31:0]  wMode_Data;

    /***********************************************
    // Instantiation
    ***********************************************/
    // Mode Controller
    Top_Ctrl        U_Ctrl      (
        .iMode          (iMode[4:1]),
        .oClock         (wClock),
        .oStop_Watch    (wStop_Watch),
        .oTimer         (wTimer),
        .oUltra         (wUltra),
        .oDHT           (wDHT)
    );

    // Clock
    Clock           U_CLK       (
        .iClk           (iClk),
        .iRst           (iRst),
        .iClock         (wClock),
        .iSet           (iSet),
        .iBtn_U         (iBtn_U),
        .iBtn_D         (iBtn_D),
        .iBtn_L         (iBtn_L),
        .iBtn_R         (iBtn_R),
        .oSet           (wCLK_Set),
        .omSec          (wmSec_CLK),
        .oSec           (wSec_CLK),
        .oMin           (wMin_CLK),
        .oHour          (wHour_CLK),
        .omSec_Tick     (wmSec_Tick),
        .oSec_Tick      (wSec_Tick)
    );

    // Stop_Watch
    Stop_Watch      U_SW        (
        .iClk           (iClk),
        .iRst           (iRst),
        .iStop_Watch    (wStop_Watch),
        .iBtn_L         (iBtn_L),
        .iBtn_R         (iBtn_R),
        .omSec          (wmSec_SW),
        .oSec           (wSec_SW),
        .oMin           (wMin_SW),
        .oHour          (wHour_SW)
    );

    // Timer
    Timer           U_TIMER     (
        .iClk           (iClk),
        .iRst           (iRst),
        .iTimer         (wTimer),
        .iSet           (iSet),
        .iBtn_U         (iBtn_U),
        .iBtn_D         (iBtn_D),
        .iBtn_L         (iBtn_L),
        .iBtn_R         (iBtn_R),
        .oSet           (wTIMER_Set),
        .omSec          (wmSec_TIMER),
        .oSec           (wSec_TIMER),
        .oMin           (wMin_TIMER),
        .oHour          (wHour_TIMER),
        .oEnd           (wEnd)
    );

    // Ultra_Sensor
    Ultra_Sensor    U_Ultra_Sensor  (
        .iClk           (iClk),
        .iRst           (iRst),
        .iUltra         (wUltra),
        .iStart         (iBtn_R),
        .imSec          (wmSec_Tick),
        .iEcho          (iEcho),
        .oTrig          (oTrig),
        .oDistance      (wUltra_Data)
    );

    // DHT_Sensor
    DHT_Sensor      U_DHT_Sensor    (
        .iClk           (iClk),
        .iRst           (iRst),
        .iDHT           (wDHT),
        .iStart         (iBtn_R),
        .ioDHT          (ioDHT),
        .oHumid_int     (wHumid_int),
        .oHumid_Dec     (wHumid_Dec),
        .oTemp_int      (wTemp_int),
        .oTemp_Dec      (wTemp_Dec)
    );

    // Mode_Mux
    Mux_Mode        U_Mode      (
        .iMode          (iMode[4:1]),
        .iCLK_Set       (wCLK_Set),
        .iTIMER_Set     (wTIMER_Set),
        .iCLK_Data      (wCLK_Data),
        .iSW_Data       (wSW_Data),
        .iTIMER_Data    (wTIMER_Data),
        .iUltra_Data    (wUltra_Data),
        .iDHT_Data      (wDHT_Data),
        .oMode_Set      (wMode_Set),
        .oMode_Data     (wMode_Data)
    );
    
    // Fnd_Controller
    Fnd_Controller  U_FND       (
        .iClk           (iClk),
        .iRst           (iRst),
        .iSet           (wMode_Set),
        .iMode          (iMode),
        .iEnd           (wEnd),
        .iData          (wMode_Data),
        .oFnd_Data      (oFnd_Data),
        .oFnd_Com       (oFnd_Com),
        .oLed_Alarm     (oLed_Alarm),
        .oLed           (oLed),
        .oDigit_Hour_10 (oDigit_Hour_10),
        .oDigit_Hour_1  (oDigit_Hour_1),
        .oDigit_Min_10  (oDigit_Min_10),
        .oDigit_Min_1   (oDigit_Min_1),
        .oDigit_Sec_10  (oDigit_Sec_10),
        .oDigit_Sec_1   (oDigit_Sec_1)
    );

endmodule
