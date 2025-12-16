`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/26 17:49:02
// Design Name: 
// Module Name: play_game_fsm
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


module play_game_fsm(
    input  logic clk,         // 100MHz = 10ns period
    input  logic rst,
    //from entire_fsm 
    input  logic start, 
    input  logic restart,
    input  logic play_en,
    //from dice_logic
    input  logic die_en,
    input  logic [2:0] die_value, // 1~6
    // from victory tracker fsm
    input  logic final_state, // 유지신호
    input logic  next_match, 
    //fsm output
    //0~40
    output logic [5:0] p1_position, // 이 값이 화면에 떠야함 !!
    output logic [5:0] p2_position,

    output logic i2c_show_signal, // 비교끝나면 i2c로 전달
    output logic game_end, // to victory_tracker
    output logic [1:0] game_win, //to  i2c, victory_tracker
    // dice값 뱓을 준비중이란것을 나타냄
    output logic wait_p1, // to 화면
    output logic wait_p2,
    // 사다리
    output logic up_signal_p1,
    output logic down_signal_p1,
    output logic up_signal_p2,
    output logic down_signal_p2
    );



    typedef enum logic [3:0] {
        IDLE,
        NEW_MATCH,      // 0:0
        // P1->P2 순서
        WAIT_UPDATE_P1, // 주사위 값 들어오는거 기다림
        UPDATE_P1, // 들어온 주사위값 업그레이드
        WAIT_UPDATE_P2, // 주사위 값 들어오는거 기다림
        UPDATE_P2, // 들어온 주사위값 업그레이드
        COMPARE, // 업그레이드 된 값 비교
        I2C_UPDATE, // 업그레이드 된 값을 비교해서 전달
        CHECK_END, // Max로 온게 있나 체크
        END_CUR_MATCH, // Max로 온게 있어서 끝나면
        WAIT_RESTART
    } state;

    state cur_state, next_state;

    logic i2c_show_signal_reg, i2c_show_signal_next;
    logic game_end_reg , game_end_next;
    logic [1:0] game_win_reg, game_win_next;
    logic [5:0] p1_position_reg, p1_position_next;
    logic [5:0] p2_position_reg, p2_position_next;
    logic wait_p1_reg , wait_p1_next;
    logic wait_p2_reg , wait_p2_next;
   // logic [2:0] temp_die_value;
    logic clock_en , clock_en_reg , clock_en_next;
    logic clock_end_3s;
    // 사다리 
    logic up_en_reg_p1, up_en_next_p1;
    logic down_en_reg_p1 , down_en_next_p1; // 1tick
    logic up_en_reg_p2, up_en_next_p2;
    logic down_en_reg_p2 , down_en_next_p2; // 1tick

     // I2C 딜레이용 카운터 (3ms)
    localparam int I2C_DELAY_CYCLES = 300_000 - 1; // 3ms @ 100MHz
    logic [$clog2(I2C_DELAY_CYCLES+1)-1:0] i2c_cnt_reg, i2c_cnt_next;


    assign i2c_show_signal = i2c_show_signal_reg;
    assign game_end = game_end_reg;
    assign game_win = game_win_reg;
    assign p1_position = p1_position_reg;
    assign p2_position = p2_position_reg;
    assign wait_p1 = wait_p1_reg;
    assign wait_p2 = wait_p2_reg;

    assign clock_en = clock_en_reg;
    assign up_signal_p1 = up_en_reg_p1;
    assign down_signal_p1 = down_en_reg_p1;
    assign up_signal_p2 = up_en_reg_p2;
    assign down_signal_p2 = down_en_reg_p2;

    always_ff @( posedge clk or posedge rst ) begin 
        if(rst) begin
            cur_state <= IDLE;
            i2c_show_signal_reg <= 0;
            game_end_reg <= 0;
            game_win_reg <= 0;
            p1_position_reg <= 0;
            p2_position_reg <= 0;
            wait_p1_reg <=0;
            wait_p2_reg <=0;
            clock_en_reg <= 0;
            //
            up_en_reg_p1   <=0;
            down_en_reg_p1 <=0;
            up_en_reg_p2   <=0;
            down_en_reg_p2 <=0;
            i2c_cnt_reg          <= 0; 
        end else begin
            cur_state <= next_state;
            i2c_show_signal_reg <= i2c_show_signal_next;
            game_end_reg <= game_end_next;
            game_win_reg <= game_win_next;
            p1_position_reg <= p1_position_next;
            p2_position_reg <= p2_position_next;
            wait_p1_reg <=wait_p1_next;
            wait_p2_reg <=wait_p2_next;
            clock_en_reg <= clock_en_next;
            //
            up_en_reg_p1 <=up_en_next_p1;
            down_en_reg_p1 <=down_en_next_p1;
            up_en_reg_p2 <=up_en_next_p2;
            down_en_reg_p2 <=down_en_next_p2;
            i2c_cnt_reg          <= i2c_cnt_next; 
        end
    end


    always_comb begin
        next_state = cur_state;
        i2c_show_signal_next = i2c_show_signal_reg;
        game_end_next = 0; //1clk pulse
        game_win_next = game_win_reg;
        p1_position_next = p1_position_reg;
        p2_position_next = p2_position_reg;
        wait_p1_next = wait_p1_reg;
        wait_p2_next = wait_p2_reg;
        clock_en_next = clock_en_reg;
        up_en_next_p1 = up_en_reg_p1;
        down_en_next_p1 = down_en_reg_p1;
        up_en_next_p2 = up_en_reg_p2;
        down_en_next_p2 = down_en_reg_p2;
        i2c_cnt_next = i2c_cnt_reg;
        // start 누르면 new_match로가고 그안에서 로직 돌리고 싶음.....
        if(cur_state == IDLE) begin
            if(start) begin
                 next_state= NEW_MATCH ;
                 p1_position_next = 0;
                 p2_position_next = 0;
            end
        end// WAIT_RESTART : restart만 보면 됨 (play_en==0일때 들어오는 신호)
        else if (cur_state == WAIT_RESTART) begin
                if (restart) begin
                    next_state = IDLE;
                end
        end

        if(play_en==0) begin
            // play_en==0 는 그냥 이전 상태 전달,,, 아무것도X
        end else begin
            case (cur_state)
                NEW_MATCH : begin
                    next_state = WAIT_UPDATE_P1;
                    wait_p1_next = 1;
                end
                WAIT_UPDATE_P1 : begin
                    if(die_en) begin
                        next_state = UPDATE_P1;
                        wait_p1_next = 0;
                        clock_en_next =1; // clock 3초 start
                        //일단 값 넣고
                        p1_position_next = p1_position_reg + die_value; // 값같이
                        // 40 넘어가면 못넘어가게
                        if(p1_position_next >= 40) p1_position_next = 6'd40; // 40못넘어감!!                       
                    end
                end
                UPDATE_P1 : begin
                    // 바로 조절하면 화면에서 움직이는게 보이지 X
                    // wait(2s) 준뒤에 움직이도록!!!!

                    // 사다리 강제 이동~
                    if(clock_end_3s) begin // 1tick
                        clock_en_next = 0;
                        case (p1_position_reg)
                            //up
                            6'd3 : p1_position_next = 6'd10;
                            6'd8 : p1_position_next = 6'd17;
                            6'd23: p1_position_next = 6'd30;
                            //down
                            6'd11: p1_position_next = 6'd0;
                            6'd35: p1_position_next = 6'd32;
                            6'd26: p1_position_next = 6'd14;
                            default: p1_position_next = p1_position_reg;
                        endcase

                        case (p1_position_reg)
                            //up
                            6'd3 : up_en_next_p1 = 1'b1;
                            6'd8 : up_en_next_p1 = 1'b1;
                            6'd23: up_en_next_p1 = 1'b1;
                            default:  up_en_next_p1 = up_en_reg_p1;
                        endcase

                        case (p1_position_reg)
                            //down
                            6'd11: down_en_next_p1 = 1'b1;
                            6'd35: down_en_next_p1 = 1'b1;
                            6'd26: down_en_next_p1 = 1'b1;
                            default:  down_en_next_p1 = down_en_reg_p1;
                        endcase

                        next_state = WAIT_UPDATE_P2;
                        wait_p2_next = 1;
                    end                   
                end
                WAIT_UPDATE_P2 : begin
                    up_en_next_p1 = 1'b0;
                    down_en_next_p1 = 1'b0;

                    if(die_en) begin
                        next_state = UPDATE_P2;
                        wait_p2_next = 0; // dic 값들어오면 내리기
                        clock_en_next =1; // clock 3초 start
                        //일단 값 넣고
                        p2_position_next = p2_position_reg + die_value; 
                        // 40 넘어가면 못넘어가게
                        if(p2_position_next >= 40) p2_position_next = 6'd40; // 40못넘어감!!                       
                    end
                end
                UPDATE_P2 : begin
                    if(clock_end_3s) begin // 1tick
                        clock_en_next = 0;
                        case (p2_position_reg)
                            //up
                            6'd3 : p2_position_next = 6'd10;
                            6'd8 : p2_position_next = 6'd17;
                            6'd23: p2_position_next = 6'd30;
                            //down
                            6'd11: p2_position_next = 6'd0;
                            6'd35: p2_position_next = 6'd32;
                            6'd26: p2_position_next = 6'd14;
                            default: p2_position_next = p2_position_reg;
                        endcase

                         case (p2_position_reg)
                            //up
                            6'd3 : up_en_next_p2 = 1'b1;
                            6'd8 : up_en_next_p2 = 1'b1;
                            6'd23: up_en_next_p2 = 1'b1;
                            default:  up_en_next_p2 = up_en_reg_p2;
                        endcase

                        case (p2_position_reg)
                            //down
                            6'd11: down_en_next_p2 = 1'b1;
                            6'd35: down_en_next_p2 = 1'b1;
                            6'd26: down_en_next_p2 = 1'b1;
                            default:  down_en_next_p2 = down_en_reg_p2;
                        endcase

                        next_state = COMPARE;
                    end                   
                end
                COMPARE : begin
                    up_en_next_p2 = 1'b0;
                    down_en_next_p2 = 1'b0;
                    // compare하면서 i2c 신호 같이 넘겨줌
                    if(p1_position_reg==p2_position_reg) begin
                        game_win_next = 2'b00; 
                    end else if (p1_position_reg>p2_position_reg) begin
                        game_win_next = 2'b01; 
                    end else if (p1_position_reg<p2_position_reg) begin
                        game_win_next = 2'b10; 
                    end

                     // i2c 신호 겹치는 것 방지용 3ms delay
                    if (i2c_cnt_reg == I2C_DELAY_CYCLES) begin
                        i2c_cnt_next         = '0;      // 카운터 리셋
                        next_state           = I2C_UPDATE;
                        i2c_show_signal_next = 1'b1;    // 3ms 기다린 후 1펄스
                    end else begin
                        i2c_cnt_next = i2c_cnt_reg + 1;
                    end

                end

                I2C_UPDATE : begin
                    i2c_show_signal_next = 0; // 1clk
                    next_state = CHECK_END;
                end 
                CHECK_END : begin // max 값(40)도착있나 확인
                    if(p1_position_reg==6'd40 || p2_position_reg==6'd40) begin
                        next_state = END_CUR_MATCH;
                        game_end_next = 1;
                    end else begin // 다시 play1부터
                        next_state = WAIT_UPDATE_P1;
                        wait_p1_next = 1'b1;
                    end
                end
                END_CUR_MATCH : begin
                     if (final_state) begin
                        // 전체 매치 완전 종료
                        next_state = WAIT_RESTART;
                    end
                    else if (next_match) begin
                        // 아직 끝 아니고, victory FSM이 다음 판 하라고 알려줬을 때
                        next_state       = NEW_MATCH;
                        p1_position_next = 0;
                        p2_position_next = 0;
                    end
                    else begin
                        next_state = END_CUR_MATCH;
                    end          
                end
                //default: next_state = IDLE;
                
            endcase
        end

    end
    counter_3s U_CNT_3S (
        .clk(clk),           // 100MHz = 10ns period
        .rst(rst),
        .clock_en(clock_en),      // 1이면 counting
        .clock_end_3s(clock_end_3s)  // 3초마다 1clk pulse
    );

endmodule



module counter_3s (
    input  logic clk,           // 100MHz = 10ns period
    input  logic rst,
    input  logic clock_en,      // 1이면 counting
    output logic clock_end_3s  // 3초마다 1clk pulse
);

    //1초 = 100,000,000 clk (시뮬할 땐 줄여서 사용)
    localparam int MAX_COUNT = 20_000_000 - 1;
    // 테벤용
    //localparam int MAX_COUNT = 10000- 1;

    logic [$clog2(MAX_COUNT+1)-1:0] counter;
    logic [3:0]                     cnt_3s;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter       <= 0;
            cnt_3s       <= 0;
            clock_end_3s <= 1'b0;
        end else begin
            // 기본: 펄스는 0
            clock_end_3s <= 1'b0;

            if (!clock_en) begin
                // enable 내려가면 항상 내부 카운터 리셋
                counter <= 0;
                cnt_3s <= 0;
            end else begin
                // clock_en = 1일 때만 카운트
                if (counter == MAX_COUNT) begin
                    counter <= 0;
                    if (cnt_3s == 4'd2) begin
                        clock_end_3s <= 1'b1;  // 3초 후 펄스
                        cnt_3s       <= 0;
                    end else begin
                        cnt_3s <= cnt_3s + 1;
                    end
                end else begin
                    counter <= counter + 1;
                end
            end
        end
    end

endmodule


