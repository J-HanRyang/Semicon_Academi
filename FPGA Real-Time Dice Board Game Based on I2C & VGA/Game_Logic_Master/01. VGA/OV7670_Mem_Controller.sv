`timescale 1ns / 1ps

module OV7670_Mem_Controller (
    input  logic        clk,
    input  logic        reset,
    // OV7670 side
    input  logic        href,
    input  logic        vsync,
    input  logic [ 7:0] data,
    // memory side
    output logic        we,
    output logic [14:0] wAddr,
    output logic [15:0] wData
);
    logic [15:0] pixelCounter;  // 저장된 픽셀 개수 (주소 역할)
    logic [15:0] pixelData;  // 픽셀 색상 데이터 조립용

    logic [9:0] x_cnt;
    logic [9:0] y_cnt;
    logic        byte_flag;  // 상위/하위 바이트 구분 (기존 pixelCounter[0] 역할)
    logic href_last;  // 줄이 바뀌는 것 감지용


    assign wAddr = pixelCounter[14:0];
    assign wData = pixelData;

    always_ff @(posedge clk) begin
        if (reset) begin
            pixelCounter <= 0;
            we           <= 0;
            x_cnt        <= 0;
            y_cnt        <= 0;
            byte_flag    <= 0;
        end else begin
            href_last <= href;

            if (href) begin
                we <= 0;  // 기본은 쓰기 금지

                if (byte_flag == 0) begin
                    pixelData[15:8] <= data;
                    byte_flag       <= 1;
                end else begin
                    pixelData[7:0] <= data;
                    byte_flag      <= 0;

                    // [다운스케일링] 짝수 픽셀 & 짝수 줄만 저장
                    if (x_cnt[0] == 0 && y_cnt[0] == 0) begin
                        we           <= 1;
                        pixelCounter <= pixelCounter + 1;
                    end

                    x_cnt <= x_cnt + 1;
                end
            end 
            else if (vsync) begin // [VSYNC 리셋] href가 없을 때 vsync를 확인하여 리셋
                pixelCounter <= 0;
                we           <= 0;
                x_cnt        <= 0;
                y_cnt        <= 0;
                byte_flag    <= 0;
            end else begin
                we <= 0;
            end

            // [줄 바꿈 감지] href가 1 -> 0 으로 떨어질 때
            if (href_last && !href) begin
                y_cnt     <= y_cnt + 1;
                x_cnt     <= 0;
                byte_flag <= 0;
            end
        end
    end
endmodule
