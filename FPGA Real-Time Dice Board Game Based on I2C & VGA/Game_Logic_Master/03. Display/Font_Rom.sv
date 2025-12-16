`timescale 1ns / 1ps

module Font_Rom (
    input  logic [6:0] char_code, // ASCII 코드 (예: 0x41='A', 0x30='0')
    input  logic [3:0] row_addr,  // 글자의 몇 번째 줄인지 (0~15)
    output logic [7:0] row_data   // 그 줄의 픽셀 데이터 (1=글자색, 0=배경색)
);

    always_comb begin
        case (char_code)
            // --- 숫자 0 ~ 9 (ASCII 0x30 ~ 0x39) ---
            7'h30: case(row_addr) // 0
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h42;
                4: row_data = 8'h42; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h31: case(row_addr) // 1
                0: row_data = 8'h08; 1: row_data = 8'h18; 2: row_data = 8'h28; 3: row_data = 8'h08;
                4: row_data = 8'h08; 5: row_data = 8'h08; 6: row_data = 8'h08; 7: row_data = 8'h3E;
                default: row_data = 0; endcase
            7'h32: case(row_addr) // 2
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h02; 3: row_data = 8'h0C;
                4: row_data = 8'h30; 5: row_data = 8'h40; 6: row_data = 8'h42; 7: row_data = 8'h7E;
                default: row_data = 0; endcase
            7'h33: case(row_addr) // 3
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h02; 3: row_data = 8'h1C;
                4: row_data = 8'h02; 5: row_data = 8'h02; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h34: case(row_addr) // 4
                0: row_data = 8'h04; 1: row_data = 8'h0C; 2: row_data = 8'h14; 3: row_data = 8'h24;
                4: row_data = 8'h44; 5: row_data = 8'h7E; 6: row_data = 8'h04; 7: row_data = 8'h04;
                default: row_data = 0; endcase
            7'h35: case(row_addr) // 5
                0: row_data = 8'h7E; 1: row_data = 8'h40; 2: row_data = 8'h40; 3: row_data = 8'h7C;
                4: row_data = 8'h02; 5: row_data = 8'h02; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h36: case(row_addr) // 6
                0: row_data = 8'h3C; 1: row_data = 8'h40; 2: row_data = 8'h40; 3: row_data = 8'h7C;
                4: row_data = 8'h42; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h37: case(row_addr) // 7
                0: row_data = 8'h7E; 1: row_data = 8'h02; 2: row_data = 8'h04; 3: row_data = 8'h08;
                4: row_data = 8'h10; 5: row_data = 8'h10; 6: row_data = 8'h10; 7: row_data = 8'h10;
                default: row_data = 0; endcase
            7'h38: case(row_addr) // 8
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h3C;
                4: row_data = 8'h42; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h39: case(row_addr) // 9
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h3E;
                4: row_data = 8'h02; 5: row_data = 8'h02; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            
            // --- 알파벳 (필요한 것들) ---
            7'h41: case(row_addr) // A
                0: row_data = 8'h18; 1: row_data = 8'h24; 2: row_data = 8'h42; 3: row_data = 8'h42;
                4: row_data = 8'h7E; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h42;
                default: row_data = 0; endcase
            7'h42: case(row_addr) // B
                0: row_data = 8'h7C; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h7C; 
                4: row_data = 8'h42; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h7C; 
                default: row_data = 0; endcase
            7'h43: case(row_addr) // C
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h40; 3: row_data = 8'h40;
                4: row_data = 8'h40; 5: row_data = 8'h40; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h44: case(row_addr) // D
                0: row_data = 8'h78; 1: row_data = 8'h44; 2: row_data = 8'h42; 3: row_data = 8'h42;
                4: row_data = 8'h42; 5: row_data = 8'h42; 6: row_data = 8'h44; 7: row_data = 8'h78;
                default: row_data = 0; endcase
            7'h45: case(row_addr) // E
                0: row_data = 8'h7E; 1: row_data = 8'h40; 2: row_data = 8'h40; 3: row_data = 8'h7C;
                4: row_data = 8'h40; 5: row_data = 8'h40; 6: row_data = 8'h40; 7: row_data = 8'h7E;
                default: row_data = 0; endcase
            7'h46: case(row_addr) // F
                0: row_data = 8'h7E; 1: row_data = 8'h40; 2: row_data = 8'h40; 3: row_data = 8'h7C;
                4: row_data = 8'h40; 5: row_data = 8'h40; 6: row_data = 8'h40; 7: row_data = 8'h40;
                default: row_data = 0; endcase
            7'h47: case(row_addr) // G
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h40; 3: row_data = 8'h40;
                4: row_data = 8'h4E; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h48: case(row_addr) // H
                0: row_data = 8'h42; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h7E;
                4: row_data = 8'h42; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h42;
                default: row_data = 0; endcase
            7'h49: case(row_addr) // I
                0: row_data = 8'h3C; 1: row_data = 8'h18; 2: row_data = 8'h18; 3: row_data = 8'h18;
                4: row_data = 8'h18; 5: row_data = 8'h18; 6: row_data = 8'h18; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h4C: case(row_addr) // L
                0: row_data = 8'h40; 1: row_data = 8'h40; 2: row_data = 8'h40; 3: row_data = 8'h40;
                4: row_data = 8'h40; 5: row_data = 8'h40; 6: row_data = 8'h40; 7: row_data = 8'h7E;
                default: row_data = 0; endcase
            7'h4D: case(row_addr) // M
                0: row_data = 8'h42; 1: row_data = 8'h66; 2: row_data = 8'h5A; 3: row_data = 8'h42;
                4: row_data = 8'h42; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h42;
                default: row_data = 0; endcase
            7'h4E: case(row_addr) // N
                0: row_data = 8'h42; 1: row_data = 8'h62; 2: row_data = 8'h52; 3: row_data = 8'h4A;
                4: row_data = 8'h46; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h42;
                default: row_data = 0; endcase
            7'h4F: case(row_addr) // O
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h42;
                4: row_data = 8'h42; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h50: case(row_addr) // P
                0: row_data = 8'h7C; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h7C;
                4: row_data = 8'h40; 5: row_data = 8'h40; 6: row_data = 8'h40; 7: row_data = 8'h40;
                default: row_data = 0; endcase
            7'h52: case(row_addr) // R
                0: row_data = 8'h7C; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h7C;
                4: row_data = 8'h44; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h42;
                default: row_data = 0; endcase
            7'h53: case(row_addr) // S
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h40; 3: row_data = 8'h3C;
                4: row_data = 8'h02; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h54: case(row_addr) // T
                0: row_data = 8'h7E; 1: row_data = 8'h18; 2: row_data = 8'h18; 3: row_data = 8'h18;
                4: row_data = 8'h18; 5: row_data = 8'h18; 6: row_data = 8'h18; 7: row_data = 8'h18;
                default: row_data = 0; endcase
            7'h55: case(row_addr) // U
                0: row_data = 8'h42; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h42;
                4: row_data = 8'h42; 5: row_data = 8'h42; 6: row_data = 8'h42; 7: row_data = 8'h3C;
                default: row_data = 0; endcase
            7'h56: case(row_addr) // V
                0: row_data = 8'h42; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h42;
                4: row_data = 8'h42; 5: row_data = 8'h24; 6: row_data = 8'h24; 7: row_data = 8'h18;
                default: row_data = 0; endcase
            7'h57: case(row_addr) // W
                0: row_data = 8'h42; 1: row_data = 8'h42; 2: row_data = 8'h42; 3: row_data = 8'h42;
                4: row_data = 8'h5A; 5: row_data = 8'h5A; 6: row_data = 8'h66; 7: row_data = 8'h42;
                default: row_data = 0; endcase
            7'h59: case(row_addr) // Y
                0: row_data = 8'h82; 1: row_data = 8'h44; 2: row_data = 8'h28; 3: row_data = 8'h10;
                4: row_data = 8'h10; 5: row_data = 8'h10; 6: row_data = 8'h10; 7: row_data = 8'h10;
                default: row_data = 0; endcase

            // --- 특수 문자 ---
            7'h3A: case(row_addr) // ':'
                2: row_data = 8'h18; 3: row_data = 8'h18; 
                5: row_data = 8'h18; 6: row_data = 8'h18; default: row_data = 0; endcase
            
            7'h3F: case(row_addr) // '?'
                0: row_data = 8'h3C; 1: row_data = 8'h42; 2: row_data = 8'h02; 3: row_data = 8'h04;
                4: row_data = 8'h08; 5: row_data = 8'h00; 6: row_data = 8'h00; 7: row_data = 8'h08;
                default: row_data = 0; endcase
            
            // --- 공백 (Space) ---
            default: row_data = 8'h00; 
        endcase
    end
endmodule