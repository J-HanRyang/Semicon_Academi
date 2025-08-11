`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/25
// Design Name      : DHT_Sensor
// Module Name      : DHT_Ctrl
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : BHT Sensor FSM Controller
//////////////////////////////////////////////////////////////////////////////////

module DHT_Sensor(
    // Clock & Reset
    input           iClk,
    input           iRst,

    input           iDHT,
    input           iStart,
    inout           ioDHT,

    output  [7:0]   oHumid_int,
    output  [7:0]   oHumid_Dec,
    output  [7:0]   oTemp_int,
    output  [7:0]   oTemp_Dec
);


    /***********************************************
    // Reg & Wire
    ***********************************************/
    wire            wTick;

    /***********************************************
    // Instantiation
    ***********************************************/
    Tick_10uS   U_Tick_10uS (
        .iClk       (iClk),
        .iRst       (iRst),
        .iRun_Stop  (1'b1),
        .iClear     (1'b0),
        .oTick      (wTick)
    );

    DHT_Ctrl    U_DHT_Ctrl  (
        .iClk       (iClk),
        .iRst       (iRst),
        .iDHT       (iDHT),
        .iStart     (iStart),
        .ioDHT      (ioDHT),
        .iTick_10us (wTick),
        .oHumid_int (oHumid_int),
        .oHumid_Dec (oHumid_Dec),
        .oTemp_int  (oTemp_int),
        .oTemp_Dec  (oTemp_Dec),
        .oDone      ()
    );
endmodule