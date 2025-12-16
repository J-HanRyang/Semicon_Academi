`timescale 1ns / 1ps

module Text_Display (
    input logic       clk,
    input logic [9:0] x,
    input logic [9:0] y,        // 현재 픽셀 좌표
    input logic [3:0] min10, min1,  // 타이머 (분)
    input logic [3:0] sec10, sec1,  // 타이머 (초)
    input logic [2:0] state,    // 게임 상태 (0~6)
    input logic       wait_p1,  // Player 1 턴
    input logic       wait_p2,  // Player 2 턴

    // 스코어 입력
    input logic [1:0] score_p1,  // P1 승리 횟수 (0~3)
    input logic [1:0] score_p2,  // P2 승리 횟수 (0~3)

    output logic        is_text,  // 1이면 글자(또는 테두리) 출력
    output logic [11:0] txt_rgb   // 글자 색상
);

    // -----------------------
    // 셀(문자) 관련 상수
    // -----------------------
    localparam int CELL_W = 16;
    localparam int CELL_H = 32;

    // -----------------------
    // 1. 스코어 위치 설정
    // -----------------------
    localparam int SCORE_X = 200;
    localparam int SCORE_Y = 32; 
    localparam int SCORE_CHARS = 5;

    // 기존 타이머/플레이어 위치
    localparam int TIMER_X = 320;
    localparam int TIMER_Y = 32;
    localparam int TIMER_CHARS = 5;
    localparam int TIMER_W = CELL_W * TIMER_CHARS;

    localparam int GAP = CELL_W;
    localparam int PLAYER_X = TIMER_X + TIMER_W + GAP;
    localparam int PLAYER_Y = 32;

    localparam int STATE_X = 320;
    localparam int STATE_Y = 64;
    localparam int STATE_MAX_CHARS = 11;

    // -----------------------
    // 2. 활성 영역 판별
    // -----------------------
    wire in_score  = (y >= SCORE_Y && y < SCORE_Y + CELL_H) && (x >= SCORE_X && x < SCORE_X + (CELL_W * SCORE_CHARS));
    wire in_timer  = (y >= TIMER_Y && y < TIMER_Y + CELL_H) && (x >= TIMER_X && x < TIMER_X + (CELL_W * TIMER_CHARS));
    wire in_player = (y >= PLAYER_Y && y < PLAYER_Y + CELL_H) && (x >= PLAYER_X && x < PLAYER_X + (CELL_W * 13));
    wire in_state  = (y >= STATE_Y && y < STATE_Y + CELL_H) && (x >= STATE_X && x < STATE_X + (CELL_W * STATE_MAX_CHARS));

    // 박스 영역 통합
    wire is_box = (in_score || in_timer || in_player || in_state);

    // -----------------------
    // 3. 로컬 오프셋 계산
    // -----------------------
    wire [9:0] x_rel = in_score  ? (x - SCORE_X)  :
                       in_timer  ? (x - TIMER_X)  :
                       in_player ? (x - PLAYER_X) :
                       in_state  ? (x - STATE_X)  : 10'd0;

    wire [9:0] y_rel = in_score  ? (y - SCORE_Y)  :
                       in_timer  ? (y - TIMER_Y)  :
                       in_player ? (y - PLAYER_Y) :
                       in_state  ? (y - STATE_Y)  : 10'd0;

    // -----------------------------------------------------------
    // [핵심 변경] 폰트 행(Row) 계산 (중앙 정렬 적용)
    // -----------------------------------------------------------
    // y_rel[4:1]은 0~15 범위를 가짐.
    // 여기서 4를 빼주면 글자가 화면상 8픽셀(4행) 아래로 내려가서 출력됨.
    // (음수가 되면 underflow로 큰 수가 되지만, Font ROM default가 0이라 빈 공간 처리됨 -> 안전함)
    
    wire [3:0] font_row = y_rel[4:1] - 4'd4; 
    wire [2:0] font_col = 3'd7 - x_rel[3:1];

    // -----------------------
    // 4. 문자 선택 로직
    // -----------------------
    logic [6:0] char_code;

    always_comb begin
        char_code = 7'h20; // 기본 space

        if (in_score) begin
            case ((x - SCORE_X) / CELL_W)
                0: char_code = {3'b011, 2'b00, score_p1}; // P1 점수
                1: char_code = 7'h20;
                2: char_code = 7'h3A; // :
                3: char_code = 7'h20;
                4: char_code = {3'b011, 2'b00, score_p2}; // P2 점수
                default: char_code = 7'h20;
            endcase
        end else if (in_timer) begin
            case ((x - TIMER_X) / CELL_W)
                0: char_code = {3'b011, min10};
                1: char_code = {3'b011, min1};
                2: char_code = 7'h3A;
                3: char_code = {3'b011, sec10};
                4: char_code = {3'b011, sec1};
                default: char_code = 7'h20;
            endcase
        end else if (in_player) begin
            case ((x - PLAYER_X) / CELL_W)
                0: char_code = 7'h50; 1: char_code = 7'h4C; 2: char_code = 7'h41;
                3: char_code = 7'h59; 4: char_code = 7'h45; 5: char_code = 7'h52;
                6: char_code = 7'h20;
                7: begin
                    if (wait_p1) char_code = 7'h31;
                    else if (wait_p2) char_code = 7'h32;
                    else char_code = 7'h2D;
                end
                8: char_code = 7'h20; 9: char_code = 7'h54; 10: char_code = 7'h55;
                11: char_code = 7'h52; 12: char_code = 7'h4E;
                default: char_code = 7'h20;
            endcase
        end else if (in_state) begin
            case (state)
                0: begin /* START GAME? */
                    case ((x - STATE_X) / CELL_W)
                        0: char_code = 7'h53; 1: char_code = 7'h54; 2: char_code = 7'h41;
                        3: char_code = 7'h52; 4: char_code = 7'h54; 5: char_code = 7'h20;
                        6: char_code = 7'h47; 7: char_code = 7'h41; 8: char_code = 7'h4D;
                        9: char_code = 7'h45; 10: char_code = 7'h3F;
                        default: char_code = 7'h20;
                    endcase
                end
                // ... (state 1~6 생략 - 기존과 동일) ...
                1: begin
                    case ((x - STATE_X) / CELL_W)
                        0: char_code = 7'h52; 1: char_code = 7'h45; 2: char_code = 7'h41;
                        3: char_code = 7'h44; 4: char_code = 7'h59; 5: char_code = 7'h3F;
                        default: char_code = 7'h20;
                    endcase
                end
                2: begin /* RUNNING */
                    case ((x - STATE_X) / CELL_W)
                        0: char_code = 7'h52; 1: char_code = 7'h55; 2: char_code = 7'h4E;
                        3: char_code = 7'h4E; 4: char_code = 7'h49; 5: char_code = 7'h4E; 6: char_code = 7'h47;
                        default: char_code = 7'h20;
                    endcase
                end
                3: begin /* PAUSE */
                    case ((x - STATE_X) / CELL_W)
                        0: char_code = 7'h50; 1: char_code = 7'h41; 2: char_code = 7'h55;
                        3: char_code = 7'h53; 4: char_code = 7'h45;
                        default: char_code = 7'h20;
                    endcase
                end
                4: begin /* TIME OVER */
                    case ((x - STATE_X) / CELL_W)
                        0: char_code = 7'h54; 1: char_code = 7'h49; 2: char_code = 7'h4D; 3: char_code = 7'h45;
                        4: char_code = 7'h20; 5: char_code = 7'h4F; 6: char_code = 7'h56; 7: char_code = 7'h45; 8: char_code = 7'h52;
                        default: char_code = 7'h20;
                    endcase
                end
                5: begin /* GAME END */
                    case ((x - STATE_X) / CELL_W)
                        0: char_code = 7'h47; 1: char_code = 7'h41; 2: char_code = 7'h4D; 3: char_code = 7'h45;
                        4: char_code = 7'h20; 5: char_code = 7'h45; 6: char_code = 7'h4E; 7: char_code = 7'h44;
                        default: char_code = 7'h20;
                    endcase
                end
                6: begin /* RESTART */
                    case ((x - STATE_X) / CELL_W)
                        0: char_code = 7'h52; 1: char_code = 7'h45; 2: char_code = 7'h53; 3: char_code = 7'h54;
                        4: char_code = 7'h41; 5: char_code = 7'h52; 6: char_code = 7'h54;
                        default: char_code = 7'h20;
                    endcase
                end
                default: char_code = 7'h20;
            endcase
        end
    end

    // =======================================================
    // 테두리(Outline) 생성 및 출력 로직
    // =======================================================
    
    // 1. 상/중/하 데이터를 모두 가져옵니다.
    wire [3:0] row_up   = font_row - 4'd1; 
    wire [3:0] row_down = font_row + 4'd1;

    logic [7:0] data_c; // 현재 줄 (Center)
    logic [7:0] data_u; // 윗 줄 (Up)
    logic [7:0] data_d; // 아랫 줄 (Down)

    Font_Rom U_Font_C ( .char_code(char_code), .row_addr(font_row), .row_data(data_c) );
    Font_Rom U_Font_U ( .char_code(char_code), .row_addr(row_up),   .row_data(data_u) );
    Font_Rom U_Font_D ( .char_code(char_code), .row_addr(row_down), .row_data(data_d) );

    // 2. 테두리(Border) 감지
    wire px_c = data_c[font_col];       // 나 자신
    wire px_u = data_u[font_col];       // 위
    wire px_d = data_d[font_col];       // 아래
    
    // 좌/우는 인덱스로 접근
    wire px_l = (font_col < 3'd7) ? data_c[font_col + 1] : 1'b0; // 왼쪽
    wire px_r = (font_col > 3'd0) ? data_c[font_col - 1] : 1'b0; // 오른쪽

    // 3. 픽셀 판정
    //    - is_main: 진짜 글자 부분
    //    - is_border: 글자가 아니지만 상하좌우 중 하나가 글자인 경우
    wire is_main   = px_c;
    wire is_border = (!px_c) && (px_u || px_d || px_l || px_r);

    // -------------------------------------------------------
    // 최종 출력 할당
    // -------------------------------------------------------
    assign is_text = is_box && (is_main || is_border);
    assign txt_rgb = is_main ? 12'hFFF : 12'h000; // 흰색 글씨 + 검은색 테두리

endmodule

// Back_Mem_Reader (unchanged)
module Back_Mem_Reader (
    input  logic        clk,
    input  logic [ 9:0] x,
    input  logic [ 9:0] y,
    input  logic [15:0] data_in,
    output logic [16:0] addr,
    output logic [11:0] rgb_out
);
    wire [8:0] x_small = {1'b0, x[9:1]};
    wire [8:0] y_small = {1'b0, y[9:1]};

    assign addr    = (y_small * 320) + x_small;
    assign rgb_out = {data_in[15:12], data_in[10:7], data_in[4:1]};
endmodule