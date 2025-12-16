`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Seoyu_Gwak -> Jiyun_Han (Organization)
// 
// Create Date	    : 2025/11/
// Design Name      : Main_Game_Master
// Module Name      : Game_Logic_Top
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Game Logic Top Module
//
// Revision 	    : 2025/12/01    Organize Top Module
//////////////////////////////////////////////////////////////////////////////////


module Game_Logic_Top (
    // Clock & Reset
    input  logic       clk,
    input  logic       rst,
    // [Input 1] Game_User_Btn
    input  logic       u_btn,            // Game Start / Ready
    input  logic       r_btn,            // Game Stop / Resume
    input  logic       l_btn,            // Game Restart
    // [Input 2] VGA Interface
    input  logic       die_en,
    input  logic [2:0] die_value,        // 1~6
    // [Output 1] Display Interface
    // 1-1 Timer
    output logic [3:0] sec0,             // Second 1
    output logic [3:0] sec1,             // Second 10
    output logic [3:0] min0,             // Minute 1
    output logic [3:0] min1,             // Minute 10
    // Player Piece Position
    output logic [5:0] p1_position,
    output logic [5:0] p2_position,
    // 1-3 Game Status & Turn Info
    output logic [2:0] play_state,       // IDLE / RUN / END...
    output logic       wait_p1,          // Player 1 Turn
    output logic       wait_p2,          // Player 2 Turn
    // score
    output logic [1:0] score_p1,
    output logic [1:0] score_p2,
    // [Output 2] I2C Interface
    output logic       i2c_show_signal,
    output logic [1:0] game_win,         // 0: Draw, 1: P1 Win, 2: P2 Win
    output logic       game_final,       // Entire Game End
    output logic [1:0] game_result,      // Final Winner
    output logic       up_signal_p1,     // P1 Ladder Up
    output logic       down_signal_p1,   // P1 Ladder Down
    output logic       up_signal_p2,     // P2 Ladder Up
    output logic       down_signal_p2,   // P2 Ladder Down
    output logic       restart
);


    /***********************************************
    // Reg & Wire
    ***********************************************/
    logic u_btn_tick, l_btn_tick, r_btn_tick;
    logic start;
    logic play_en;
    logic time_over;
    logic w_game_final;
    logic final_state;
    logic next_match;
    logic game_end;
    logic w_restart;

    assign restart = w_restart;
    assign game_final = w_game_final;


    /***********************************************
    // Button Decounce
    ***********************************************/
    btn_debounce U_BTN_DEBOUNCE_UP (
        .clk     (clk),
        .rst     (rst),
        .btn_in  (u_btn),
        .btn_tick(u_btn_tick)
    );

    btn_debounce U_BTN_DEBOUNCE_R (
        .clk     (clk),
        .rst     (rst),
        .btn_in  (r_btn),
        .btn_tick(r_btn_tick)
    );

    btn_debounce U_BTN_DEBOUNCE_L (
        .clk     (clk),
        .rst     (rst),
        .btn_in  (l_btn),
        .btn_tick(l_btn_tick)
    );


    /***********************************************
    // Entire Game Main Controller
    ***********************************************/
    entire_fsm U_ENTIRE_FSM (
        .clk       (clk),
        .rst       (rst),
        // FSM Input
        .u_btn_tick(u_btn_tick),
        .r_btn_tick(r_btn_tick),
        .l_btn_tick(l_btn_tick),
        .time_over (time_over),
        .game_final(w_game_final),
        // FSM Output
        .start     (start),
        .play_en   (play_en),
        .restart   (w_restart),
        .play_state(play_state)     // Display Print
    );


    /***********************************************
    // Timer
    ***********************************************/
    timer U_TIMER (
        .clk       (clk),
        .rst       (rst),
        //FSM Control
        .start     (start),         // From Top_FSM
        .play_en   (play_en),       // 1: Run, 0: Stop
        .game_final(w_game_final),  // End Game -> Stop Clock
        .restart   (w_restart),
        // Timer Val
        .sec0      (sec0),
        .sec1      (sec1),
        .min0      (min0),
        .min1      (min1),
        .time_over (time_over)
    );


    /***********************************************
    // Main Rule Engine
    ***********************************************/
    play_game_fsm U_PLAY_GAME_FSM (
        .clk            (clk),
        .rst            (rst),
        //FSM Controller
        .start          (start),
        .restart        (w_restart),
        .play_en        (play_en),
        // VGA Input Dice Interface
        .die_en         (die_en),
        .die_value      (die_value),        // 1~6
        //
        .final_state    (final_state),
        .next_match     (next_match),
        // Output -> Display Position
        .p1_position    (p1_position),
        .p2_position    (p2_position),
        // Output Turn Infomation -> Display
        .wait_p1        (wait_p1),
        .wait_p2        (wait_p2),
        // Win / Lose Infomation
        .game_end       (game_end),         // To Victory_Tracker
        .game_win       (game_win),         // To I2C, Victory_Tracker
        .i2c_show_signal(i2c_show_signal),
        .up_signal_p1   (up_signal_p1),
        .down_signal_p1 (down_signal_p1),
        .up_signal_p2   (up_signal_p2),
        .down_signal_p2 (down_signal_p2)
    );


    /***********************************************
    // Score Board
    ***********************************************/
    victory_tracker_fsm U_VICTORY_TRACKER_FSM (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .restart    (w_restart),
        .game_end   (game_end),      // Game_1 Finish
        .game_win   (game_win),      // 00: Draw, 01: P1 Win, 10: P2 Win
        .game_final (w_game_final),  // Finish (2 Point Reach)
        .final_state(final_state),
        .next_match (next_match),
        .game_result(game_result),   // 00: Draw, 01: P1 Win, 10: P2 Win -> I2C
        .score_p1   (score_p1),
        .score_p2   (score_p2)
    );



endmodule
