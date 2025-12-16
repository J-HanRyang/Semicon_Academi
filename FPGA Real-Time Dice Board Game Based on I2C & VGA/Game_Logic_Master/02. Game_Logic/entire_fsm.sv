`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/26 14:28:38
// Design Name: 
// Module Name: entire_fsm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module entire_fsm (
    input  logic clk,         // 100MHz = 10ns period
    input  logic rst,
    // fsm 입력
    input  logic u_btn_tick,
    input  logic r_btn_tick,
    input  logic l_btn_tick,
    input  logic time_over,
    input  logic game_final,
    // fsm 출력
    output logic start,
    output logic play_en,
    output logic restart,
    output logic [2:0] play_state
);

    typedef enum logic [2:0] {
        IDLE,
        START_WAIT,      // Ready 상태
        PLAY,
        STOP,
        TIME_OVER,
        TOTAL_GAME_END,  // 진짜 총 게임 끝
        RESTART
    } state;

    state cur_state, next_state;

    logic start_reg,   start_next;
    logic play_en_reg, play_en_next;
    logic restart_reg, restart_next;
    logic clock_en;
    logic clock_end_5s;

    assign start   = start_reg;
    assign play_en = play_en_reg;
    assign restart = restart_reg;

    // 상태/출력 레지스터
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cur_state   <= IDLE;
            start_reg   <= 1'b0;
            play_en_reg <= 1'b0;
            restart_reg <= 1'b0;
        end else begin
            cur_state   <= next_state;
            start_reg   <= start_next;
            play_en_reg <= play_en_next;
            restart_reg <= restart_next;
        end
    end
    always_comb begin 
        case (cur_state)
            IDLE : play_state = 3'b000;
            START_WAIT :  play_state = 3'b001;    // Ready 상태
            PLAY : play_state = 3'b010;
            STOP : play_state = 3'b011;
            TIME_OVER : play_state = 3'b100;
            TOTAL_GAME_END : play_state = 3'b101; // 진짜 총 게임 끝
            RESTART : play_state = 3'b110;
            default: play_state = 3'b000;
        endcase
    end

    // 조합 논리
    always_comb begin
        // 기본값들
        next_state   = cur_state;
        start_next   = 1'b0;          
        play_en_next = play_en_reg;  
        restart_next = 1'b0;         
        clock_en     = 1'b0;

        case (cur_state)
            // --------------------------------------------------
            IDLE: begin
                play_en_next = 1'b0;
                // 처음 U 버튼 -> START_WAIT
                if (u_btn_tick) begin
                    next_state = START_WAIT;
                    start_next = 1'b1;   // 타이머에게 시작 알림(펄스)
                end
            end

            // --------------------------------------------------
            START_WAIT: begin
                play_en_next = 1'b0;
                if (u_btn_tick) begin
                    next_state   = PLAY;
                    play_en_next = 1'b1; // 게임 시작
                end
            end

            // --------------------------------------------------
            PLAY: begin
                play_en_next = 1'b1;
                if (time_over) begin
                    next_state   = TIME_OVER;
                    play_en_next = 1'b0;
                end else if (game_final) begin
                    next_state   = TOTAL_GAME_END;
                    play_en_next = 1'b0;
                end else if (r_btn_tick) begin
                    next_state   = STOP;
                    play_en_next = 1'b0;
                end
            end

            // --------------------------------------------------
            STOP: begin
                play_en_next = 1'b0;
                if (r_btn_tick) begin
                    next_state   = PLAY;
                    play_en_next = 1'b1;
                end
            end

            // --------------------------------------------------
            TIME_OVER: begin
                play_en_next = 1'b0;
                if (l_btn_tick) begin
                    next_state   = RESTART;
                    restart_next = 1'b1;  // 타이머/게임 쪽에 재시작 요청
                end
            end

            // --------------------------------------------------
            TOTAL_GAME_END: begin
                play_en_next = 1'b0;
                if (l_btn_tick) begin
                    next_state   = RESTART;
                    restart_next = 1'b1;
                end
            end

            // --------------------------------------------------
            RESTART: begin
                play_en_next = 1'b0;
                clock_en     = 1'b1;      // 10초 카운터 작동

                if (clock_end_5s) begin
                    next_state = START_WAIT;
                    start_next = 1'b1;    // Ready로 돌아가면서 start 한 번 더 알림
                end
            end

            default: begin
                next_state   = IDLE;
            end
        endcase
    end

    // 10초 카운터
    // 5초 카운터
    counter_5s U_CNT_5S (
        .clk          (clk),           // 100MHz = 10ns period
        .rst          (rst),
        .clock_en     (clock_en),      // 1이면 counting
        .clock_end_5s(clock_end_5s)  // 10초마다 1clk pulse
    );

endmodule


// clock_en 이 1이 되면 10초 카운트 후 clock_end_10s 1clk 펄스
module counter_5s (
    input  logic clk,           // 100MHz = 10ns period
    input  logic rst,
    input  logic clock_en,      // 1이면 counting
    output logic clock_end_5s  // 10초마다 1clk pulse
);

    // 1초 = 100,000,000 clk (시뮬할 땐 줄여서 사용)
    localparam int MAX_COUNT = 100_000_000 - 1;
    //localparam int MAX_COUNT = 1000 - 1;

    logic [$clog2(MAX_COUNT+1)-1:0] counter;
    logic [2:0]                     cnt_5s;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter       <= 0;
            cnt_5s       <= 0;
            clock_end_5s <= 1'b0;
        end else begin
            // 기본: 펄스는 0
            clock_end_5s <= 1'b0;

            if (!clock_en) begin
                // enable 내려가면 항상 내부 카운터 리셋
                counter <= 0;
                cnt_5s <= 0;
            end else begin
                // clock_en = 1일 때만 카운트
                if (counter == MAX_COUNT) begin
                    counter <= 0;
                    if (cnt_5s == 4'd2) begin
                        clock_end_5s <= 1'b1;  // 정확히 10초 후 펄스
                        cnt_5s       <= 0;
                    end else begin
                        cnt_5s <= cnt_5s + 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end

endmodule

