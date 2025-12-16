`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/11/30
// Design Name      : Game_Player_Slave
// Module Name      : Game_Player_Slave (Top)
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Game_Player Slave Module (I2C Slave -> VGA(Filter))
//                  : Using Seoyu's Slave & OV7670
//
// Revision 	    : 2025/11/30    Ver_1.0
//////////////////////////////////////////////////////////////////////////////////

module Game_Player_Slave #(
    parameter [6:0] I2C_SLAVE_ADDR = 7'b1010_101
) (
    // Clock & Reset
    input  logic       clk,
    input  logic       reset,
    /******************************
    // Slave Interface
    ******************************/
    // Master Interface
    input  logic       SCL,
    inout  wire        SDA,
    /******************************
    // OV7670 Interface
    ******************************/
    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] data,
    // OV7670 I2C
    output logic       SCCB_SCL,
    inout  wire        SCCB_SDA,
    // VGA_Port
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port,
    // Debug_SW/LED
    input        [5:0] iSW,
    output logic       SCCB_Init_done
);

    /***********************************************
    // Reg & Wire
    ***********************************************/
    // V Clock
    logic       wV_Sync;
    // VGA(Filter) Interface
    logic [7:0] current_status;  // Reg0
    logic [7:0] game_result;  // Reg1
    logic [7:0] change_status;  // Reg2


    /***********************************************
    // Instantiation
    ***********************************************/
    i2c_slave_interface #(
        .I2C_ADDR(I2C_SLAVE_ADDR)
    ) U_PLAYER_SLAVE (
        .*,
        .iV_Sync           (wV_Sync),
        .current_status_out(current_status),  // Reg0
        .game_result_out   (game_result),     // Reg1
        .change_status_out (change_status)    // Reg2
    );

    OV7670_CCTV U_OV7670_CCTV (
        .*,
        .v_sync           (wV_Sync),
        .current_status_in({current_status[7:2], iSW[1:0]}),  // Reg0
        .game_result_in   ({game_result[7:2], iSW[3:2]}),     // Reg1
        .change_status_in ({change_status[7:2], iSW[5:4]})    // Reg2
    );

endmodule
