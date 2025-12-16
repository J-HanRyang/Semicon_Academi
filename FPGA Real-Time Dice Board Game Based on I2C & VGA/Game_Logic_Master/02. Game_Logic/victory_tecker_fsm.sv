`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/26 16:53:41
// Design Name: 
// Module Name: victory_tecker_fsm
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

module victory_tracker_fsm(
    input  logic       clk,       // 100MHz = 10ns period
    input  logic       rst,

    input  logic       start,     // 전체 매치 시작
    input  logic       restart,   // 매치 리셋
    input  logic       game_end,  // 한 판 종료 (from game_play_fsm)
    input  logic [1:0] game_win,  // 00:무승부, 01:1P승, 10:2P승 <- 말의 위치에대한

    output logic       final_state,
    output logic       next_match,  //tick
    output logic       game_final,   // 매치 종료 (2점 도달) / 1tick
    output logic [1:0] game_result,   // 00:무승부, 01:1P승, 10:2P승 <- 3판2승제에 대한
    output logic [1:0] score_p1,
    output logic [1:0] score_p2
);

    typedef enum logic [2:0] {
        IDLE,          // 처음 상태, 점수 0:0
        WAIT_GAME,     // 한 판 진행 중, game_end 기다림
        UPDATE_SCORE,  // game_win 보고 점수 업데이트
        CHECK_END,     // 2점 도달했는지 확인
        MATCH_OVER     // 최종 결과 확정 후 대기
    } state_t;

    state_t cur_state, next_state;

    // 양쪽 점수 (0~2)
    logic [1:0] score_p1_reg, score_p1_next;
    logic [1:0] score_p2_reg, score_p2_next;

    logic       game_final_reg,  game_final_next;
    logic [1:0] game_result_reg, game_result_next;

    logic final_state_reg, final_state_next;
    logic next_match_reg , next_match_next;

    assign game_final  = game_final_reg;
    assign game_result = game_result_reg;
    assign score_p1 = score_p1_reg;
    assign score_p2 = score_p2_reg;
    assign final_state =  final_state_reg;
    assign next_match = next_match_reg;


     // I2C 딜레이용 카운터 (3ms)
    localparam int I2C_DELAY_CYCLES = 300_000 - 1; // 3ms @ 100MHz
    logic [$clog2(I2C_DELAY_CYCLES+1)-1:0] i2c_cnt_reg, i2c_cnt_next;



    always_ff @(posedge clk or posedge rst) begin 
        if (rst) begin
            cur_state       <= IDLE;
            score_p1_reg        <= 2'd0;
            score_p2_reg        <= 2'd0;
            game_final_reg  <= 1'b0;
            game_result_reg <= 2'b00;
            final_state_reg <= 1'b0;
            next_match_reg  <= 1'b0;
            i2c_cnt_reg          <= 0; 
        end else begin
            cur_state       <= next_state;
            score_p1_reg        <= score_p1_next;
            score_p2_reg        <= score_p2_next;
            game_final_reg  <= game_final_next;
            game_result_reg <= game_result_next;
            final_state_reg <= final_state_next;
            next_match_reg  <= next_match_next;
            i2c_cnt_reg          <= i2c_cnt_next;
        end
    end

    always_comb begin 
        next_state       = cur_state;
        score_p1_next    = score_p1_reg;
        score_p2_next    = score_p2_reg;
        game_final_next  = 1'b0; // 1tick pulse
        game_result_next = game_result_reg;
        final_state_next = final_state_reg;
        next_match_next  = 1'b0; // 1tick pulse
        i2c_cnt_next = i2c_cnt_reg;

        case (cur_state)

            //------------------------------------------------
            IDLE: begin
                // 매치 시작 전: 점수/결과/종료 플래그 초기화
                score_p1_next    = 2'd0;
                score_p2_next    = 2'd0;
                game_final_next  = 1'b0;
                game_result_next = 2'b00;
                final_state_next = 1'b0;

                if (start) begin
                    next_state = WAIT_GAME;
                end
            end

            //------------------------------------------------
            WAIT_GAME: begin
                // 한 판이 끝날 때까지 대기
                if (game_end) begin
                    next_state = UPDATE_SCORE;
                end
                // 중간에 restart 들어오면 완전 초기화
                if (restart) begin
                    next_state = IDLE;
                end
            end

            //------------------------------------------------
            UPDATE_SCORE: begin
                // game_win에 따라 점수 업데이트
                // i2c 신호 겹치는 것 방지용 3ms delay
                    if (i2c_cnt_reg == I2C_DELAY_CYCLES) begin
                        i2c_cnt_next         = '0;      // 카운터 리셋
                        next_state           = CHECK_END;

                        case (game_win)
                    2'b00: begin // 무승부: 둘 다 +1
                        score_p1_next = score_p1_reg + 1;
                        score_p2_next = score_p2_reg + 1;
                    end
                    2'b01: begin // 1P 승
                        score_p1_next = score_p1_reg + 1;
                    end
                    2'b10: begin // 2P 승
                        score_p2_next = score_p2_reg + 1;
                    end
                    default: begin
                        // 나머지는 변화 없음
                    end
                endcase
                    end else begin
                        i2c_cnt_next = i2c_cnt_reg + 1;
                    end
       
            end

            //------------------------------------------------
            CHECK_END: begin
                // 둘 중 누가 2점 도달했는지 확인
                if (score_p1_reg == 2 || score_p2_reg == 2) begin
                    next_state      = MATCH_OVER;
                    game_final_next = 1'b1;
                    final_state_next = 1'b1;

                    // 2:2면 무승부
                    if (score_p1_reg == 2 && score_p2_reg == 2)
                        game_result_next = 2'b00; // draw
                    else if (score_p1_reg == 2)
                        game_result_next = 2'b01; // player1 승
                    else if (score_p2_reg == 2)
                        game_result_next = 2'b10; // player2 승
                end else begin
                    // 아직 누구도 2점 못 가면 다음 판 진행
                    next_state = WAIT_GAME;
                    next_match_next = 1'b1;
                end 
            end

            //------------------------------------------------
            MATCH_OVER: begin
                // game_final=1, game_result는 확정된 상태로 유지
                game_final_next = 1'b0;
                // I2C나 다른 블록이 읽어갈 시간
                if (restart) begin
                    // 새 매치 시작
                    next_state = IDLE;
                    final_state_next = 1'b0;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
