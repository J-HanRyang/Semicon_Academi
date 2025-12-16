`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/23 23:54:42
// Design Name: 
// Module Name: OV7076_Init_SCCB_inf
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


module OV7076_Init_SCCB_inf(
    input  logic clk,
    input  logic reset,    

    // 카메라의 I2C 라인
    output logic CAM_SCL,
    inout  wire  CAM_SDA,

    // 초기화 완료 표시
    output logic init_done
    );

    // ─────────────────────────────────────
    // I2C_Master와 연결할 신호
    // ─────────────────────────────────────
    logic        i2c_start;
    logic        i2c_ready;
    logic        i2c_done;

    logic [1:0]  i2c_mode;
    logic [6:0]  i2c_slave_addr;
    logic [7:0]  i2c_reg_addr;
    logic [1:0]  i2c_burst_len;

    logic [31:0] i2c_tx_data;
    //logic [31:0] i2c_rx_data;
    logic        i2c_tx_done;
    //logic        i2c_rx_done;
    logic sccb_en;

    // OV7670: 8bit addr = 0x42(write) / 0x43(read) → 7bit는 0x21
    localparam [6:0] OV7670_ADDR_7BIT = 7'h21;
    localparam [1:0] MODE_REG_WRITE   = 2'b10;

    assign i2c_slave_addr = OV7670_ADDR_7BIT;
    assign i2c_mode       = MODE_REG_WRITE;  // 항상 RegWrite
    assign i2c_burst_len  = 2'b00;          // 1 byte

    I2C_Master u_i2c_master (
        .clk        (clk),
        .reset      (reset),      
        .i2c_en     (1'b1),
        .start      (i2c_start),
        .ready      (i2c_ready),
        .done       (i2c_done),
        .sccb_en(sccb_en), // sccb mode 사용
        .mode       (i2c_mode),
        .slave_addr (i2c_slave_addr),
        .reg_addr   (i2c_reg_addr),
        .burst_len  (i2c_burst_len),

        .tx_data    (i2c_tx_data),
        .rx_data    (),
        .tx_done    (i2c_tx_done),
        .rx_done    (),

        .SCL        (CAM_SCL),
        .SDA        (CAM_SDA)
    );

    // ─────────────────────────────────────
    // 2) OV7670_config_rom 인스턴스
    // ─────────────────────────────────────
    logic [7:0]  rom_addr;
    logic [15:0] rom_dout;

    OV7670_rom u_ov7670_rom (
        .clk  (clk),
        .addr (rom_addr),
        .dout (rom_dout)
    );

    wire [7:0] rom_reg_addr = rom_dout[15:8];
    wire [7:0] rom_reg_data = rom_dout[7:0];

    // 특수 코드
    wire is_delay = (rom_dout == 16'hFF_F0);
    wire is_end   = (rom_dout == 16'hFF_FF);

    // ─────────────────────────────────────
    // 3) 초기화 FSM
    // ─────────────────────────────────────
    typedef enum logic [2:0] {
        ST_IDLE,
        ST_LOAD,    // ROM 데이터 안정화 기다리기
        ST_CHECK,   // delay/end/normal 판별
        ST_I2C_START,
        ST_I2C_WAIT,
        ST_DELAY,
        ST_DONE
    } state_t;

    state_t state, state_next;

    // delay용 카운터
    logic [23:0] delay_cnt, delay_cnt_next;
    logic [7:0]  rom_addr_next;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= ST_IDLE;
            delay_cnt <= 24'd0;
            rom_addr  <= 8'd0;
            init_done <= 1'b0;
        end else begin
            state     <= state_next;
            delay_cnt <= delay_cnt_next;
            rom_addr  <= rom_addr_next;
            init_done <= (state_next == ST_DONE);
        end
    end

    always_comb begin
        sccb_en = 1'b1;
        i2c_start    = 1'b0;
        i2c_reg_addr = rom_reg_addr;
        i2c_tx_data  = {rom_reg_data, 24'h000000};

        state_next     = state;
        delay_cnt_next = delay_cnt;
        rom_addr_next  = rom_addr;

        case (state)
            //-------------------------------------------------
            ST_IDLE: begin
                rom_addr_next = 8'd0;
                state_next    = ST_LOAD;
            end

            //-------------------------------------------------
            ST_LOAD: begin
                state_next = ST_CHECK;
            end

            //-------------------------------------------------
            ST_CHECK: begin
                if (is_end) begin
                    state_next = ST_DONE;
                end
                else if (is_delay) begin
                    delay_cnt_next = 24'd500_000;  
                    state_next     = ST_DELAY;
                end
                else begin
                    state_next = ST_I2C_START;
                end
            end

            //-------------------------------------------------
            ST_I2C_START: begin
                if (i2c_ready) begin
                    i2c_start = 1'b1;
                    state_next = ST_I2C_WAIT;
                end
            end

            ST_I2C_WAIT: begin
                // 해당 레지스터 write 완료
                if (i2c_done) begin
                    rom_addr_next = rom_addr + 1;
                    state_next    = ST_LOAD;
                end
            end

            //-------------------------------------------------
            ST_DELAY: begin
                if (delay_cnt == 24'd0) begin
                    rom_addr_next = rom_addr + 1;
                    state_next    = ST_LOAD;
                end else begin
                    delay_cnt_next = delay_cnt - 1;
                end
            end

            //-------------------------------------------------
            ST_DONE: begin
                state_next = ST_DONE;
            end
        endcase
    end

endmodule