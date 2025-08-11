`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/25
// Design Name      : DHT_Sensor
// Module Name      : Tick_10uS
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Make 10us Pulse
//////////////////////////////////////////////////////////////////////////////////

module Tick_10uS(
    input                   iClk,
    input                   iRst,

    input                   iRun_Stop,
    input                   iClear,

    output                  oTick
);

    // Parameter
    parameter               COUNT   = 1_000,
                            WIDTH   = $clog2(COUNT);
    
    // Reg & Wire
    reg     [WIDTH-1: 0]    rCounter;
    reg                     rTick;

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
                if  (rCounter == (COUNT-1))
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