
`timescale 1ns / 1ps

module timer (
    input  logic       clk,         // 100MHz = 10ns period
    input  logic       rst,
    //fsm  조정
    input  logic       start,       //from top_fsm
    input  logic       play_en,     // 1: run, 0:stop
    input  logic       game_final,  //게임이 끝남 -> 시간이 멈춤
    input  logic       restart,
    // decimal time :  값
    output logic [3:0] sec0,        // 초 1의 자리
    output logic [3:0] sec1,        // 초 10의 자리
    output logic [3:0] min0,        // 분 1의 자리
    output logic [3:0] min1,        // 분 10의 자리
    output logic       time_over    // 0이 되면 1
);

    logic clk_1s;
    logic run_stop;
    logic clear;

    timer_control_Unit U_timer_control_Unit (
        .clk(clk),
        .rst(rst),
        .start(start),  // 게임 스타트 -> stop
        .play_en(play_en),  // 1: run, 0:stop
        .game_final(game_final),  //게임이 끝남 -> 시간이 멈춤
        .time_over(time_over),  // time_over시 game_end
        .restart(restart),  // restart시 다시 10:00
        .run_stop(run_stop),
        .clear(clear)
    );

    Tick_gen_1s U_Tick_GEN_1S (
        .clk   (clk),    // 10ns period
        .rst   (rst),
        .run_stop(run_stop),
        .clk_1s(clk_1s)  // 1-sec tick pulse (1 clk width)
    );

    down_counter U_down_counter (
        .clk      (clk),
        .rst      (rst),
        .clk_1s   (clk_1s),
        .clear    (clear),
        .sec0     (sec0),
        .sec1     (sec1),
        .min0     (min0),
        .min1     (min1),
        .time_over(time_over)
    );

endmodule





module timer_control_Unit (
    input logic clk,
    input logic rst,

    input logic start,       // 게임 스타트 -> stop
    input logic play_en,     // 1: run, 0:stop
    input logic game_final,  //게임이 끝남 -> 시간이 멈춤
    input logic time_over,   // time_over시 game_end
    input logic restart,     // restart시 다시 10:00

    output logic run_stop,
    output logic clear
);

    typedef enum logic [1:0]{
        INIT,
        STOP,
        RUN,
        GAME_END
    } state_t;

    state_t cur_state, next_state;

    logic run_stop_reg, run_stop_next;
    logic clear_reg, clear_next;

    assign run_stop = run_stop_reg;
    assign clear = clear_reg;


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            cur_state <= INIT;
            run_stop_reg <= 0;
            clear_reg <= 1;
        end else begin
            cur_state <= next_state;
            run_stop_reg <= run_stop_next;
            clear_reg <= clear_next;
        end
    end


    always_comb begin
        next_state = cur_state;
        clear_next    = clear_reg;
        run_stop_next = run_stop_reg;


        case (cur_state)
            INIT: begin  // clear 10:00
                clear_next = 1;
                run_stop_next = 0;
                if (start) begin
                    next_state = STOP;
                    clear_next = 0;
                    run_stop_next = 0;
                end
            end
            STOP: begin
                clear_next = 0;
                run_stop_next = 0;
                if (play_en) begin
                    next_state = RUN;
                    clear_next = 0;
                    run_stop_next = 1;
                end
            end
            RUN: begin
                clear_next = 0;
                run_stop_next = 1;

                if (time_over || game_final) begin  // 우선순위 1
                        next_state = GAME_END;
                        clear_next    = 0;
                        run_stop_next = 0;
                end else if (play_en == 0) begin
                    next_state = STOP;
                    clear_next = 0;
                    run_stop_next = 0;
                end
            end
            GAME_END: begin
                if (restart) begin
                    next_state = INIT;
                end
            end
        endcase
    end



endmodule


module down_counter (
    input  logic       clk,        // 100MHz = 10ns period
    input  logic       rst,
    input  logic       clk_1s,     // 1초 tick (이미 run_stop 반영됨)
    input  logic       clear,      // 1: clear -> 10:00 로드
    output logic [3:0] sec0,       // 초 1의 자리
    output logic [3:0] sec1,       // 초 10의 자리
    output logic [3:0] min0,       // 분 1의 자리
    output logic [3:0] min1,       // 분 10의 자리
    output logic       time_over   // 0이 되면 1
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // 비동기 리셋 : 10:00, time_over 클리어
            min1      <= 4'd1;   // 10분
            min0      <= 4'd0;
            sec1      <= 4'd0;
            sec0      <= 4'd0;
            time_over <= 1'b0;
        end else begin
            // clear가 1이면 언제든지 10:00으로 재설정
            if (clear) begin
                min1      <= 4'd1;
                min0      <= 4'd0;
                sec1      <= 4'd0;
                sec0      <= 4'd0;
                time_over <= 1'b0;
            end
            // 이미 끝났으면 값 유지
            else if (time_over) begin
                time_over <= 1'b1;
            end
            // 정상 동작: 1초 tick 들어올 때만 감소
            else if (clk_1s) begin

                // 00:01 -> 00:00 으로 가는 경우
                if ((min1 == 4'd0) && (min0 == 4'd0) &&
                    (sec1 == 4'd0) && (sec0 == 4'd1)) begin

                    min1      <= 4'd0;
                    min0      <= 4'd0;
                    sec1      <= 4'd0;
                    sec0      <= 4'd0;
                    time_over <= 1'b1;

                end else begin
                    // 일반적인 BCD 다운카운트
                    if (sec0 > 0) begin
                        sec0 <= sec0 - 1;
                    end else begin
                        sec0 <= 4'd9;
                        if (sec1 > 0) begin
                            sec1 <= sec1 - 1;
                        end else begin
                            sec1 <= 4'd5;
                            if (min0 > 0) begin
                                min0 <= min0 - 1;
                            end else begin
                                min0 <= 4'd9;
                                if (min1 > 0) begin
                                    min1 <= min1 - 1;
                                end
                            end
                        end
                    end
                end
            end
            // 나머지 경우 → 값 유지
        end
    end

endmodule


module Tick_gen_1s (
    input  logic clk,       // 100MHz = 10ns period
    input  logic rst,
    input  logic run_stop,  // 1: tick 생성, 0: 카운터 정지 (pause)
    output logic clk_1s     // 1-sec tick pulse (1 clk width)
);

    // 진짜 1s
    localparam int MAX_COUNT = 100_000_000 - 1;
    // 시뮬용 
    //localparam int MAX_COUNT = 10000 - 1;

    logic [$clog2(MAX_COUNT+1)-1:0] counter;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            clk_1s  <= 0;
        end else begin
            if (!run_stop) begin
                // 일시정지: counter 그대로, tick은 0
                counter <= counter;
                clk_1s  <= 0;
            end else begin
                if (counter == MAX_COUNT) begin
                    counter <= 0;
                    clk_1s  <= 1;   // 1-cycle pulse
                end else begin
                    counter <= counter + 1;
                    clk_1s  <= 0;
                end
            end
        end
    end

endmodule
