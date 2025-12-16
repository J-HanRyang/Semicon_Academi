`timescale 1ns / 1ps

module OV7670_CCTV (
    input  logic       clk,
    input  logic       reset,
    //-------- OV76710 side-----------
    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] data,

    // +  SDA,SCA
    output logic SCCB_SCL,
    inout  wire  SCCB_SDA,

    // Filter SW
    input logic [7:0] current_status_in,  // Reg0
    input logic [7:0] game_result_in,  // Reg1
    input logic [7:0] change_status_in,  // Reg2

    //---------vga port--------------
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port,
    //-------------------------------
    output logic       SCCB_Init_done
);

    logic        sys_clk;
    logic        DE;
    logic [ 9:0] x_pixel;
    logic [ 9:0] y_pixel;

    logic [16:0] rAddr;
    logic [15:0] rData;

    logic        we;
    logic [16:0] wAddr;
    logic [15:0] wData;

    // Filter 관련 신호
    logic [3:0] wRaw_R, wRaw_G, wRaw_B;
    logic [3:0] wFilter_R, wFilter_G, wFilter_B;
    logic signed [4:0] wX_Offset, wY_Offset;

    // ---------------------------------------------------------------
    // ★ 핵심 수정: 좌표 계산 (Upscaling + Offset + Clamping)
    // ---------------------------------------------------------------
    // 중간 계산용 (부호와 범위를 넉넉하게 잡음)
    logic signed [11:0] calc_X, calc_Y;
    // 실제 ImgMemReader에 들어갈 최종 좌표
    logic [9:0] wRead_X, wRead_Y;

    always_comb begin
        // 1. Upscaling & Offset 적용
        // x_pixel[9:1] : 640좌표를 2로 나누어 320좌표로 변환 (2배 확대 효과)
        // $signed(...) : 오프셋(음수 가능) 계산을 위해 부호 있는 수로 변환
        calc_X = $signed({1'b0, x_pixel[9:1]}) + wX_Offset;
        calc_Y = $signed({1'b0, y_pixel[9:1]}) + wY_Offset;

        // 2. 범위 제한 (Clamping)
        // 계산된 좌표가 화면 밖(음수거나 320/240 초과)으로 나가면 
        // 가장자리 값이나 0으로 고정하여 검은 화면/깨짐 방지
        if (calc_X < 0) wRead_X = 0;
        else if (calc_X >= 320) wRead_X = 319;
        else wRead_X = calc_X[9:0];

        if (calc_Y < 0) wRead_Y = 0;
        else if (calc_Y >= 240) wRead_Y = 239;
        else wRead_Y = calc_Y[9:0];
    end
    // ---------------------------------------------------------------

    assign xclk = sys_clk;

    // I2C Init
    OV7076_Init_SCCB_inf U_OV7076_Init_SCCB_inf (
        .clk(clk),
        .reset(reset),
        .CAM_SCL(SCCB_SCL),
        .CAM_SDA(SCCB_SDA),
        .init_done(SCCB_Init_done)
    );

    // Clock Generator
    pixel_clk_gen U_PXL_CLK_GEN (
        .clk  (clk),
        .reset(reset),
        .pclk (sys_clk)
    );

    // VGA Timing
    VGA_Syncher U_VGA_Syncher (
        .clk    (sys_clk),
        .reset  (reset),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );

    // Image Memory Reader
    // ★ 수정된 wRead_X, wRead_Y를 연결합니다.
    ImgMemReader U_Img_Reader (
        .DE(DE),
        .x_pixel(wRead_X),      // <--- 수정됨 (확대 및 오프셋 적용된 좌표)
        .y_pixel(wRead_Y),  // <--- 수정됨
        .addr(rAddr),
        .imgData(rData),
        .r_port(wRaw_R),
        .g_port(wRaw_G),
        .b_port(wRaw_B)
    );

    // Frame Buffer
    frame_buffer U_Frame_Buffer (
        .wclk (pclk),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData),
        .rclk (sys_clk),
        .oe   (1'b1),
        .rAddr(rAddr),
        .rData(rData)
    );

    // Camera Controller
    OV7670_Mem_Controller U_OV7670_Mem_Controller (
        .clk  (pclk),
        .reset(reset),
        .href (href),
        .vsync(vsync),
        .data (data),
        .we   (we),
        .wAddr(wAddr),
        .wData(wData)
    );

    // Filter Module
    Filter U_Filter (
        .iClk   (sys_clk),
        .iRst   (reset),    // 리셋 연결 필수
        .iV_Sync(v_sync),

        // ★ 패턴(비/별)은 전체 화면(640x480) 기준으로 그려야 하므로 원본 좌표 사용
        .iX                (x_pixel),
        .iY                (y_pixel),
        .iR                (wRaw_R),
        .iG                (wRaw_G),
        .iB                (wRaw_B),
        .current_status_in(current_status_in),  // Reg0
        .game_result_in   (game_result_in),     // Reg1
        .change_status_in (change_status_in),   // Reg2
        .oR                (wFilter_R),
        .oG                (wFilter_G),
        .oB                (wFilter_B),
        .oX_Offset         (wX_Offset),
        .oY_Offset         (wY_Offset)
    );

    assign r_port = wFilter_R;
    assign g_port = wFilter_G;
    assign b_port = wFilter_B;

endmodule
