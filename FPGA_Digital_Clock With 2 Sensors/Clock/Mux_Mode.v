`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date      : 2025/07/11
// Design Name      : Project_Clock
// Module Name      : Mux_Mode
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Clock + Stop_Watch Mode Select
//
// Revision         : 2025/07/14    Add Timer
//                    2025/07/21    Add Mode_Set
//////////////////////////////////////////////////////////////////////////////////

module Mux_Mode(
    input   [3:0]   iMode,

    input   [1:0]   iCLK_Set,
    input   [1:0]   iTIMER_Set,

    input   [23:0]  iCLK_Data,
    input   [23:0]  iSW_Data,
    input   [23:0]  iTIMER_Data,
    input   [8:0]   iUltra_Data,
    input   [31:0]  iDHT_Data,

    output  [1:0]   oMode_Set,
    output  [31:0]  oMode_Data
    );

    // Reg & Wire
    reg     [1:0]   rMode_Set;
    reg     [31:0]  rMode_Data;

    // Mux
    always @(*)
    begin
        case (iMode)
            4'b0000 : rMode_Data = {8'b0, iCLK_Data};
            4'b0001 : rMode_Data = {8'b0, iSW_Data};
            4'b0010 : rMode_Data = {8'b0, iTIMER_Data};
            4'b0100 : rMode_Data = {23'b0, iUltra_Data};
            4'b1000 : rMode_Data = iDHT_Data;
            default : rMode_Data = {8'b0, iCLK_Data};
        endcase
    end

    always @(*)
    begin
        case (iMode[1:0])
            2'b00   : rMode_Set = iCLK_Set;
            2'b10   : rMode_Set = iTIMER_Set;
            default : rMode_Set = iCLK_Set;
        endcase
    end

    // Output Connect
    assign  oMode_Set   = rMode_Set; 
    assign  oMode_Data  = rMode_Data;

endmodule