`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han, Hyungang Heo, Hyuncheol Cho
// 
// Create Date	    : 2025/07/24
// Design Name      : Ultra_Sensor
// Module Name      : Ultra_Sensor
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : SR04 Ultrasonic Sensor
//////////////////////////////////////////////////////////////////////////////////

module Ultra_Sensor(
    input           iClk,
    input           iRst,

    input           iUltra,
    input           iStart,
    input           imSec,
    input           iEcho,

    output          oTrig,
    output  [8:0]   oDistance
    );

    /***********************************************
    // Reg & Wire
    ***********************************************/
    wire            wTick;


    /***********************************************
    // Instantiation
    ***********************************************/
    Tick_1MHz       U_Tick_1MHz     (
        .iClk       (iClk),
        .iRst       (iRst),
        .iRun_Stop  (1'b1),
        .iClear     (1'b0),
        .oTick      (wTick)
    );

    SR04_Ctrl       U_SR04_Ctrl     (
        .iClk       (iClk),
        .iRst       (iRst),
        .iUltra     (iUltra),
        .iStart     (iStart),
        .iTick      (wTick),
        .imSec      (imSec),
        .iEcho      (iEcho),
        .oTrig      (oTrig),
        .oDistance  (oDistance)
    );
    
endmodule
