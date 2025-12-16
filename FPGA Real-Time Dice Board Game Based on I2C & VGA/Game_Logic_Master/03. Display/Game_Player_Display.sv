`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/12/01
// Design Name      : 
// Module Name      : Game_Piece_Display
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Game Piece Display
//
// Revision 	    : 2025/12/02    Fix it to walk around.
//                                  Added ladder motion
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module Game_Piece_Display (
    // Clock & Reset
    input  logic       iClk,
    input  logic       iRst,
    // Display Coordinates
    input  logic [9:0] iX,
    input  logic [9:0] iY,
    // Game Logic Input Position Data
    input  logic [5:0] iP1_Pos,
    input  logic [5:0] iP2_Pos,
    // Output Player Is
    output logic       oIs_P1,
    output logic       oIs_P2
);


    /***********************************************
    // Motion Controller
    ***********************************************/
    logic [9:0] p1_draw_x, p1_draw_y;
    logic [9:0] p2_draw_x, p2_draw_y;
    logic [5:0] p1_anim_pos, p2_anim_pos;

    Piece_Motion_Ctrl U_P1_MOTION (
        .iClk        (iClk),
        .iRst        (iRst),
        .iTarget_Pos (iP1_Pos),
        .oDraw_X     (p1_draw_x),
        .oDraw_Y     (p1_draw_y),
        .oCurrent_Pos(p1_anim_pos)
    );

    Piece_Motion_Ctrl U_P2_MOTION (
        .iClk        (iClk),
        .iRst        (iRst),
        .iTarget_Pos (iP2_Pos),
        .oDraw_X     (p2_draw_x),
        .oDraw_Y     (p2_draw_y),
        .oCurrent_Pos(p2_anim_pos)
    );


    /***********************************************
    // Display Position
    ***********************************************/
    logic [9:0] cX1, cY1;
    logic [9:0] cX2, cY2;
    localparam OFFSET = 8;
    localparam SIZE = 10;

    always_comb begin
        int diff_x, diff_y;
        diff_x = (p1_draw_x > p2_draw_x) ? (p1_draw_x - p2_draw_x) : (p2_draw_x - p1_draw_x);
        diff_y = (p1_draw_y > p2_draw_y) ? (p1_draw_y - p2_draw_y) : (p2_draw_y - p1_draw_y);

        // Same Position
        if (diff_x < 5 && diff_y < 5) begin
            cX1 = p1_draw_x - OFFSET;
            cY1 = p1_draw_y - OFFSET;
            cX2 = p2_draw_x + OFFSET;
            cY2 = p2_draw_y + OFFSET;
        end else begin
            cX1 = p1_draw_x;
            cY1 = p1_draw_y;
            cX2 = p2_draw_x;
            cY2 = p2_draw_y;
        end
    end

    always_comb begin
        // Player 1
        if (iX >= cX1 - SIZE && iX <= cX1 + SIZE &&
            iY >= cY1 - SIZE && iY <= cY1 + SIZE)
            oIs_P1 = 1;
        else oIs_P1 = 0;

        // Player 2
        if (iX >= cX2 - SIZE && iX <= cX2 + SIZE &&
            iY >= cY2 - SIZE && iY <= cY2 + SIZE)
            oIs_P2 = 1;
        else oIs_P2 = 0;
    end

endmodule


/***********************************************
// Piece_Motion_Controller
***********************************************/
module Piece_Motion_Ctrl (
    input logic iClk,
    input logic iRst,
    input logic [5:0] iTarget_Pos,
    output logic [9:0] oDraw_X,
    output logic [9:0] oDraw_Y,
    output logic [5:0] oCurrent_Pos
);


    /***********************************************
    // Board Table (0~40)
    ***********************************************/
    function automatic void get_coord(
        input logic [5:0] pos, output logic [9:0] x, output logic [9:0] y);
        case (pos)
            6'd0:    {x, y} = {10'd88, 10'd220};
            6'd1:    {x, y} = {10'd88, 10'd264};
            6'd2:    {x, y} = {10'd88, 10'd308};
            6'd3:    {x, y} = {10'd88, 10'd352};
            6'd4:    {x, y} = {10'd88, 10'd396};
            6'd5:    {x, y} = {10'd88, 10'd440};
            6'd6:    {x, y} = {10'd132, 10'd440};
            6'd7:    {x, y} = {10'd177, 10'd440};
            6'd8:    {x, y} = {10'd177, 10'd396};
            6'd9:    {x, y} = {10'd177, 10'd352};
            6'd10:   {x, y} = {10'd177, 10'd308};
            6'd11:   {x, y} = {10'd177, 10'd264};
            6'd12:   {x, y} = {10'd177, 10'd220};
            6'd13:   {x, y} = {10'd222, 10'd220};
            6'd14:   {x, y} = {10'd267, 10'd220};
            6'd15:   {x, y} = {10'd267, 10'd264};
            6'd16:   {x, y} = {10'd267, 10'd308};
            6'd17:   {x, y} = {10'd267, 10'd352};
            6'd18:   {x, y} = {10'd267, 10'd396};
            6'd19:   {x, y} = {10'd267, 10'd440};
            6'd20:   {x, y} = {10'd312, 10'd440};
            6'd21:   {x, y} = {10'd358, 10'd440};
            6'd22:   {x, y} = {10'd358, 10'd396};
            6'd23:   {x, y} = {10'd358, 10'd352};
            6'd24:   {x, y} = {10'd358, 10'd308};
            6'd25:   {x, y} = {10'd358, 10'd264};
            6'd26:   {x, y} = {10'd358, 10'd220};
            6'd27:   {x, y} = {10'd403, 10'd220};
            6'd28:   {x, y} = {10'd449, 10'd220};
            6'd29:   {x, y} = {10'd449, 10'd264};
            6'd30:   {x, y} = {10'd449, 10'd308};
            6'd31:   {x, y} = {10'd449, 10'd352};
            6'd32:   {x, y} = {10'd449, 10'd396};
            6'd33:   {x, y} = {10'd449, 10'd440};
            6'd34:   {x, y} = {10'd493, 10'd440};
            6'd35:   {x, y} = {10'd539, 10'd440};
            6'd36:   {x, y} = {10'd539, 10'd396};
            6'd37:   {x, y} = {10'd539, 10'd352};
            6'd38:   {x, y} = {10'd539, 10'd308};
            6'd39:   {x, y} = {10'd539, 10'd264};
            6'd40:   {x, y} = {10'd539, 10'd220};
            default: {x, y} = {10'd0, 10'd0};
        endcase
    endfunction


    /***********************************************
    // Movement_Logic
    ***********************************************/
    logic [5:0] curr_pos_reg;
    logic [9:0] curr_x_reg, curr_y_reg;
    logic [9:0] dest_x_reg, dest_y_reg;

    logic [5:0] curr_pos_next;
    logic [9:0] curr_x_next, curr_y_next;
    logic [9:0] dest_x_next, dest_y_next;

    assign oCurrent_Pos = curr_pos_reg;
    assign oDraw_X      = curr_x_reg;
    assign oDraw_Y      = curr_y_reg;

    // Movement Speed Control
    logic [17:0] speed_cnt;
    logic        move_tick;
    localparam SPEED_VAL = 18'd50_000;

    always_ff @(posedge iClk) begin
        if (iRst) begin
            speed_cnt <= 0;
            move_tick <= 0;
        end else begin
            if (speed_cnt >= SPEED_VAL) begin
                speed_cnt <= 0;
                move_tick <= 1;
            end else begin
                speed_cnt <= speed_cnt + 1;
                move_tick <= 0;
            end
        end
    end


    /***********************************************
    // FSM 
    ***********************************************/
    typedef enum logic [1:0] {
        IDLE,
        CALC_NEXT,
        SLIDING
    } anim_state_t;

    anim_state_t state, state_next;

    // Ladder Detect Function
    function automatic logic is_special_move(input logic [5:0] from,
                                             input logic [5:0] to);
        // Ladder
        if (from == 3 && to == 10) return 1;
        if (from == 8 && to == 17) return 1;
        if (from == 23 && to == 30) return 1;
        // Snake
        if (from == 11 && to == 0) return 1;
        if (from == 35 && to == 32) return 1;
        if (from == 26 && to == 14) return 1;
        return 0;
    endfunction

    // Current State Update
    always_ff @(posedge iClk) begin
        if (iRst) begin
            state                    <= IDLE;
            curr_pos_reg             <= 0;
            {curr_x_reg, curr_y_reg} <= {10'd88, 10'd220};  // Start Pos (0)
            {dest_x_reg, dest_y_reg} <= {10'd88, 10'd220};
        end else begin
            state                    <= state_next;
            curr_pos_reg             <= curr_pos_next;
            {curr_x_reg, curr_y_reg} <= {curr_x_next, curr_y_next};
            {dest_x_reg, dest_y_reg} <= {dest_x_next, dest_y_next};
        end
    end

    // Next State Decision
    always_comb begin
        state_next                 = state;
        curr_pos_next              = curr_pos_reg;
        {curr_x_next, curr_y_next} = {curr_x_reg, curr_y_reg};
        {dest_x_next, dest_y_next} = {dest_x_reg, dest_y_reg};

        case (state)
            IDLE: begin
                if (curr_pos_reg != iTarget_Pos) begin
                    state_next = CALC_NEXT;
                end
            end

            CALC_NEXT: begin
                // Ladder -> Diagonal movement
                if (is_special_move(curr_pos_reg, iTarget_Pos)) begin
                    curr_pos_next = iTarget_Pos;
                    get_coord(iTarget_Pos, dest_x_next, dest_y_next);
                end  // Normal Move
                else if (curr_pos_reg < iTarget_Pos) begin
                    // Front 1
                    curr_pos_next = curr_pos_reg + 1;
                    get_coord(curr_pos_reg + 1, dest_x_next, dest_y_next);
                end else if (curr_pos_reg > iTarget_Pos) begin
                    // Back 1 // no use
                    curr_pos_next = curr_pos_reg - 1;
                    get_coord(curr_pos_reg - 1, dest_x_next, dest_y_next);
                end

                state_next = SLIDING;
            end

            SLIDING: begin
                if (move_tick) begin
                    // Move X
                    if (curr_x_reg < dest_x_reg) begin
                        curr_x_next = curr_x_reg + 1;
                    end else if (curr_x_reg > dest_x_reg) begin
                        curr_x_next = curr_x_reg - 1;
                    end

                    // Move Y
                    if (curr_y_reg < dest_y_reg) begin
                        curr_y_next = curr_y_reg + 1;
                    end else if (curr_y_reg > dest_y_reg) begin
                        curr_y_next = curr_y_reg - 1;
                    end

                    // X, Y Detect
                    if ((curr_x_reg == dest_x_reg || (curr_x_reg > dest_x_reg ? curr_x_reg - dest_x_reg < 2 : dest_x_reg - curr_x_reg < 2)) && 
                            (curr_y_reg == dest_y_reg || (curr_y_reg > dest_y_reg ? curr_y_reg - dest_y_reg < 2 : dest_y_reg - curr_y_reg < 2))) begin

                        // Corrext
                        curr_x_next = dest_x_reg;
                        curr_y_next = dest_y_reg;

                        if (curr_pos_reg == iTarget_Pos)
                            state_next = IDLE;  // Destination
                        else state_next = CALC_NEXT;  // Go Continue
                    end
                end
            end
        endcase
    end

endmodule

