`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/11/30
// Design Name      : Main_Game_Master
// Module Name      : VGA_TOP
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Game_Master Top Module
//
// Revision 	    : 2025/12/01    ADD Game Piece Module
//                  :               Revision Top Instance
//                  :               Only Detect Dice
//////////////////////////////////////////////////////////////////////////////////
module VGA_Top (
    // System Input
    input  logic       clk,
    input  logic       reset,
    input  logic       d_btn,
    // OV7670 Sensor
    input  logic       cam_pclk,
    input  logic       cam_href,
    input  logic       cam_vsync,
    input  logic [7:0] cam_data,
    output logic       cam_xclk,
    output logic       cam_scl,
    inout  wire        cam_sda,
    // [Output 1] Game Logic Interface
    output logic       dice_en,
    output logic [2:0] dice_value,  //  1~6
    // [Output 2] Display Interface
    output logic       video_pclk,  // 25MHz pixel clock
    output logic       h_sync,
    output logic       v_sync,
    output logic       DE,          // Active Video Area
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic [3:0] cam_r,
    output logic [3:0] cam_g,
    output logic [3:0] cam_b
);

    assign cam_xclk = video_pclk;  // Direct Connect?

    /***********************************************
    // OV7670 Camera
    ***********************************************/
    logic sccb_init_done;

    OV7670_Init_SCCB_inf U_OV7670_INIT (
        .clk      (clk),
        .reset    (reset),
        .CAM_SCL  (cam_scl),
        .CAM_SDA  (cam_sda),
        .init_done(sccb_init_done)
    );


    /***********************************************
    // VGA Timing Generation
    ***********************************************/
    video_timing U_VIDEO_TIMING (
        .clk    (clk),         // 100MHz
        .reset  (reset),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .pclk   (video_pclk),  // 25MHz
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );


    /***********************************************
    // Camera Data Capture
    ***********************************************/
    logic [14:0] wAddr;  // [16:0]에서 수정했습니다!
    logic [15:0] wData;
    logic        we;

    OV7670_Mem_Controller U_MEM_CTRL (
        .clk  (cam_pclk),
        .reset(reset),
        .href (cam_href),
        .vsync(cam_vsync), //cma_vsync에서 수정했습니다!
        .data (cam_data),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData)
    );

    // Frame Buffer
    logic [14:0] rAddr;  // [16:0]에서 수정했습니다!
    logic [15:0] rData;

    frame_buffer U_FRAME_BUFFER (
        .wclk (cam_pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (video_pclk),
        .oe   (1'b1),
        .rAddr(rAddr),
        .rData(rData)
    );


    /***********************************************
    // Memory Reader
    ***********************************************/
    logic cam_part;

    ImgMemReader U_IMG_READER (
        .DE      (DE),
        .x_pixel (x_pixel),
        .y_pixel (y_pixel),
        .addr    (rAddr),
        .imgData (rData),
        .r_port  (),
        .g_port  (),
        .b_port  (),         // Not Use -> Red_Check Pass
        .cam_part(cam_part)
    );


    /***********************************************
    // Dice Detector
    ***********************************************/
    Red_Check U_RED_CHECK (
        .pixel_data(rData),
        .DE        (cam_part),
        .r_out     (cam_r),
        .g_out     (cam_g),
        .b_out     (cam_b)
    );

    btn_debounce U_BTN_DICE (
        .clk     (clk),
        .rst     (reset),
        .btn_in  (d_btn),
        .btn_tick(dice_en)
    );

    Dice_Reader U_DICE_READER (
        .pclk      (cam_pclk),
        .reset     (reset),
        .vsync     (cam_vsync),
        .we        (we),
        .pixel_in  (wData),
        .dice_value(dice_value)  // Output Dice Result 1~6
    );

endmodule
