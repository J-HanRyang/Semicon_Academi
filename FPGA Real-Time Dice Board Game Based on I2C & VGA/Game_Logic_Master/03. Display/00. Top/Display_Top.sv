`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/12/01
// Design Name      : Main_Game_Master
// Module Name      : Display_Top
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Display Top Module
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////

module Display_Top (
    input  logic       iClk,
    // [Input 1] VGA Interface
    input  logic [9:0] iX_Pixel,
    input  logic [9:0] iY_Pixel,
    input  logic       iDE,
    // [Input 2] Camera Input
    input  logic [3:0] iCam_R,
    input  logic [3:0] iCam_G,
    input  logic [3:0] iCam_B,
    input  logic       iIs_Cam_Region,
    // [Input 2] Game Logic Interface
    input  logic [5:0] iP1_Pos,
    input  logic [5:0] iP2_Pos,
    input  logic [3:0] iMin10,
    input  logic [3:0] iMin1,
    input  logic [3:0] iSec10,
    input  logic [3:0] iSec1,
    input  logic [2:0] iGame_State,
    input  logic       iWait_P1,
    input  logic       iWait_P2,
    input  logic [1:0] score_p1,        // P1 승리 횟수 (0~3)
    input  logic [1:0] score_p2,        // P2 승리 횟수 (0~3)
    // Output
    output logic [3:0] oFinal_R,
    output logic [3:0] oFinal_G,
    output logic [3:0] oFinal_B
);


    /***********************************************
    // Back Ground Image
    ***********************************************/
    (* rom_style = "distributed" *)logic [15:0] bg_mem  [0:(320*240)];  // LUT
    logic [16:0] bg_addr;
    logic [15:0] bg_data;
    logic [11:0] bg_rgb;

    //(* rom_style = "block" *)logic [15:0] bg_mem  [0:76799];  // BRAM
    // (* rom_style = "distributed" *)logic [15:0] bg_mem  [0:76799]; // LUT

    initial begin
        $readmemh("board.mem", bg_mem);
    end

    Back_Mem_Reader U_BACK_READER (
        .clk    (iClk),
        .x      (iX_Pixel),
        .y      (iY_Pixel),
        .data_in(bg_data),
        .addr   (bg_addr),
        .rgb_out(bg_rgb)
    );

    // Read Memory
    always_ff @(posedge iClk) begin
        bg_data <= bg_mem[bg_addr];
    end


    /***********************************************
    // Text Display
    ***********************************************/
    logic        is_text;
    logic [11:0] txt_rgb;

    Text_Display U_TEXT (
        .clk     (iClk),
        .x       (iX_Pixel),
        .y       (iY_Pixel),
        .min10   (iMin10),
        .min1    (iMin1),
        .sec10   (iSec10),
        .sec1    (iSec1),
        .state   (iGame_State),
        .wait_p1 (iWait_P1),
        .wait_p2 (iWait_P2),
        .score_p1(score_p1),
        .score_p2(score_p2),
        .is_text (is_text),
        .txt_rgb (txt_rgb)
    );


    /***********************************************
    // Piece Display
    ***********************************************/
    logic is_p1, is_p2;

    Game_Piece_Display U_PIECE (
        .iClk   (iClk),
        .iRst   (iRst),
        .iX     (iX_Pixel),
        .iY     (iY_Pixel),
        .iP1_Pos(iP1_Pos),
        .iP2_Pos(iP2_Pos),
        .oIs_P1 (is_p1),
        .oIs_P2 (is_p2)
    );

    /***********************************************
    // Final Winner
    ***********************************************/
    always_comb begin
        if (!iDE) begin
            {oFinal_R, oFinal_G, oFinal_B} = 12'h000;
        end else if (is_text) begin
            {oFinal_R, oFinal_G, oFinal_B} = txt_rgb;
        end else if (is_p1) begin
            {oFinal_R, oFinal_G, oFinal_B} = 12'hf00;  // Red
        end else if (is_p2) begin
            {oFinal_R, oFinal_G, oFinal_B} = 12'h00f;  // Blue
        end else if (iIs_Cam_Region) begin
            {oFinal_R, oFinal_G, oFinal_B} = {
                iCam_R, iCam_G, iCam_B
            };  //{iCam_R, iCam_R, iCam_B}에서 수정했습니다!
        end else begin
            {oFinal_R, oFinal_G, oFinal_B} = bg_rgb;
        end
    end

endmodule
