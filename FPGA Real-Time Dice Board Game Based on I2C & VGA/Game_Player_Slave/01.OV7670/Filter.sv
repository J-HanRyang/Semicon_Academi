`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/11/28
// Design Name      : Game_Player_Slave
// Module Name      : Filter
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Variable Filter
//
// Revision 	    : 2025/11/28    Ver_1.0 (Gray / Shake)
//                  : 2025/11/29    Ver_1.1 (Mosaic / Bright)   -> Apply Image
//                  : 2025/11/29    Ver_1.2 (Rain / Star)       -> Apply OV7670
//                  : 2025/11/30    Ver_2.0 Connect Slave       -> Check Connection with Master
//                  : 2025/12/02    Ver_2.1 Filter Prioritization,
//                                          Change Status After 1 Sec Filter Off
//                  : 2025/12/04    Ver_2.2 1 second clear removal
//////////////////////////////////////////////////////////////////////////////////

module Filter (
    // Clock & Reset
    input  logic              iClk,
    input  logic              iRst,
    // VGA_Input
    input  logic              iV_Sync,
    input  logic        [9:0] iX,
    input  logic        [9:0] iY,
    input  logic        [3:0] iR,
    input  logic        [3:0] iG,
    input  logic        [3:0] iB,
    // SW -> Slave SIgnal
    input  logic        [7:0] current_status_in,  // Reg0
    input  logic        [7:0] game_result_in,     // Reg1
    input  logic        [7:0] change_status_in,   // Reg2
    // VGA_Output
    output logic signed [4:0] oX_Offset,
    output logic signed [4:0] oY_Offset,
    output logic        [3:0] oR,
    output logic        [3:0] oG,
    output logic        [3:0] oB
);

    /**************************************************
    // Random Numver Generator
    **************************************************/
    logic [15:0] rLFSR;  // Linear Feedback Shift Register (XOR Opperation)

    always_ff @(posedge iClk) begin
        if (iRst) rLFSR <= 16'hACE1;
        else
            rLFSR <= (rLFSR == 0) ? 16'hACE1 : {rLFSR[14:0], rLFSR[15] ^ rLFSR[13] ^ rLFSR[12] ^ rLFSR[10]};
    end

    /**************************************************
    // Calculate Particle Positions (Rain/Star)
    **************************************************/
    localparam NUM_PARTICLES = 10;

    logic   [9:0] rPart_X    [0:NUM_PARTICLES-1];  // X-Position
    logic   [9:0] rPart_Y    [0:NUM_PARTICLES-1];  // Y-Position
    logic   [2:0] rPart_Speed[0:NUM_PARTICLES-1];  // Drop Speed

    integer       i;
    always_ff @(posedge iV_Sync, posedge iRst) begin
        if (iRst) begin  // Initial Position Setting
            for (i = 0; i < NUM_PARTICLES; i = i + 1) begin
                rPart_X[i] <= (i * 64);
                rPart_Y[i] <= 500;
                rPart_Speed[i] <= 3;
            end
        end else begin
            for (i = 0; i < NUM_PARTICLES; i = i + 1) begin
                if (rPart_Y[i] >= 480 || (game_result_in != 8'h02 && game_result_in != 8'h03)) begin
                    if (game_result_in == 8'h02 || game_result_in == 8'h03) begin // Filter -> Y reset
                        rPart_Y[i] <= 0;  // Y : 480 -> 0
                        rPart_X[i] <= (rLFSR + (i * 77)) % 640;     // X : Random Position
                        rPart_Speed[i] <= ((rLFSR >> 4) % 5) + 2;   // Rabdom Speed Setting
                    end else begin
                        rPart_Y[i] <= 500;  // No Filter
                    end
                end else begin
                    if (game_result_in == 8'h03)  // Rain
                        rPart_Y[i] <= rPart_Y[i] + (rPart_Speed[i] == 0 ? 2 : rPart_Speed[i] * 3);  // Rain Drop (Fast)
                    else if (game_result_in == 8'h02)  // Star
                        rPart_Y[i] <= rPart_Y[i] + (rPart_Speed[i] == 0 ? 1 : rPart_Speed[i]);      // Star Drop (Slow)
                end
            end
        end
    end

    /**************************************************
    // Drawing Particles
    **************************************************/
    logic rIs_Rain, rIs_Star_Core, rIs_Star_Halo;

    always_ff @(posedge iClk) begin
        rIs_Rain      <= 0;
        rIs_Star_Core <= 0;
        rIs_Star_Halo <= 0;

        if (game_result_in == 8'h03) begin  // Rain
            for (int k = 0; k < NUM_PARTICLES; k++) begin
                if ((iX >= rPart_X[k] && iX < rPart_X[k] + 4) &&    // Width  : 4  Pixel
                    (iY >= rPart_Y[k] && iY < rPart_Y[k] + 40))     // Length : 40 Pixel
                    rIs_Rain <= 1;
            end
        end else if (game_result_in == 8'h02) begin  // Star
            for (int k = 0; k < NUM_PARTICLES; k++) begin
                if ((iX >= rPart_X[k] && iX < rPart_X[k]+4) &&  // Width  : 4 Pixel
                    (iY >= rPart_Y[k] && iY < rPart_Y[k]+4))    // Length : 4 Pixel
                    rIs_Star_Core <= 1;
                else if ((iX >= rPart_X[k]-4 && iX < rPart_X[k]+8) &&   // Width  : 8 Pixel
                    (iY >= rPart_Y[k]-4 && iY < rPart_Y[k]+8))     // Length : 4 Pixel
                    rIs_Star_Halo <= 1;
            end
        end
    end

    /**************************************************
    // Text (WIN, LOSE)
    **************************************************/
    logic wIs_Win_Text;
    logic wIs_Lose_Text;

    // Text Scale : Y 120 ~ 200
    always_comb begin
        wIs_Win_Text  = 0;
        wIs_Lose_Text = 0;

        // WIN
        if (game_result_in == 8'h02) begin
            if (iY >= 120 && iY < 200) begin
                // W: |  |  |
                // Left
                if (iX >= 220 && iX < 230) wIs_Win_Text = 1;
                // Right
                if (iX >= 280 && iX < 290) wIs_Win_Text = 1;
                // Center
                if (iX >= 250 && iX < 260 && iY >= 160) wIs_Win_Text = 1;
                // W : ㅡㅡ
                if (iX >= 220 && iX < 290 && iY >= 190) wIs_Win_Text = 1;

                // I : Oblong
                if (iX >= 310 && iX < 330) wIs_Win_Text = 1;

                // N : | |
                if (iX >= 350 && iX < 365) wIs_Win_Text = 1;
                if (iX >= 395 && iX < 410) wIs_Win_Text = 1;
                // Diagonal \
                if (iX >= 365 && iX < 395) begin
                    // Y coordinate is proportional to X
                    if ((iY - 120) > (iX - 365) * 2 && (iY - 120) < (iX - 365) * 2 + 15)
                        wIs_Win_Text = 1;
                end
            end
        end

        // LOSE
        if (game_result_in == 8'h03) begin
            if (iY >= 120 && iY < 200) begin
                // L : |
                if (iX >= 200 && iX < 215) wIs_Lose_Text = 1;
                // L : ㅡ
                if (iX >= 200 && iX < 240 && iY >= 185) wIs_Lose_Text = 1;

                // O
                if (iX >= 260 && iX < 300) begin
                    // Drill a hole inside
                    if (!(iX >= 270 && iX < 290 && iY >= 130 && iY < 190))
                        wIs_Lose_Text = 1;
                end

                // S : ---
                if (iX >= 320 && iX < 360) begin
                    if (iY >= 120 && iY < 135) wIs_Lose_Text = 1;  // Top
                    if (iY >= 152 && iY < 167) wIs_Lose_Text = 1;  // Middle
                    if (iY >= 185 && iY < 200) wIs_Lose_Text = 1;  // Bottom
                end
                // S : |
                if (iX >= 320 && iX < 335 && iY >= 120 && iY < 160)
                    wIs_Lose_Text = 1;
                if (iX >= 345 && iX < 360 && iY >= 160 && iY < 200)
                    wIs_Lose_Text = 1;

                // E : |
                if (iX >= 380 && iX < 395) wIs_Lose_Text = 1;
                // E : ---
                if (iX >= 380 && iX < 420) begin
                    if (iY >= 120 && iY < 135) wIs_Lose_Text = 1;  // Top
                    if (iY >= 152 && iY < 167) wIs_Lose_Text = 1;  // Middle
                    if (iY >= 185 && iY < 200) wIs_Lose_Text = 1;  // Bottom
                end
            end
        end
    end

    /**************************************************
    // Shaking Effect & Counter (Ver_2.2 Fix)
    /**************************************************/
    logic [4:0] rShake_Cnt;

    always_ff @(posedge iV_Sync, posedge iRst) begin
        if (iRst) begin
            rShake_Cnt          <= 0;
        end else begin
            rShake_Cnt          <= rShake_Cnt + 1;
        end
    end

    
    /**************************************************
    // Color Change -> Mux Out (Ver_2.1 Fix)
    **************************************************/
    logic [11:0] wGray;
    logic [3:0] wR_Bright, wG_Bright, wB_Bright;

    always_comb begin
        wGray = (iR * 51) + (iG * 179) + (iB * 26);

        wR_Bright = (iR > 11) ? 4'hf : (iR + 4);
        wG_Bright = (iG > 11) ? 4'hf : (iG + 4);
        wB_Bright = (iB > 11) ? 4'hf : (iB + 4);
    end

    always_comb begin
        // Default
        oX_Offset = 0;
        oY_Offset = 0;
        oR        = iR;
        oG        = iG;
        oB        = iB;

        /**************************************************
        // Game_Result
        **************************************************/
        if (game_result_in == 8'h02) begin  // WIN
            if (wIs_Win_Text) begin
                oR = 15;
                oG = 14;
                oB = 0;  // letter Color : Gold
            end else if (rIs_Star_Core) begin
                oR = 15;
                oG = 15;
                oB = 15;  // Star Core Color : White
            end else if (rIs_Star_Halo) begin
                oR = 15;
                oG = 14;
                oB = 0;
            end else begin
                oR = iR;
                oG = iG;
                oB = iB;
            end
        end else if (game_result_in == 8'h03) begin  // LOSE
            if (wIs_Lose_Text) begin
                oR = 15;
                oG = 0;
                oB = 0;  // letter Color : RED
            end else if (rIs_Rain) begin
                oR = 3;
                oG = 3;
                oB = 15;  // Rain Color : BLUE
            end else begin
                oR = wGray[11:8];
                oG = wGray[11:8];
                oB = wGray[11:8];  // BGC : Gray
            end
        end else if (game_result_in == 8'h01) begin // Drwq
            oR = iR;
            oG = iG;
            oB = iB;
        end


        /**************************************************
        // Change_Status (Ver_2.2 Fix)
        **************************************************/
        else if (change_status_in != 0) begin
            // Trap -> Shake
            if (change_status_in == 8'h01) begin
                oX_Offset = {1'b0, rShake_Cnt[0], rShake_Cnt[2], rShake_Cnt[1]} -4;
                oY_Offset = {1'b0, rShake_Cnt[1], rShake_Cnt[3], rShake_Cnt[0]} -4;

                if (iY[4] == 0) begin
                    oR = 0;
                    oG = 0;
                    oB = 0;
                end else begin
                    oR = wGray[11:8];
                    oG = wGray[11:8];
                    oB = wGray[11:8];
                end
            end else if (change_status_in == 8'h02) begin // Ladder
                oR = iR;
                oG = iG;
                oB = iB >> 2;
            end
        end

        /**************************************************
        // Change_Status
        **************************************************/
        else if (current_status_in == 8'h01) begin  // Winning
            oR = wR_Bright;
            oG = wG_Bright;
            oB = wB_Bright;
        end else if (current_status_in == 8'h02) begin  // Losing
            oR = wGray[11:8];
            oG = wGray[11:8];
            oB = wGray[11:8];
        end
    end

endmodule
