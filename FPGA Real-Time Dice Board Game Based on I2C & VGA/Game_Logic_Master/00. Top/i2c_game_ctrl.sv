`timescale 1ns/1ps

// 고민.....i2c game_end/ game_final / restart 신호 사이
// 시간이 너무 짧으면 무시됨..
// test bench 돌렸을때
// repeat(5000) @(posedge clk); -> 무시됨...
// 솔직히 게임할때 restart와 game final or game end 사이에는 문제 없을것ㄱ 같은데
// game_end -> game_final 사이가 문제가 될 듯..
module I2C_Game_Ctrl (
    input  logic       clk,
    input  logic       rst,

    // 게임 쪽에서 들어오는 신호들
    input  logic       i2c_show_signal,   // play_game_fsm 에서 1clk 펄스
    input  logic [1:0] game_win,          // 00:무, 01:P1 우세, 10:P1 열세
    input  logic       game_final,        // victory_tracker_fsm 에서 펄스
    input  logic [1:0] game_result,       // 00:무, 01:P1 승, 10:P1 패
    input  logic       restart,           // 전체 리셋
    input  logic       up_signal_p1,         //사다리(tick)
    input  logic       down_signal_p1,
    input  logic       up_signal_p2,         //사다리(tick)
    input  logic       down_signal_p2,

    // I2C 라인
    output logic       SCL,
    inout  wire        SDA
    //
    
);

    
    localparam logic [6:0] P1_ADDR   = 7'b1010_101;  // player1
    localparam logic [6:0] P2_ADDR   = 7'b0101_010;  // player2

    localparam logic [7:0] REG0_ADDR = 8'h00;        // current_state
    localparam logic [7:0] REG1_ADDR = 8'h01;        // game_state
    localparam logic [7:0] REG2_ADDR = 8'h02;        // 사다리

    localparam logic [1:0] MODE_REG_WRITE = 2'b10;   // i2c_master 의 REG_WRITE 모드
    localparam logic [1:0] BURST_1BYTE    = 2'b00;   // 항상 1바이트만 씀

    // -----------------------------
    // i2c_master 연결 신호
    // -----------------------------
    logic        i2c_en;
    logic        start;
    logic        ready;
    logic        done;

    logic [1:0]  mode;
    logic [6:0]  slave_addr;
    logic [7:0]  reg_addr;
    logic [1:0]  burst_len;
    logic [31:0] tx_data;
 
  

    I2C_Master U_I2C_MASTER (
        .clk        (clk),
        .reset      (rst),

        .i2c_en     (i2c_en),
        .start      (start),
        .ready      (ready),
        .done       (done),

        .mode       (mode),
        .slave_addr (slave_addr),
        .reg_addr   (reg_addr),
        .burst_len  (burst_len),

        .tx_data    (tx_data),
        .rx_data    (),
        .tx_done    (),
        .rx_done    (),

        .SCL        (SCL),
        .SDA        (SDA)
    );

    // 항상 enable 켜두고, start만 펄스로 씀
    assign i2c_en = 1'b1;

    // -----------------------------
    // 이벤트 들어올 때 값 latch
    // -----------------------------
    // logic [1:0] game_win_lat, game_result_lat;

    // always_ff @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         game_win_lat    <= 2'b00;
    //         game_result_lat <= 2'b00;
    //     end else begin
    //         if (i2c_show_signal)
    //             game_win_lat <= game_win;

    //         if (game_final)
    //             game_result_lat <= game_result;
    //     end
    // end

    // -----------------------------
    // 쓸 값 미리 계산
    // -----------------------------
    logic [7:0] p1_reg0_val, p2_reg0_val;
    logic [7:0] p1_reg1_val, p2_reg1_val;
    logic [7:0] p1_reg2_val, p2_reg2_val;

    always_comb begin
        // reg0 : 현재 누가 앞서고 있는지
        p1_reg0_val = 8'd0;
        p2_reg0_val = 8'd0;

        case (game_win)
            2'b00: begin // P1 == P2
                p1_reg0_val = 8'd0;
                p2_reg0_val = 8'd0;
            end
            2'b01: begin // P1 > P2
                p1_reg0_val = 8'd1;
                p2_reg0_val = 8'd2;
            end
            2'b10: begin // P1 < P2
                p1_reg0_val = 8'd2;
                p2_reg0_val = 8'd1;
            end
            default: begin
                p1_reg0_val = 8'd0;
                p2_reg0_val = 8'd0;
            end
        endcase

        // reg1 : 매치 결과
        p1_reg1_val = 8'd0;
        p2_reg1_val = 8'd0;

        case (game_result)
            2'b00: begin // 무승부
                p1_reg1_val = 8'd1;
                p2_reg1_val = 8'd1;
            end
            2'b01: begin // P1 승
                p1_reg1_val = 8'd2;
                p2_reg1_val = 8'd3;
            end
            2'b10: begin // P1 패
                p1_reg1_val = 8'd3;
                p2_reg1_val = 8'd2;
            end
            default: begin
                p1_reg1_val = 8'd0;
                p2_reg1_val = 8'd0;
            end
        endcase

        // 사다리 레지스터
        p1_reg2_val = 8'd0;
        p2_reg2_val = 8'd0;

        if(up_signal_p1) p1_reg2_val=8'd2;
        if(up_signal_p2) p2_reg2_val=8'd2;
        if(down_signal_p1) p1_reg2_val=8'd1;
        if(down_signal_p2) p2_reg2_val=8'd1;
       

    end

    // -----------------------------
    // slave1 → slave2 순서 FSM
    // -----------------------------
    typedef enum logic [5:0] {
        ST_IDLE,

        // i2c_show_signal (reg0)
        ST_SHOW_P1_WAIT,
        ST_SHOW_P2_WAIT,
        ST_SHOW_P1_WR,
        ST_SHOW_P2_WR,        

        // game_final (reg1)
        ST_FINAL_P1_WAIT,
        ST_FINAL_P2_WAIT,
        ST_FINAL_P1_WR,
        ST_FINAL_P2_WR,       

        // restart (모두 0으로)
        ST_RST_P1_REG0_WAIT,
        ST_RST_P1_REG1_WAIT,
        ST_RST_P1_REG0_WR,
        ST_RST_P1_REG1_WR,    

        //ST_RST_P2_REG0_WAIT,  
        ST_RST_P2_REG0_WR,    
        ST_RST_P2_REG1_WAIT,
        ST_RST_P2_REG1_WR,    
        ST_RST_P2_WAIT_END,    

        //사다리
        ST_LADDER_P1_REG2_WAIT,
        ST_LADDER_P2_REG2_WAIT,
        ST_LADDER_P1_REG2_WR,
        ST_LADDER_P2_REG2_WR

    } ctrl_state_t;

    ctrl_state_t cur_state, next_state;

    logic        start_reg, start_next;
    logic [1:0]  mode_reg, mode_next;
    logic [6:0]  slave_addr_reg, slave_addr_next;
    logic [7:0]  reg_addr_reg, reg_addr_next;
    logic [1:0]  burst_len_reg, burst_len_next;
    logic [31:0] tx_data_reg, tx_data_next;

    assign start      = start_reg;
    assign mode       = mode_reg;
    assign slave_addr = slave_addr_reg;
    assign reg_addr   = reg_addr_reg;
    assign burst_len  = burst_len_reg;
    assign tx_data    = tx_data_reg;

    // 상태 레지스터
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cur_state       <= ST_IDLE;
            start_reg       <= 1'b0;
            mode_reg        <= MODE_REG_WRITE;
            slave_addr_reg  <= 7'd0;
            reg_addr_reg    <= 8'd0;
            burst_len_reg   <= BURST_1BYTE;
            tx_data_reg     <= 32'd0;
        end else begin
            cur_state       <= next_state;
            start_reg       <= start_next;
            mode_reg        <= mode_next;
            slave_addr_reg  <= slave_addr_next;
            reg_addr_reg    <= reg_addr_next;
            burst_len_reg   <= burst_len_next;
            tx_data_reg     <= tx_data_next;
        end
    end

    // 조합 논리
    always_comb begin
        next_state       = cur_state;

        // 기본값: 설정 유지, start는 기본 0 (펄스용)
        start_next       = 1'b0;
        mode_next        = mode_reg;
        slave_addr_next  = slave_addr_reg;
        reg_addr_next    = reg_addr_reg;
        burst_len_next   = burst_len_reg;
        tx_data_next     = tx_data_reg;

        case (cur_state)

            // ---------------- ST_IDLE ----------------
            ST_IDLE: begin
                // 항상 1바이트 + REG_WRITE
                mode_next      = MODE_REG_WRITE;
                burst_len_next = BURST_1BYTE;

                // 우선순위: restart > game_final > i2c_show_signal > 사다리; // 겹치지 않는!!
                if (restart) begin
                    // P1 reg0 = 0
                    slave_addr_next = P1_ADDR;
                    reg_addr_next   = REG0_ADDR;
                    tx_data_next    = {8'd0, 24'd0};    // 상위 바이트에 0
                    next_state = ST_RST_P1_REG0_WR;

                end else if (game_final) begin
                    // P1 reg1 = p1_reg1_val
                    slave_addr_next = P1_ADDR;
                    reg_addr_next   = REG1_ADDR;
                    tx_data_next    = {p1_reg1_val, 24'd0};
                    next_state = ST_FINAL_P1_WR;


                end else if (i2c_show_signal) begin
                    // P1 reg0 = p1_reg0_val
                    slave_addr_next = P1_ADDR;
                    reg_addr_next   = REG0_ADDR;
                    tx_data_next    = {p1_reg0_val, 24'd0};
                    next_state = ST_SHOW_P1_WR;
                end else if (up_signal_p1 || down_signal_p1) begin 
                    slave_addr_next = P1_ADDR;
                    reg_addr_next   = REG2_ADDR;
                    tx_data_next    = {p1_reg2_val, 24'd0};
                    next_state = ST_LADDER_P1_REG2_WR;
                end else if (up_signal_p2 || down_signal_p2) begin 
                    slave_addr_next = P2_ADDR;
                    reg_addr_next   = REG2_ADDR;
                    tx_data_next    = {p2_reg2_val, 24'd0};
                    next_state = ST_LADDER_P2_REG2_WR;
                end
            end

            // --------- i2c_show_signal 경로 (reg0) ----------

            ST_SHOW_P1_WR : begin
                if (ready) begin
                    start_next = 1'b1;
                    next_state = ST_SHOW_P1_WAIT;
                end
            end
            ST_SHOW_P1_WAIT: begin
                if (done) begin
                    // 이제 slave2 (P2) reg0 쓰기
                    slave_addr_next = P2_ADDR;
                    reg_addr_next   = REG0_ADDR;
                    tx_data_next    = {p2_reg0_val, 24'd0};
                    next_state = ST_SHOW_P2_WR;
                end
            end

            ST_SHOW_P2_WR : begin
                if(ready) begin
                    start_next = 1'b1;
                    next_state = ST_SHOW_P2_WAIT;
                end
            end


            ST_SHOW_P2_WAIT: begin
                if (done) begin
                    next_state = ST_IDLE;
                end
            end

            // --------- game_final 경로 (reg1) ----------

            ST_FINAL_P1_WR : begin
                if (ready) begin
                    start_next = 1'b1;
                    next_state = ST_FINAL_P1_WAIT;
                end
            end
            
            ST_FINAL_P1_WAIT: begin
                if (done) begin
                    // P2 reg1
                    slave_addr_next = P2_ADDR;
                    reg_addr_next   = REG1_ADDR;
                    tx_data_next    = {p2_reg1_val, 24'd0};
                    next_state = ST_FINAL_P2_WR;
                end
            end

            ST_FINAL_P2_WR : begin
                if(ready) begin
                    start_next = 1'b1;
                    next_state = ST_FINAL_P2_WAIT;
                end
               
            end

            ST_FINAL_P2_WAIT: begin
                if (done) begin
                    next_state = ST_IDLE;
                end
            end

            // --------- restart 경로 (모두 0으로) ----------
            //---------p1
            ST_RST_P1_REG0_WR : begin
                if (ready) begin
                        start_next = 1'b1;
                        next_state = ST_RST_P1_REG0_WAIT;
                    end
            end


            ST_RST_P1_REG0_WAIT: begin
                if (done) begin
                    // P1 reg1 = 0
                    slave_addr_next = P1_ADDR;
                    reg_addr_next   = REG1_ADDR;
                    tx_data_next    = {8'd0, 24'd0};
                    next_state = ST_RST_P1_REG1_WR;
                end
            end

            ST_RST_P1_REG1_WR : begin
                if(ready) begin
                    start_next = 1'b1;
                    next_state = ST_RST_P1_REG1_WAIT;
                end
                
            end
            ST_RST_P1_REG1_WAIT: begin
                if (done) begin
                    // P2 reg0 = 0
                    slave_addr_next = P2_ADDR;
                    reg_addr_next   = REG0_ADDR;
                    tx_data_next    = {8'd0, 24'd0};
                    next_state = ST_RST_P2_REG0_WR;
                end
            end
            //-------------p2
            ST_RST_P2_REG0_WR : begin
                if(ready) begin
                    start_next = 1'b1;
                    next_state = ST_RST_P2_REG1_WAIT;
                end
                
            end
            ST_RST_P2_REG1_WAIT: begin
                if (done) begin
                    // P2 reg1 = 0
                    slave_addr_next = P2_ADDR;
                    reg_addr_next   = REG1_ADDR;
                    tx_data_next    = {8'd0, 24'd0};
                    next_state =  ST_RST_P2_REG1_WR;
                    
                end
            end
            ST_RST_P2_REG1_WR : begin
                if(ready) begin
                    start_next = 1'b1;
                    next_state = ST_RST_P2_WAIT_END;
                end
            end

            ST_RST_P2_WAIT_END: begin
                if (done) begin
                    next_state = ST_IDLE;
                end
            end



            //-------------------사다리------------------------
            ST_LADDER_P1_REG2_WR : begin
                if (ready) begin
                    start_next = 1'b1;
                    next_state = ST_LADDER_P1_REG2_WAIT;
                end
            end

            ST_LADDER_P1_REG2_WAIT : begin
                if (done) begin
                    next_state = ST_IDLE;
                end
            end
            ST_LADDER_P2_REG2_WR : begin
                if (ready) begin
                    start_next = 1'b1;
                    next_state = ST_LADDER_P2_REG2_WAIT;
                end
            end

            ST_LADDER_P2_REG2_WAIT : begin
                if (done) begin
                    next_state = ST_IDLE;
                end
            end


            default: begin
                next_state = ST_IDLE;
            end
        endcase
    end

endmodule
