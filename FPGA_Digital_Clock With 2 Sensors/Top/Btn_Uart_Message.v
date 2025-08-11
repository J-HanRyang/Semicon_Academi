`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Joobin Hwang with Jiyun_Han
// 
// Create Date	    : 2025/07/27
// Design Name      : Project_Digital_Clock
// Module Name      : Btn_Uart_Message
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : PC Commend & Message
//
// Revision 	    : 2025/07/27    --Start--
//                    2025/07/28    --Finish--
//////////////////////////////////////////////////////////////////////////////////

module Btn_Uart_Message (
    input           iClk,
    input           iRst, 

    input   [7:0]   iRx_Data,
    input   [7:0]   iAscii_Hour_10,
    input   [7:0]   iAscii_Hour_1,
    input   [7:0]   iAscii_Min_10,
    input   [7:0]   iAscii_Min_1,
    input   [7:0]   iAscii_Sec_10,
    input   [7:0]   iAscii_Sec_1,

    input           iSet,
    input   [3:0]   iMode,

    input           iBtn_U,
    input           iBtn_D,
    input           iBtn_L,
    input           iBtn_R,
    
    output  [7:0]   oBtn_data,
    output          en_btn
);

    // 상태 정의
    localparam IDLE     = 4'd0;
    localparam DATA     = 4'd1;
    localparam DATA_1   = 4'd2;
    localparam DATA_2   = 4'd3;
    localparam DATA_3   = 4'd4;
    localparam DATA_4   = 4'd5;
    localparam SEND     = 4'd6;
    localparam DONE     = 4'd7;

    reg [2:0] state_reg, state_next;
    reg [5:0] msg_idx_reg, msg_idx_next;
    reg [5:0] msg_len_reg, msg_len_next;
    reg       en_btn_reg, en_btn_next;
    reg [7:0] btn_data_reg, btn_data_next;

    reg [7:0] msg_mem_reg [0:31];   // Max 32Byte
    reg [7:0] msg_mem_next[0:31];
    reg run_stop_reg, run_stop_next; 
    reg run_stop_swreg, run_stop_swnext; 
    reg run_stop_setreg, run_stop_setnext;
    reg run_stop_Mreg, run_stop_Mnext;

    reg     [7:0]   rCommand_Cur;
    reg     [7:0]   rCommand_Nxt;

    wire [3:0] wBtn = {iBtn_U, iBtn_D, iBtn_L, iBtn_R};

    integer i;

    assign en_btn   = en_btn_reg;
    assign oBtn_data = btn_data_reg;

    // 레지스터 업데이트
    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            state_reg     <= IDLE;
            msg_idx_reg   <= 0;
            msg_len_reg   <= 0;
            en_btn_reg    <= 0;
            btn_data_reg  <= 0;
            run_stop_reg <= 0;
            run_stop_swreg <= 0;
            run_stop_setreg<= 0;
            run_stop_Mreg <= 0;
            rCommand_Cur    <= 0;
            for (i = 0; i < 32; i = i + 1)
                msg_mem_reg[i] <= 8'd0;
        end else begin
            state_reg     <= state_next;
            msg_idx_reg   <= msg_idx_next;
            msg_len_reg   <= msg_len_next;
            en_btn_reg    <= en_btn_next;
            btn_data_reg  <= btn_data_next;
            run_stop_reg  <= run_stop_next;
            run_stop_swreg <= run_stop_swnext;
            run_stop_setreg <= run_stop_setnext;
            run_stop_Mreg <= run_stop_Mnext;
            rCommand_Cur    <= rCommand_Nxt;
            for (i = 0; i < 32; i = i + 1)
                msg_mem_reg[i] <= msg_mem_next[i];
        end
    end

    // 조합 논리
    always @(*) begin
        state_next     = state_reg;
        msg_idx_next   = msg_idx_reg;
        msg_len_next   = msg_len_reg;
        en_btn_next    = 1'b0;
        btn_data_next  = btn_data_reg;
        run_stop_next  = run_stop_reg;
        run_stop_swnext = run_stop_swreg;
        run_stop_setnext = run_stop_setreg;
        run_stop_Mnext = run_stop_Mreg;
        rCommand_Nxt    = rCommand_Cur;
        for (i = 0; i < 32; i = i + 1)
            msg_mem_next[i] = msg_mem_reg[i];

        case (state_reg)
            IDLE: begin
                msg_idx_next = 0;

                case (iRx_Data)
                    "C"     : 
                    begin
                        msg_mem_next[0]     = "C";
                        msg_mem_next[1]     = "l";
                        msg_mem_next[2]     = "o";
                        msg_mem_next[3]     = "c";
                        msg_mem_next[4]     = "k";
                        msg_mem_next[5]     = " ";
                        msg_len_next        = 18;
                        rCommand_Nxt        = "C";
                        state_next          = DATA_1;
                    end 

                    "W"     :
                    begin
                        msg_mem_next[0]     = "S";
                        msg_mem_next[1]     = "t";
                        msg_mem_next[2]     = "o";
                        msg_mem_next[3]     = "p";
                        msg_mem_next[4]     = "w";
                        msg_mem_next[5]     = "a";
                        msg_mem_next[6]     = "t";
                        msg_mem_next[7]     = "c";
                        msg_mem_next[8]     = "h";
                        msg_mem_next[9]     = " ";
                        rCommand_Nxt        = "W";
                        msg_len_next        = 23;
                        state_next          = DATA_1;
                    end

                    "T"     :
                    begin
                        msg_mem_next[0]     = "T";
                        msg_mem_next[1]     = "i";
                        msg_mem_next[2]     = "m";
                        msg_mem_next[3]     = "e";
                        msg_mem_next[4]     = "r";
                        msg_mem_next[5]     = " ";
                        rCommand_Nxt        = "T";
                        msg_len_next        = 18;
                        state_next          = DATA_1;        
                    end

                    "U"     :
                    begin
                        msg_mem_next[0]     = "U";
                        msg_mem_next[1]     = "l";
                        msg_mem_next[2]     = "t";
                        msg_mem_next[3]     = "r";
                        msg_mem_next[4]     = "a";
                        msg_mem_next[5]     = "s";
                        msg_mem_next[6]     = "e";
                        msg_mem_next[7]     = "n";
                        msg_mem_next[8]     = "s";
                        msg_mem_next[9]     = "o";
                        msg_mem_next[10]    = "r";
                        msg_mem_next[11]    = " ";
                        msg_mem_next[12]    = ":";
                        msg_mem_next[13]    = " ";
                        rCommand_Nxt        = "U";
                        msg_len_next        = 21;
                        state_next          = DATA_1;        
                    end

                    "D"     :
                    begin
                        msg_mem_next[0]     = "D";
                        msg_mem_next[1]     = "H";
                        msg_mem_next[2]     = "T";
                        msg_mem_next[3]     = "1";
                        msg_mem_next[4]     = "1";
                        msg_mem_next[5]     = " ";
                        msg_mem_next[6]     = ":";
                        msg_mem_next[7]     = " ";
                        rCommand_Nxt        = "D";
                        msg_len_next        = 21;
                        state_next          = DATA_1;
                    end

                    default :   ;
                endcase

                casez ({iSet, iMode, wBtn}) // 8bit
                    9'b1_00?0_0001    : // Clock_Right
                    begin
                        msg_mem_next[0]     = "R";
                        msg_mem_next[1]     = "i";
                        msg_mem_next[2]     = "g";
                        msg_mem_next[3]     = "h";
                        msg_mem_next[4]     = "t";
                        msg_mem_next[5]     = 8'h0A;
                        msg_len_next        = 6;
                        state_next          = SEND;
                    end
                    
                    9'b1_00?0_0010    : // Clock Left
                    begin
                        msg_mem_next[0]     = "L";
                        msg_mem_next[1]     = "e";
                        msg_mem_next[2]     = "f";
                        msg_mem_next[3]     = "t";
                        msg_mem_next[4]     = 8'h0A;
                        msg_len_next        = 5;
                        state_next          = SEND;
                    end

                    9'b1_00?0_0100    : // Clock Down
                    begin
                        msg_mem_next[0]     = "D";
                        msg_mem_next[1]     = "o";
                        msg_mem_next[2]     = "w";
                        msg_mem_next[3]     = "n";
                        msg_mem_next[4]     = 8'h0A;
                        msg_len_next        = 5;
                        state_next          = SEND;
                    end

                    9'b1_00?0_1000    : // Clock Up
                    begin
                        msg_mem_next[0]     = "U";
                        msg_mem_next[1]     = "p";
                        msg_mem_next[2]     = 8'h0A;
                        msg_len_next        = 3;
                        state_next          = SEND;
                    end

                    9'b?_0001_0001    : // SW Run / Stop
                    begin
                        run_stop_next = run_stop_reg +1;
                        
                        if (run_stop_next) begin
                            msg_mem_next[0]     = "S";
                            msg_mem_next[1]     = "t";
                            msg_mem_next[2]     = "o";
                            msg_mem_next[3]     = "p";
                            msg_mem_next[4]     = "_";
                            msg_mem_next[5]     = "W";
                            msg_mem_next[6]     = "a";
                            msg_mem_next[7]     = "t";
                            msg_mem_next[8]     = "c";
                            msg_mem_next[9]     = "h";
                            msg_mem_next[10]    = "_";
                            msg_mem_next[11]    = "R";
                            msg_mem_next[12]    = "U";
                            msg_mem_next[13]    = "N";
                            msg_mem_next[14]    = 8'h0A;
                            msg_len_next        = 15;
                            state_next          = SEND;
                        end else 
                        begin             
                            msg_mem_next[0]     = "S";
                            msg_mem_next[1]     = "t";
                            msg_mem_next[2]     = "o";
                            msg_mem_next[3]     = "p";
                            msg_mem_next[4]     = "_";
                            msg_mem_next[5]     = "W";
                            msg_mem_next[6]     = "a";
                            msg_mem_next[7]     = "t";
                            msg_mem_next[8]     = "c";
                            msg_mem_next[9]     = "h";
                            msg_mem_next[10]    = "_";
                            msg_mem_next[11]    = "S";
                            msg_mem_next[12]    = "T";
                            msg_mem_next[13]    = "O";
                            msg_mem_next[14]    = "P";
                            msg_mem_next[15]    = 8'h0A;
                            msg_len_next        = 16;
                            state_next          = SEND;
                        end
                    end

                    9'b?_0001_0010    : // Sw Clear
                    begin
                        msg_mem_next[0]         = "S";
                        msg_mem_next[1]         = "t";
                        msg_mem_next[2]         = "o";
                        msg_mem_next[3]         = "p";
                        msg_mem_next[4]         = "_";
                        msg_mem_next[5]         = "W";
                        msg_mem_next[6]         = "a";
                        msg_mem_next[7]         = "t";
                        msg_mem_next[8]         = "c";
                        msg_mem_next[9]         = "h";
                        msg_mem_next[10]        = "_";    
                        msg_mem_next[11]        = "C";
                        msg_mem_next[12]        = "l";
                        msg_mem_next[13]        = "e";
                        msg_mem_next[14]        = "a";
                        msg_mem_next[15]        = "r";
                        msg_mem_next[16]        = 8'h0A;
                        msg_len_next            = 17;
                        state_next              = SEND;
                    end
                
                    9'b0_0010_0001    : // Timer tun /stop
                    begin
                        if  ((iAscii_Hour_10 || iAscii_Hour_1 || iAscii_Min_10 ||
                             iAscii_Min_1    || iAscii_Sec_10 || iAscii_Sec_1) == 0)
                        begin
                            run_stop_swnext = 0;
                        end else
                        begin
                            run_stop_swnext = run_stop_swreg +1;
                        end
                       
                        if (run_stop_swnext) begin
                            msg_mem_next[0]     = "T";
                            msg_mem_next[1]     = "i";
                            msg_mem_next[2]     = "m";
                            msg_mem_next[3]     = "e";
                            msg_mem_next[4]     = "r";
                            msg_mem_next[5]     = "_";
                            msg_mem_next[6]     = "R";
                            msg_mem_next[7]     = "U";
                            msg_mem_next[8]     = "N";
                            msg_mem_next[9]     = 8'h0A;
                            msg_len_next        = 10;
                            state_next          = SEND;
                        end else begin
                            msg_mem_next[0]     = "T";
                            msg_mem_next[1]     = "i";
                            msg_mem_next[2]     = "m";
                            msg_mem_next[3]     = "e";
                            msg_mem_next[4]     = "r";
                            msg_mem_next[5]     = "_";
                            msg_mem_next[6]     = "S";
                            msg_mem_next[7]     = "T";
                            msg_mem_next[8]     = "O";
                            msg_mem_next[9]     = "P";
                            msg_mem_next[10]    = 8'h0A;
                            msg_len_next = 11;
                            state_next = SEND;
                        end
                    end

                    9'b0_0010_0010    : // Timer clear
                    begin
                        msg_mem_next[0]         = "T";
                        msg_mem_next[1]         = "i";
                        msg_mem_next[2]         = "m";
                        msg_mem_next[3]         = "e";
                        msg_mem_next[4]         = "r";
                        msg_mem_next[5]         = "_";
                        msg_mem_next[6]         = "C";
                        msg_mem_next[7]         = "l";
                        msg_mem_next[8]         = "e";
                        msg_mem_next[9]         = "a";
                        msg_mem_next[10]        = "r";
                        msg_mem_next[11]        = 8'h0A;
                        msg_len_next            = 12;
                        state_next              = SEND;
                    end

                    default : ;
                endcase

                if (iRx_Data == "S") begin
                        run_stop_setnext = run_stop_setreg +1;
                        
                    if (run_stop_setnext) begin
                        msg_mem_next[0]         = "S";
                        msg_mem_next[1]         = "e";
                        msg_mem_next[2]         = "t";
                        msg_mem_next[3]         = "t";
                        msg_mem_next[4]         = "i";
                        msg_mem_next[5]         = "n";
                        msg_mem_next[6]         = "g";
                        msg_mem_next[7]         = "_";
                        msg_mem_next[8]         = "O";
                        msg_mem_next[9]         = "n";
                        msg_mem_next[10]        = 8'h0A;
                        msg_len_next            = 11;
                        state_next = SEND;
                
                    end else begin
                        msg_mem_next[0]         = "S";
                        msg_mem_next[1]         = "e";
                        msg_mem_next[2]         = "t";
                        msg_mem_next[3]         = "t";
                        msg_mem_next[4]         = "i";
                        msg_mem_next[5]         = "n";
                        msg_mem_next[6]         = "g";
                        msg_mem_next[7]         = "_";
                        msg_mem_next[8]         = "O";
                        msg_mem_next[9]         = "f";
                        msg_mem_next[10]        = "f";
                        msg_mem_next[11]        = 8'h0A;
                        msg_len_next            = 12;
                        state_next              = SEND;
                    end
                end

                if ((iRx_Data == "M") && iMode[3]) begin
                    run_stop_Mnext = run_stop_Mreg +1;
                        
                    if (!run_stop_Mnext) begin
                        msg_mem_next[0]         = "T";
                        msg_mem_next[1]         = "e";
                        msg_mem_next[2]         = "m";
                        msg_mem_next[3]         = "p";
                        msg_mem_next[4]         = "e";
                        msg_mem_next[5]         = "r";
                        msg_mem_next[6]         = "a";
                        msg_mem_next[7]         = "t";
                        msg_mem_next[8]         = "u";
                        msg_mem_next[9]         = "r";
                        msg_mem_next[10]        ="e";
                        msg_mem_next[11]        = 8'h0A;
                        msg_len_next            = 12;
                        state_next              = SEND;
                
                    end else begin
                        msg_mem_next[0]         = "H";
                        msg_mem_next[1]         = "u";
                        msg_mem_next[2]         = "m";
                        msg_mem_next[3]         = "i";
                        msg_mem_next[4]         = "d";
                        msg_mem_next[5]         = "i";
                        msg_mem_next[6]         = "t";
                        msg_mem_next[7]         = "y";
                        msg_mem_next[8]         = 8'h0A;
                        msg_len_next            = 9;
                        state_next              = SEND;
                    end
                end

                if ((iRx_Data == "M") && !iMode[3]) begin
                    run_stop_Mnext = run_stop_Mreg +1;
                        
                    if (!run_stop_Mnext) begin
                        msg_mem_next[0]         = "S";
                        msg_mem_next[1]         = "e";
                        msg_mem_next[2]         = "c";
                        msg_mem_next[3]         = "_";
                        msg_mem_next[4]         = "m";
                        msg_mem_next[5]         = "S";
                        msg_mem_next[6]         = "e";
                        msg_mem_next[7]         = "c";
                        msg_mem_next[8]         = 8'h0A;
                        msg_len_next            = 9;
                        state_next              = SEND;
                
                    end else begin
                        msg_mem_next[0]         = "H";
                        msg_mem_next[1]         = "o";
                        msg_mem_next[2]         = "u";
                        msg_mem_next[3]         = "r";
                        msg_mem_next[4]         = "_";
                        msg_mem_next[5]         = "M";
                        msg_mem_next[6]         = "i";
                        msg_mem_next[7]         = "n";
                        msg_mem_next[8]         = 8'h0A;
                        msg_len_next            = 9;
                        state_next              = SEND;
                    end
                end
            end

            DATA_1  : state_next    = DATA_2;
            DATA_2  : state_next    = DATA_3;
            DATA_3  : state_next    = DATA_4;

            DATA_4: begin
                case (rCommand_Cur)
                    "C"     : 
                    begin
                        msg_mem_next[6]     = iAscii_Hour_10;
                        msg_mem_next[7]     = iAscii_Hour_1;
                        msg_mem_next[8]     = "H";
                        msg_mem_next[9]     = " ";
                        msg_mem_next[10]    = iAscii_Min_10;
                        msg_mem_next[11]    = iAscii_Min_1;
                        msg_mem_next[12]    = "M";
                        msg_mem_next[13]    = " ";
                        msg_mem_next[14]    = iAscii_Sec_10;
                        msg_mem_next[15]    = iAscii_Sec_1;
                        msg_mem_next[16]    = "S";
                        msg_mem_next[17]    = 8'h0A;
                        msg_len_next        = 18;
                        state_next          = SEND;
                    end 

                    "W"     :
                    begin
                        
                        msg_mem_next[10]     = iAscii_Hour_10;
                        msg_mem_next[11]     = iAscii_Hour_1;
                        msg_mem_next[12]     = "M";
                        msg_mem_next[13]     = " ";
                        msg_mem_next[14]    = iAscii_Min_10;
                        msg_mem_next[15]    = iAscii_Min_1;
                        msg_mem_next[16]    = "S";
                        msg_mem_next[17]    = " ";
                        msg_mem_next[18]    = iAscii_Sec_10;
                        msg_mem_next[19]    = iAscii_Sec_1;
                        msg_mem_next[20]    = "m";
                        msg_mem_next[21]    = "S";
                        msg_mem_next[22]    = 8'h0A;
                        msg_len_next        = 23;
                        state_next          = SEND;
                    end

                    "T"     :
                    begin
                        
                        msg_mem_next[6]     = iAscii_Hour_10;
                        msg_mem_next[7]     = iAscii_Hour_1;
                        msg_mem_next[8]     = "H";
                        msg_mem_next[9]     = " ";
                        msg_mem_next[10]    = iAscii_Min_10;
                        msg_mem_next[11]    = iAscii_Min_1;
                        msg_mem_next[12]    = "M";
                        msg_mem_next[13]    = " ";
                        msg_mem_next[14]    = iAscii_Sec_10;
                        msg_mem_next[15]    = iAscii_Sec_1;
                        msg_mem_next[16]    = "S";
                        msg_mem_next[17]    = 8'h0A;
                        msg_len_next        = 18;
                        state_next          = SEND;        
                    end

                    "U"     :
                    begin
                        
                        msg_mem_next[14]    = iAscii_Hour_10;
                        msg_mem_next[15]    = iAscii_Hour_1;
                        msg_mem_next[16]    = iAscii_Min_10;
                        msg_mem_next[17]    = iAscii_Min_1;
                        msg_mem_next[18]    = "c";
                        msg_mem_next[19]    = "m";
                        msg_mem_next[20]    = 8'h0A;
                        msg_len_next        = 21;
                        state_next          = SEND;        
                    end

                    "D"     :
                    begin
                        
                        msg_mem_next[8]     = iAscii_Hour_10;
                        msg_mem_next[9]     = iAscii_Hour_1;
                        msg_mem_next[10]    = ".";
                        msg_mem_next[11]    = iAscii_Min_10;
                        msg_mem_next[12]    = "'";
                        msg_mem_next[13]    = "C";
                        msg_mem_next[14]    = " ";
                        msg_mem_next[15]    = iAscii_Min_1;
                        msg_mem_next[16]    = iAscii_Sec_10;
                        msg_mem_next[17]    = ".";
                        msg_mem_next[18]    = iAscii_Sec_1;
                        msg_mem_next[19]    = "%";
                        msg_mem_next[20]    = 8'h0A;
                        msg_len_next        = 21;
                        state_next          = SEND;
                    end

                    default :   ;
                endcase
            end

            SEND: begin
                btn_data_next = msg_mem_reg[msg_idx_reg];
                en_btn_next   = 1'b1;

                if (msg_idx_reg == (msg_len_reg - 1))
                    state_next  = DONE;
                else begin
                    msg_idx_next = msg_idx_reg + 1;
                    state_next  = SEND;
                end
            end

            DONE: begin
                state_next = IDLE;
            end

            default: state_next = IDLE;
        endcase
    end

endmodule
