`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/27 02:15:05
// Design Name: 
// Module Name: i2c_master
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

module I2C_Master (
    input      clk,
    input      reset,
    input      i2c_en,
    input      start,
    output reg ready,
    output reg done,

    input [1:0] mode,        // 00:Write, 01:Read, 10:RegWrite, 11:RegRead
    input [6:0] slave_addr,  //player1 : 7'b1010_101 , player2 : 7'b0101_010
    input [7:0] reg_addr,
    input [1:0] burst_len,   // 00:1B, 01:2B, 10:3B, 11:4B -> 00만사용!

    input      [31:0] tx_data,  // up to 4 bytes -> 상위 8bit만 !!
    output reg [31:0] rx_data,  // 
    output reg        tx_done,
    output reg        rx_done,

    output SCL,
    inout  SDA
);

    localparam integer FCOUNT = 500;  // START/STOP delay용

    //-------------------------------------------------------------
    // 모드 정의
    //-------------------------------------------------------------
    typedef enum logic [1:0] {
        WRITE_ONLY = 2'b00,
        READ_ONLY  = 2'b01,
        REG_WRITE  = 2'b10,
        REG_READ   = 2'b11
    } mode_t;

    mode_t mode_sel;
    assign mode_sel = mode_t'(mode);

    logic slave_addr_rw;
    assign slave_addr_rw = (mode_sel == READ_ONLY) ? 1'b1 : 1'b0; // 처음 addr
    // read only말고는 처음에는 0보내야함

    //-------------------------------------------------------------
    // FSM 상태 정의
    //-------------------------------------------------------------
    typedef enum logic [4:0] {
        IDLE,
        START1,
        START2,
        ADDR_W,
        ACK_ADDR_W,
        REG_ADDR,
        ACK_REG,
        WRITE_BYTE,
        ACK_WRITE,
        REP_START1,
        REP_START2,
        REP_START3,
        REP_START4,
        ADDR_R,
        ACK_ADDR_R,
        READ_BYTE,
        READ_HOLD,
        ACK_READ,
        NACK_READ,
        STOP1,
        STOP2,
        STOP3
    } state_t;

    state_t state, state_next;

    //-------------------------------------------------------------
    // 내부 레지스터
    //-------------------------------------------------------------
    reg [7:0] temp_slave_addr_reg, temp_slave_addr_next;
    reg [7:0] temp_slave_reg_reg, temp_slave_reg_next;
    reg [31:0] temp_tx_data_reg, temp_tx_data_next;
    reg [7:0] temp_rx_data_reg, temp_rx_data_next;
    reg [3:0] bit_counter_reg, bit_counter_next;
    reg [2:0] slv_count_reg, slv_count_next;
    reg [1:0] burst_len_reg, burst_len_next;
    reg write_ack_reg, write_ack_next;
    reg read, read_next;
    reg tx_done_reg, tx_done_next;
    reg rx_done_reg, rx_done_next;
    reg [31:0] rx_data_reg, rx_data_next;
    reg [$clog2(FCOUNT)-1:0] sclk_counter_reg, sclk_counter_next;

    // SCL 관련
    reg tick_sample;
    reg scl_en;
    reg start_stop_scl;
    reg data_ack_scl;

    // SDA 관련 (원래 스타일 유지)
    reg sda_en;
    reg master_o_data;

    assign SCL = scl_en ? data_ack_scl : start_stop_scl;

    assign SDA = sda_en ? master_o_data : 1'bz;

    // 출력
    assign tx_done = tx_done_reg;
    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    //-------------------------------------------------------------
    // SCLK 동기화
    //-------------------------------------------------------------
    reg sclk_sync0, sclk_sync1;
    wire sclk_rising = sclk_sync0 & ~sclk_sync1;
    wire sclk_falling = ~sclk_sync0 & sclk_sync1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_sync0 <= 1;
            sclk_sync1 <= 1;
        end else begin
            sclk_sync0 <= SCL;
            sclk_sync1 <= sclk_sync0;
        end
    end

    //-------------------------------------------------------------
    // FSM 상태 레지스터
    //-------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state               <= IDLE;
            sclk_counter_reg    <= 0;
            temp_tx_data_reg    <= 0;
            temp_slave_addr_reg <= 0;
            temp_slave_reg_reg  <= 0;
            bit_counter_reg     <= 0;
            slv_count_reg       <= 0;
            burst_len_reg       <= 0;
            tx_done_reg         <= 0;
            rx_done_reg         <= 0;
            write_ack_reg       <= 1'bz;
            read                <= 0;
            rx_data_reg         <= 0;
            temp_rx_data_reg    <= 0;
        end else begin
            state               <= state_next;
            sclk_counter_reg    <= sclk_counter_next;
            temp_tx_data_reg    <= temp_tx_data_next;
            temp_slave_addr_reg <= temp_slave_addr_next;
            temp_slave_reg_reg  <= temp_slave_reg_next;
            bit_counter_reg     <= bit_counter_next;
            slv_count_reg       <= slv_count_next;
            burst_len_reg       <= burst_len_next;
            tx_done_reg         <= tx_done_next;
            rx_done_reg         <= rx_done_next;
            write_ack_reg       <= write_ack_next;
            read                <= read_next;
            rx_data_reg         <= rx_data_next;
            temp_rx_data_reg    <= temp_rx_data_next;
        end
    end

    //-------------------------------------------------------------
    // FSM 조합 논리
    //-------------------------------------------------------------
    always @(*) begin
        state_next           = state;
        sclk_counter_next    = sclk_counter_reg;
        temp_tx_data_next    = temp_tx_data_reg;
        temp_rx_data_next    = temp_rx_data_reg;
        temp_slave_addr_next = temp_slave_addr_reg;
        temp_slave_reg_next  = temp_slave_reg_reg;
        bit_counter_next     = bit_counter_reg;
        slv_count_next       = slv_count_reg;
        burst_len_next       = burst_len_reg;
        tx_done_next         = 0;
        rx_done_next         = 0;
        write_ack_next       = write_ack_reg;
        read_next            = read;
        ready                = 0;
        done                 = 0;
        rx_data_next         = rx_data_reg;

        scl_en               = 0;
        start_stop_scl       = 1;
        sda_en               = 1;
        master_o_data        = 1;

        case (state)
            //-----------------------------------------------------
            IDLE: begin
                master_o_data = 1'b1;
                ready = 1;
                if (start && i2c_en) begin
                    temp_slave_addr_next = {slave_addr, slave_addr_rw};
                    temp_slave_reg_next  = reg_addr;
                    temp_tx_data_next    = tx_data;
                    burst_len_next       = burst_len;

                    slv_count_next       = 0;
                    bit_counter_next     = 0;
                    state_next           = START1;
                end
            end

            //-----------------------------------------------------
            START1: begin
                master_o_data = 0;
                if (sclk_counter_reg == FCOUNT - 1) begin
                    state_next        = START2;
                    sclk_counter_next = 0;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end

            START2: begin
                master_o_data  = 1'b0;
                start_stop_scl = 1'b0;
                if (sclk_counter_reg == FCOUNT - 1) begin
                    sclk_counter_next = 0;
                    state_next        = ADDR_W;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end

            //-----------------------------------------------------
            ADDR_W: begin
                scl_en = 1;
                master_o_data = temp_slave_addr_reg[7];
                if (sclk_falling) begin
                    //failling 에서 data change
                    temp_slave_addr_next = {temp_slave_addr_reg[6:0], 1'b0};
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        state_next       = ACK_ADDR_W;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end

            ACK_ADDR_W: begin
                scl_en = 1;
                sda_en = 0;
                if (sclk_rising) write_ack_next = SDA;

                if (sclk_falling && (write_ack_reg == 0)) begin  //ack
                    state_next = (mode_sel == REG_READ || mode_sel == REG_WRITE)
                               ? REG_ADDR : WRITE_BYTE;
                end else if (sclk_falling && (write_ack_reg == 1'b1))
                    state_next = STOP1;  // nack
                else if (sclk_falling && (write_ack_reg === 1'bz))
                    state_next = STOP1;  // 버그 detect용

            end

            //-----------------------------------------------------
            REG_ADDR: begin
                scl_en = 1;
                master_o_data = temp_slave_reg_reg[7];
                if (sclk_falling) begin
                    temp_slave_reg_next = {temp_slave_reg_reg[6:0], 1'b0};
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        state_next       = ACK_REG;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end

            ACK_REG: begin
                scl_en = 1;
                sda_en = 0;
                if (sclk_rising) write_ack_next = SDA;

                if (sclk_falling && write_ack_reg == 0)  //ack 
                    state_next = (mode_sel == REG_READ) ? REP_START1 : WRITE_BYTE;
                else if (sclk_falling && (write_ack_reg == 1'b1))
                    state_next = STOP1;  // nack
                else if (sclk_falling && (write_ack_reg === 1'bz))
                    state_next = STOP1;  // 버그 detect용


            end

            //-----------------------------------------------------
            WRITE_BYTE: begin
                scl_en = 1;
                master_o_data = temp_tx_data_reg[31 - (slv_count_reg*8) - bit_counter_reg];
                if (sclk_falling) begin
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        slv_count_next   = slv_count_reg + 1;
                        state_next       = ACK_WRITE;
                        tx_done_next     = 1;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end

            ACK_WRITE: begin
                scl_en = 1;
                sda_en = 0;  // z
                if (sclk_rising) write_ack_next = SDA;

                if (sclk_falling && write_ack_reg == 0)  //ack
                    state_next = (slv_count_reg < burst_len_reg + 1) ? WRITE_BYTE : STOP1;
                else if (sclk_falling && (write_ack_reg == 1'b1))
                    state_next = STOP1;  // nack
                else if (sclk_falling && (write_ack_reg === 1'bz))
                    state_next = STOP1;  // 버그 detect용
            end

            //-----------------------------------------------------
            //-----------------------------------------------------ㄴ
            // Repeated START

            // 1단계: SCL low, SDA high
            REP_START1: begin
                scl_en         = 1'b0;  // data_ack_scl off
                start_stop_scl = 1'b0;  // SCL = 0
                sda_en         = 1'b1;
                master_o_data  = 1'b1;  // SDA = 1

                if (sclk_counter_reg == FCOUNT - 1) begin
                    sclk_counter_next    = 0;
                    state_next           = REP_START2;
                    // 읽기용 주소 준비
                    temp_slave_addr_next = {slave_addr, 1'b1};
                    bit_counter_next     = 0;

                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end

            // 2단계: SCL high, SDA high (plateau)
            REP_START2: begin
                scl_en         = 1'b0;
                start_stop_scl = 1'b1;  // SCL = 1
                sda_en         = 1'b1;
                master_o_data  = 1'b1;  // SDA = 1 그대로

                if (sclk_counter_reg == FCOUNT - 1) begin
                    sclk_counter_next = 0;
                    state_next        = REP_START3;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end

            // 3단계: SCL high 유지, SDA 1 -> 0 
            // (★ START 조건)
            REP_START3: begin
                scl_en         = 1'b0;
                start_stop_scl = 1'b1;  // 여전히 HIGH
                sda_en         = 1'b1;
                master_o_data  = 1'b0;  // → repeated START

                if (sclk_counter_reg == FCOUNT - 1) begin
                    sclk_counter_next = 0;
                    state_next        = REP_START4;
                    bit_counter_next  = 0;
                    scl_en            = 1;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end

            // 4단계 ADDR상태 처음, falling edge 방지
            REP_START4: begin
                scl_en         = 1'b0;
                start_stop_scl = 1'b0;  //미리 falling
                sda_en         = 1'b1;
                master_o_data  = 1'b0;

                if (sclk_counter_reg == FCOUNT - 1) begin
                    sclk_counter_next = 0;
                    state_next        = ADDR_R;  // READ 주소 전송
                    bit_counter_next  = 0;
                    scl_en            = 1;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            //-----------------------------------------------------
            ADDR_R: begin
                scl_en = 1;
                master_o_data = temp_slave_addr_reg[7];
                if (sclk_falling) begin //바로들어오면 밀려버림..마지막에 1이안들어가고 밀려서 0들어감..
                    temp_slave_addr_next = {temp_slave_addr_reg[6:0], 1'b0};
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        state_next       = ACK_ADDR_R;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end



            ACK_ADDR_R: begin
                scl_en = 1;
                sda_en = 0;
                if (sclk_rising) write_ack_next = SDA;

                if (sclk_falling && write_ack_reg == 0) state_next = READ_BYTE;
                else if (sclk_falling && (write_ack_reg == 1'b1))
                    state_next = STOP1;  // nack
                else if (sclk_falling && (write_ack_reg === 1'bz))
                    state_next = STOP1;  // 버그 detect용

            end

            //-----------------------------------------------------
            READ_BYTE: begin
                scl_en = 1;
                sda_en = 0;

                // SDA 샘플링
                if (sclk_rising)
                    temp_rx_data_next = {temp_rx_data_reg[6:0], SDA};

                // 바이트 완성
                // falling 에서 bit
                if (sclk_falling) begin
                    if (bit_counter_reg == 7) begin
                        bit_counter_next = 0;
                        slv_count_next   = slv_count_reg + 1;
                        rx_done_next     = 1;

                        // rx_data 저장 (MSB부터)
                        case (slv_count_reg)
                            3'd0: rx_data_next[31:24] = temp_rx_data_reg;
                            3'd1: rx_data_next[23:16] = temp_rx_data_reg;
                            3'd2: rx_data_next[15:8] = temp_rx_data_reg;
                            3'd3: rx_data_next[7:0] = temp_rx_data_reg;
                        endcase

                        state_next = READ_HOLD;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end

            READ_HOLD: begin
                scl_en = 1;
                if (slv_count_reg < burst_len_reg + 1) state_next = ACK_READ;
                else state_next = NACK_READ;
            end

            ACK_READ: begin
                scl_en = 1;
                master_o_data = 0;
                if (sclk_falling) state_next = READ_BYTE;
            end

            NACK_READ: begin
                scl_en = 1;
                master_o_data = 1;
                if (sclk_falling) state_next = STOP1;
            end

            //-----------------------------------------------------
            STOP1: begin
                scl_en         = 0;  // 제너레이터 끄고
                start_stop_scl = 0;  // 일단 SCL low
                master_o_data  = 0;  // SDA low
                if (sclk_counter_reg == 500 - 1) begin
                    sclk_counter_next = 0;
                    state_next        = STOP2;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end

            STOP2: begin
                scl_en         = 0;
                start_stop_scl = 1;  // 계속 high 유지
                master_o_data  = 0;  //
                done           = 0;
                if (sclk_counter_reg == 250 - 1) begin
                    sclk_counter_next = 0;
                    state_next        = STOP3;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end

            STOP3: begin
                scl_en         = 0;
                start_stop_scl = 1;  // 계속 high 유지
                master_o_data  = 1;  // 여기서 SDA↑ → STOP 조건 생성
                done           = 1;
                if (sclk_counter_reg == 250 - 1) begin
                    sclk_counter_next = 0;
                    state_next        = IDLE;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end

    //-------------------------------------------------------------
    parameter CLK3 = 1000, CLK0 = 250, CLK1 = 500, CLK2 = 750;

    reg [$clog2(CLK3)-1:0] counter_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter_reg  <= 0;
            data_ack_scl <= 0;
        end else begin
            if (scl_en) begin
                if (counter_reg >= 0 && counter_reg < CLK0 - 1) begin
                    counter_reg  <= counter_reg + 1;
                    data_ack_scl <= 0;
                end else if (counter_reg >= CLK0-1 && counter_reg < CLK1-1) begin
                    counter_reg  <= counter_reg + 1;
                    data_ack_scl <= 1;
                end else if (counter_reg >= CLK1-1 && counter_reg < CLK2-1) begin
                    counter_reg  <= counter_reg + 1;
                    data_ack_scl <= 1;
                end else if (counter_reg >= CLK2-1 && counter_reg < CLK3-1-1) begin
                    counter_reg  <= counter_reg + 1;
                    data_ack_scl <= 0;
                end else if (counter_reg == CLK3 - 1 - 1) begin
                    counter_reg  <= counter_reg + 1;
                    data_ack_scl <= 0;
                end else if (counter_reg == CLK3 - 1) begin
                    counter_reg  <= 0;
                    data_ack_scl <= 0;
                end
            end else begin
                counter_reg  <= 0;
                data_ack_scl <= 0;
            end
        end
    end

endmodule
