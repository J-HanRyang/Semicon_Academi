`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/12
// Design Name      : Project_Sensor
// Module Name      : Top_Ctrl
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Digital_Clock Mode Select
//
// Revision 	    : 2025/07/12    --Start--
//                    2025/07/13    Add Timer
//                    2025/07/21    Simple
//                    2025/07/24    Add Sensor_2
//////////////////////////////////////////////////////////////////////////////////


module Top_Ctrl(
    input       [3:0]   iMode,
    
    output              oClock,
    output              oStop_Watch,
    output              oTimer,
    output              oUltra,
    output              oDHT
    );

    assign oClock       = (iMode == 4'b0000) ? 1'b1 : 1'b0;
    assign oStop_Watch  = (iMode == 4'b0001) ? 1'b1 : 1'b0;
    assign oTimer       = (iMode == 4'b0010) ? 1'b1 : 1'b0;
    assign oUltra       = (iMode == 4'b0100) ? 1'b1 : 1'b0;
    assign oDHT         = (iMode == 4'b1000) ? 1'b1 : 1'b0;

endmodule