`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/12/01
// Design Name      : Main_Game_Master
// Module Name      : VGA_Game_Master
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : VGA_Game_Master Top
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////

module VGA_Game_Master (
    // Clock & Reset
    input  logic       iClk,
    input  logic       iRst,
    // Button Input
    input  logic       iBtn_U,    // Game Start
    input  logic       iBtn_R,    // Game Stop
    input  logic       iBtn_L,    // Game Restart
    input  logic       iBtn_D,    // Dice Capture Trigger
    // OV7670 Interface
    input  logic       PCLK,
    input  logic       HREF,
    input  logic       VSYNC,
    input  logic [7:0] DATA,
    output logic       XCLK,
    output logic       SCL,
    inout  wire        SDA,
    // VGA Monitor Output
    output logic       oH_Sync,
    output logic       oV_Sync,
    output logic [3:0] oVGA_R,
    output logic [3:0] oVGA_G,
    output logic [3:0] oVGA_B,
    // I2C Interface
    output logic       I2C_SCL,
    inout  wire        I2C_SDA,
    //
    output logic [2:0] dice_val,
    output logic [1:0] score_p1,
    output logic [1:0] score_p2
);


    /***********************************************
    // Reg & Wire
    ***********************************************/
    // [VGA -> Logic] Dice Info
    logic       w_dice_en;
    logic [2:0] w_dice_val;
    // [VGA -> Display]
    logic       w_video_pclk;
    logic       w_de;
    logic [9:0] w_x_pixel, w_y_pixel;
    logic [3:0] w_cam_r, w_cam_g, w_cam_b;
    logic w_is_cam_region;
    // [Logic -> Display] Game Info
    logic [5:0] w_p1_pos, w_p2_pos;
    logic [3:0] w_min10, w_min1, w_sec10, w_sec1;
    logic [2:0] w_play_state;
    logic w_wait_p1, w_wait_p2;
    logic [1:0] w_score_p1, w_score_p2;
    // [Logic -> I2C Controller] I2C Info
    logic       w_i2c_show;
    logic [1:0] w_game_win;
    logic       w_game_final;
    logic [1:0] w_game_result;
    logic w_up_p1, w_down_p1;
    logic w_up_p2, w_down_p2;
    logic w_restart;


    assign dice_val = w_dice_val;



    /***********************************************
    // VGA_TOP
    ***********************************************/
    assign w_is_cam_region = w_de && (w_x_pixel < 160) && (w_y_pixel < 120);

    VGA_Top U_VGA (
        .clk       (iClk),
        .reset     (iRst),
        .d_btn     (iBtn_D),
        // Camera Pins
        .cam_pclk  (PCLK),
        .cam_href  (HREF),
        .cam_vsync (VSYNC),
        .cam_data  (DATA),
        .cam_xclk  (XCLK),
        .cam_scl   (SCL),
        .cam_sda   (SDA),
        // To Logic
        .dice_en   (w_dice_en),
        .dice_value(w_dice_val),
        // To Display (Timing & Video)
        .video_pclk(w_video_pclk),
        .h_sync    (oH_Sync),
        .v_sync    (oV_Sync),
        .DE        (w_de),
        .x_pixel   (w_x_pixel),
        .y_pixel   (w_y_pixel),
        .cam_r     (w_cam_r),
        .cam_g     (w_cam_g),
        .cam_b     (w_cam_b)
    );


    /***********************************************
    // Game_Logic_TOP
    ***********************************************/
    Game_Logic_Top U_GAME_LOGIC (
        .clk            (iClk),
        .rst            (iRst),
        // Buttons
        .u_btn          (iBtn_U),
        .r_btn          (iBtn_R),
        .l_btn          (iBtn_L),
        // From VGA
        .die_en         (w_dice_en),
        .die_value      (w_dice_val),
        // To Display
        .sec0           (w_sec1),
        .sec1           (w_sec10),
        .min0           (w_min1),
        .min1           (w_min10),
        .p1_position    (w_p1_pos),
        .p2_position    (w_p2_pos),
        .play_state     (w_play_state),
        .wait_p1        (w_wait_p1),
        .wait_p2        (w_wait_p2),
        .score_p1       (w_score_p1),
        .score_p2       (w_score_p2),
        // To I2C
        .i2c_show_signal(w_i2c_show),
        .game_win       (w_game_win),
        .game_final     (w_game_final),
        .game_result    (w_game_result),
        .up_signal_p1   (w_up_p1),
        .down_signal_p1 (w_down_p1),
        .up_signal_p2   (w_up_p2),
        .down_signal_p2 (w_down_p2),
        .restart        (w_restart)
    );


    /***********************************************
    // Display_Top
    ***********************************************/
    Display_Top U_DISPLAY (
        .iClk          (w_video_pclk),     // VGA Clock (25MHz)
        // From VGA (Timing)
        .iX_Pixel      (w_x_pixel),
        .iY_Pixel      (w_y_pixel),
        .iDE           (w_de),
        .iCam_R        (w_cam_r),
        .iCam_G        (w_cam_g),
        .iCam_B        (w_cam_b),
        .iIs_Cam_Region(w_is_cam_region),
        // From Logic (Data)
        .iP1_Pos       (w_p1_pos),
        .iP2_Pos       (w_p2_pos),
        .iMin10        (w_min10),
        .iMin1         (w_min1),
        .iSec10        (w_sec10),
        .iSec1         (w_sec1),
        .iGame_State   (w_play_state),
        .iWait_P1      (w_wait_p1),
        .iWait_P2      (w_wait_p2),
        .score_p1      (w_score_p1),
        .score_p2      (w_score_p2),
        // To Monitor
        .oFinal_R      (oVGA_R),
        .oFinal_G      (oVGA_G),
        .oFinal_B      (oVGA_B)
    );

    assign score_p1 = w_score_p1;
    assign score_p2 = w_score_p2;


    /***********************************************
    // I2C
    ***********************************************/
    I2C_Game_Ctrl U_I2C_CTRL (
        .clk            (iClk),
        .rst            (iRst),
        .i2c_show_signal(w_i2c_show),
        .game_win       (w_game_win),
        .game_final     (w_game_final),
        .game_result    (w_game_result),
        .restart        (w_restart),
        .up_signal_p1   (w_up_p1),
        .down_signal_p1 (w_down_p1),
        .up_signal_p2   (w_up_p2),
        .down_signal_p2 (w_down_p2),
        // I2C
        .SCL            (I2C_SCL),
        .SDA            (I2C_SDA)
    );

endmodule
