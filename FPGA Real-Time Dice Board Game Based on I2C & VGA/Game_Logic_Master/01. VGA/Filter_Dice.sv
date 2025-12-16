`timescale 1ns / 1ps

module Red_Check (
    input  logic [15:0] pixel_data,
    input  logic        DE,
    output logic [ 3:0] r_out,
    output logic [ 3:0] g_out,
    output logic [ 3:0] b_out
);
    logic [4:0] r;
    logic [5:0] g;
    logic [4:0] b;

    assign r = pixel_data[15:11];
    assign g = pixel_data[10:5];
    assign b = pixel_data[4:0];

    // 빨간색 감지 조건 수정해서 감도 조절
    logic is_red;
    // assign is_red = (r > 8) && (g < 8) && (b < 8);
    assign is_red = (r > 10) && (r > g[5:1] + 2) && (r > b + 2);

    always_comb begin
        if (DE) begin
            if (is_red) begin
                r_out = r[4:1];
                g_out = g[5:2];
                b_out = b[4:1];
                // 빨간색이 감지되면 흰색 출력
                // r_out = 4'hF;
                // g_out = 4'hF;
                // b_out = 4'hF;
            end else begin
                // 빨간색이 아니면 검은색 출력 (배경 지우기)
                // r_out = r[4:1];
                // g_out = g[4:1];
                // b_out = b[4:1];
                r_out = 4'h0;
                g_out = 4'h0;
                b_out = 4'h0;
            end
            // r_out = r[4:1]; g_out = g[5:2]; b_out = b[4:1];
        end else begin
            // 화면 밖 구간 0
            r_out = 4'h0;
            g_out = 4'h0;
            b_out = 4'h0;
        end
    end

endmodule


module Dice_Reader (
    input  logic        pclk,
    input  logic        reset,
    input  logic        vsync,
    input  logic        we,
    input  logic [15:0] pixel_in,
    output logic [ 2:0] dice_value
);

    logic [4:0] r;
    logic [5:0] g;
    logic [4:0] b;

    assign r = pixel_in[15:11];
    assign g = pixel_in[10:5];
    assign b = pixel_in[4:0];


    logic is_red_pixel;
    assign is_red_pixel = (r > 10) && (r > g[5:1] + 2) && (r > b + 2);

    // 픽셀 카운팅
    logic [31:0] current_count;
    logic [31:0] final_count;

    // always_ff @(posedge pclk) begin
    //     if (reset) begin
    //         current_count <= 0;
    //         final_count   <= 0;
    //     end else if (vsync) begin
    //         final_count   <= current_count;
    //         current_count <= 0;
    //     end else begin
    //         if (we && is_red_pixel) begin
    //             current_count <= current_count + 1;
    //         end
    //     end
    // end

    // [수정된 카운팅 및 저장 로직]
    always_ff @(posedge pclk) begin
        if (reset) begin
            current_count <= 0;
            final_count   <= 0;
        end else begin
            if (vsync) begin
                if (current_count > 0) begin
                    final_count   <= current_count;
                    current_count <= 0;
                end
            end else begin
                if (we && is_red_pixel) begin
                    current_count <= current_count + 1;
                end
            end
        end
    end


    // 결과 출력
    localparam MIN_CNT = 125;
    localparam UNIT = 250;
    logic [2:0] dice_num;

    always_comb begin
        if (final_count < MIN_CNT) dice_num = 0;
        else if (final_count < MIN_CNT + UNIT) dice_num = 1;
        else if (final_count < MIN_CNT + UNIT * 2) dice_num = 2;
        else if (final_count < MIN_CNT + UNIT * 3) dice_num = 3;
        else if (final_count < MIN_CNT + UNIT * 4) dice_num = 4;
        else if (final_count < MIN_CNT + UNIT * 5) dice_num = 5;
        else dice_num = 6;
    end

    // assign led_out[2:0]  = dice_num;
    // assign led_out[3]    = (final_count > 0); // 1개라도 잡히면 켜짐
    // assign led_out[14:4] = final_count[10:0]; // 카운트 값 직접 표시
    assign dice_value = dice_num;

endmodule
