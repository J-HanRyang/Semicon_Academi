`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Original Author : Seoyu_Kwak
//                  : Modified By     : Jiyun_Han
// 
// Create Date	    : 2025/11/30
// Design Name      : Game_Player_Slave
// Module Name      : i2c_slave_interface
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : I2C Slave Module
//
// Revision 	    : 2025/11/28    Ver_1.0 Import the file and start editing
//                                          (Subsequently Revised by Jiyun_Han)
//                  : 2025/11/29    Ver_1.1 Add Connection lines to the OV7670
//                  : 2025/11/30    Ver_1.2 Add Internal register for change status
//                                          Clean up and comment out modules for readability
//                  : 2025/12/03    Ver_1.3 Add Register Auto Clear
//////////////////////////////////////////////////////////////////////////////////

module i2c_slave_interface #(
    parameter [6:0] I2C_ADDR = 7'b1010_101  // Playter_1
) (
    // Clock & Reset
    input  logic       clk,
    input  logic       reset,               // active high
    // Ver_1.3 Clear Clock
    input  logic       iV_Sync,
    // Master Interface
    input  logic       SCL,
    inout  wire        SDA,
    // VGA(Filter) Interface
    output logic [7:0] current_status_out,  // Reg0
    output logic [7:0] game_result_out,     // Reg1
    output logic [7:0] change_status_out    // Reg2
);


    /***********************************************
    // Reg & Wire
    ***********************************************/
    logic [7:0] temp_rx_data_reg, temp_rx_data_next;  // Rx_Data
    logic [7:0] temp_tx_data_reg, temp_tx_data_next;  // Tx_Data
    logic [7:0] temp_addr_reg, temp_addr_next;
    logic [7:0] reg_addr_reg, reg_addr_next;
    logic [3:0] bit_counter_reg, bit_counter_next;  // Bit_Count
    logic read_ack_reg, read_ack_next;  // ACK/NANK
    // Internal Register Temp
    logic [7:0] temp_reg_0_next, temp_reg_0_reg;  // Current Status
    logic [7:0] temp_reg_1_next, temp_reg_1_reg;  // Game_Result
    logic [7:0] temp_reg_2_next, temp_reg_2_reg;  // Change_Status
    logic       o_data;
    // Ver_1.3
    logic [5:0] clear_timer;
    logic       prev_vsync;
    logic       vsync_pulse;
    assign vsync_pulse = (iV_Sync && !prev_vsync);  // Rising Edge

    /***********************************************
    // I2C 라인 동기화 (모두 clk 도메인에서 처리) + start/stop condition
    ***********************************************/
    logic scl_sync, scl_prev;
    logic sda_sync, sda_prev;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            scl_sync <= 1'b1;
            scl_prev <= 1'b1;
            sda_sync <= 1'b1;
            sda_prev <= 1'b1;
        end else begin
            scl_prev <= scl_sync;
            sda_prev <= sda_sync;
            scl_sync <= SCL;
            sda_sync <= SDA;
        end
    end

    wire scl_rise = (scl_sync == 1'b1 && scl_prev == 1'b0);
    wire scl_fall = (scl_sync == 1'b0 && scl_prev == 1'b1);

    // START / STOP 조건 (SCL high에서 SDA 변화)
    wire start_cond = (scl_sync == 1'b1 && sda_prev == 1'b1 && sda_sync == 1'b0);
    wire stop_cond = (scl_sync == 1'b1 && sda_prev == 1'b0 && sda_sync == 1'b1);


    // --------------------------------------------------
    // SDA 구동  
    // --------------------------------------------------
    logic sda_en;
    assign SDA = sda_en ? o_data : 1'bz;

    // --------------------------------------------------
    // 32-bit 레지스터 4개만
    // --------------------------------------------------
    logic [7:0] slv_reg0_reg, slv_reg0_next;
    logic [7:0] slv_reg1_reg, slv_reg1_next;
    logic [7:0] slv_reg2_reg, slv_reg2_next;


    // --------------------------------------------------
    // I2C 슬레이브 FSM
    // --------------------------------------------------
    typedef enum logic [3:0] {
        ST_IDLE,
        ST_ADDR,      // 주소 + RW 수신
        ST_ACK_ADDR,  // 주소 ACK
        ST_REG,       // 레지스터 주소 수신
        ST_ACK_REG,   // 레지스터 주소 ACK
        ST_RX,        // 데이터 수신 (32bit write)
        ST_ACK_RX,    // 데이터 바이트 ACK
        ST_TX,        // 데이터 전송 (32bit read)
        ST_NACK       // 마스터 ACK/NACK 체크
    } i2c_state_t;

    i2c_state_t state, state_next;


    // Ver_1.3 Revision
    // --------------------------------------------------
    // 상태/레지스터 플립플롭 (단일 sequential 블록)
    // --------------------------------------------------
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state            <= ST_IDLE;
            temp_rx_data_reg <= 8'd0;
            temp_tx_data_reg <= 8'd0;
            temp_addr_reg    <= 8'd0;
            reg_addr_reg     <= 8'd0;
            bit_counter_reg  <= 4'd0;
            read_ack_reg     <= 1'b0;

            slv_reg0_reg     <= 8'd0;
            slv_reg1_reg     <= 8'd0;
            slv_reg2_reg     <= 8'd0;

            temp_reg_0_reg   <= 8'd0;
            temp_reg_1_reg   <= 8'd0;
            temp_reg_2_reg   <= 8'd0;

            // Ver_1.3
            clear_timer      <= 6'd0;
            prev_vsync       <= 1'b0;
        end else begin
            state            <= state_next;
            temp_rx_data_reg <= temp_rx_data_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_addr_reg    <= temp_addr_next;
            reg_addr_reg     <= reg_addr_next;
            bit_counter_reg  <= bit_counter_next;
            read_ack_reg     <= read_ack_next;

            temp_reg_0_reg   <= temp_reg_0_next;
            temp_reg_1_reg   <= temp_reg_1_next;
            temp_reg_2_reg   <= temp_reg_2_next;

            // Ver_1.3
            prev_vsync       <= iV_Sync;

            slv_reg0_reg     <= slv_reg0_next;
            slv_reg1_reg     <= slv_reg1_next;

            // Auto Clear Reg2
            if (state == ST_RX && bit_counter_reg == 4'd7 && scl_fall && reg_addr_reg == 2'd2) begin
                slv_reg2_reg <= temp_rx_data_reg;
                clear_timer  <= 0;
            end else if (slv_reg2_reg != 0) begin
                if (vsync_pulse) begin
                    if (clear_timer < 60) begin
                        clear_timer <= clear_timer + 1;
                    end else begin
                        slv_reg2_reg <= 8'd0;
                        clear_timer  <= 0;
                    end
                end
            end else begin
                clear_timer <= 0;
            end
        end
    end

    // --------------------------------------------------
    // I2C FSM + 레지스터 write 로직 (조합)
    // --------------------------------------------------
    always_comb begin
        // 기본값 (hold)
        state_next        = state;
        sda_en            = 1'b0;
        o_data            = 1'b0;

        temp_rx_data_next = temp_rx_data_reg;
        temp_tx_data_next = temp_tx_data_reg;
        temp_addr_next    = temp_addr_reg;
        reg_addr_next     = reg_addr_reg;

        bit_counter_next  = bit_counter_reg;
        read_ack_next     = read_ack_reg;

        slv_reg0_next     = slv_reg0_reg;
        slv_reg1_next     = slv_reg1_reg;
        slv_reg2_next     = slv_reg2_reg;

        temp_reg_0_next   = temp_reg_0_reg;
        temp_reg_1_next   = temp_reg_1_reg;
        temp_reg_2_next   = temp_reg_2_reg;

        // ★ 1순위: Repeated START (어디서든 새 트랜잭션 시작)
        if (start_cond) begin
            state_next        = ST_ADDR;
            bit_counter_next  = 4'd0;
            temp_addr_next    = 8'd0;
            //         reg_addr_next     = 8'd0; //repeat start할떄 reg정보 날라가면 안됨!!!
            temp_rx_data_next = 8'd0;
            temp_tx_data_next = 8'd0;
            sda_en            = 1'b0;
            // read(S->M) 를 위해 당시 data 캡쳐 (중간에 바뀔 수도 있으니)
            temp_reg_0_next   = slv_reg0_reg;
            temp_reg_1_next   = slv_reg1_reg;
            temp_reg_2_next   = slv_reg2_reg;

        end  // ★ 2순위: STOP
        else if (stop_cond) begin
            state_next = ST_IDLE;
            sda_en     = 1'b0;
        end  // ★ 3순위: 상태 머신 동작
        else begin
            case (state)
                //--------------------------------------------------
                ST_IDLE: begin
                    sda_en = 1'b0;
                    // start_cond는 위에서 이미 처리
                end

                //--------------------------------------------------
                // 7bit 주소 + R/W 비트 수신 (M -> S)
                ST_ADDR: begin
                    sda_en = 1'b0;  // 마스터가 SDA 구동

                    if (scl_rise) begin
                        temp_addr_next = {temp_addr_reg[6:0], SDA};
                    end

                    if (scl_fall) begin
                        if (bit_counter_reg == 4'd8) begin
                            bit_counter_next = 4'd0;
                            state_next       = ST_ACK_ADDR;
                        end else begin
                            bit_counter_next = bit_counter_reg + 4'd1;
                        end
                    end
                end

                // 주소 ACK
                ST_ACK_ADDR: begin
                    if (temp_addr_reg[7:1] == I2C_ADDR) begin
                        sda_en = 1'b1;
                        o_data = 1'b0;  // ACK(0)

                        if (scl_fall) begin
                            if (temp_addr_reg[0] == 1'b1) begin  //read
                                // Read 동작 (M<=S)
                                state_next       = ST_TX;
                                bit_counter_next = 4'd0;

                                // Read: 기존 reg_addr_reg 기준으로 첫 바이트 준비
                                // 당시 data 캡쳐 (중간에 바뀔 수도 있으니)
                                // start 할때 캡쳐해놓은 데이터

                                case (reg_addr_reg)
                                    2'd0: temp_tx_data_next = temp_reg_0_reg;
                                    2'd1: temp_tx_data_next = temp_reg_1_reg;
                                    2'd2: temp_tx_data_next = temp_reg_2_reg;
                                    default: temp_tx_data_next = 8'h00;
                                endcase
                            end else begin
                                // Write 동작 → 레지스터 주소 수신
                                state_next = ST_REG;
                            end
                        end
                    end else begin
                        // 주소 잘못 접근 → IDLE
                        state_next = ST_IDLE;
                    end
                end

                //--------------------------------------------------
                // 레지스터 주소 수신 (8bit, M->S)
                ST_REG: begin
                    sda_en = 1'b0;

                    if (scl_rise) begin
                        reg_addr_next = {reg_addr_reg[6:0], SDA};
                    end

                    if (scl_fall) begin
                        if (bit_counter_reg == 4'd7) begin
                            bit_counter_next = 4'd0;
                            state_next       = ST_ACK_REG;
                        end else begin
                            bit_counter_next = bit_counter_reg + 4'd1;
                        end
                    end
                end

                // 레지스터 주소 ACK
                ST_ACK_REG: begin
                    sda_en = 1'b1;
                    o_data = 1'b0;  // ACK

                    if (scl_fall) begin
                        state_next       = ST_RX;  // Write (M->S)
                        bit_counter_next = 4'd0;
                    end
                end

                //--------------------------------------------------
                // 데이터 수신 (32bit Write, 최대 4바이트)
                ST_RX: begin
                    sda_en = 1'b0;

                    // 비트 쉬프트 (M -> S)
                    if (scl_rise) begin
                        temp_rx_data_next = {temp_rx_data_reg[6:0], SDA};
                    end

                    if (scl_fall) begin
                        if (bit_counter_reg == 4'd7) begin
                            // 마지막 비트까지 포함된 새 바이트

                            bit_counter_next = 4'd0;
                            state_next       = ST_ACK_RX;

                            // reg_addr_reg[1:0]에 따라 32bit 분배
                            //만약에  read only register이면 그냥 없애면 됨!!!
                            case (reg_addr_reg)  // 하위는 잘라서
                                2'd0: begin
                                    slv_reg0_next = temp_rx_data_reg;
                                end

                                2'd1: begin
                                    slv_reg1_next = temp_rx_data_reg;
                                end

                                2'd2: begin
                                    slv_reg2_next = temp_rx_data_reg;
                                end
                            endcase
                        end else begin
                            bit_counter_next = bit_counter_reg + 4'd1;
                        end
                    end
                end

                // 수신 데이터에 대한 ACK
                ST_ACK_RX: begin
                    sda_en = 1'b1;
                    o_data = 1'b0;  // ACK

                    if (scl_fall) begin
                        state_next = ST_RX; // 마스터가 STOP/RESTART 걸면 위의 start/stop_cond 처리됨
                    end
                end

                //--------------------------------------------------
                // 데이터 전송 (32bit Read, S->M)
                ST_TX: begin
                    sda_en = 1'b1;
                    o_data = temp_tx_data_reg[7];

                    if (scl_fall) begin
                        if (bit_counter_reg == 4'd7) begin
                            bit_counter_next = 4'd0;
                            state_next       = ST_NACK; // 마스터 ACK/NACK 받을 차례
                        end else begin
                            temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                            bit_counter_next  = bit_counter_reg + 4'd1;
                        end
                    end
                end

                // 마스터 ACK/NACK 샘플 (M->S)
                ST_NACK: begin
                    sda_en = 1'b0;

                    if (scl_rise) begin
                        read_ack_next = SDA;  // 0: ACK, 1: NACK
                    end

                    if (scl_fall) begin
                        if (read_ack_reg == 1'b1) begin
                            // NACK → 전송 종료
                            read_ack_next = 1'b0;
                            state_next    = ST_IDLE;
                        end else if (read_ack_reg == 1'b0) begin
                            // ACK → 다음 바이트 준비
                            read_ack_next    = 1'b0;
                            state_next       = ST_TX;
                            bit_counter_next = 4'd0;

                            // 다음 바이트 선택 (32bit 전체 4바이트 지원)
                            case (reg_addr_reg)
                                2'd0: begin
                                    temp_tx_data_next = temp_reg_0_reg;
                                end

                                2'd1: begin
                                    temp_tx_data_next = temp_reg_1_reg;
                                end

                                2'd2: begin
                                    temp_tx_data_next = temp_reg_2_reg;
                                end
                                default: temp_tx_data_next = 8'h00;
                            endcase
                        end
                    end
                end

                default: begin
                    state_next = ST_IDLE;
                end
            endcase
        end
    end

    assign current_status_out = slv_reg0_reg;
    assign game_result_out = slv_reg1_reg;
    assign change_status_out = slv_reg2_reg;

endmodule
