`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/23 23:49:30
// Design Name: 
// Module Name: OV7670_rom
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


module OV7670_rom(
    input  logic        clk,
    input  logic [7:0]  addr,
    output logic [15:0] dout
);

    // FFFF is end of rom, FFF0 is delay
    always_ff @(posedge clk) begin
        case (addr)
            0:  dout <= 16'h12_80;  // reset
            1:  dout <= 16'hFF_F0;  // delay
            2:  dout <= 16'h12_14;  // COM7, RGB output, QVGA
            3:  dout <= 16'h11_80;  // CLKRC
            4:  dout <= 16'h0C_04;  // COM3
            5:  dout <= 16'h3E_19;  // COM14
            6:  dout <= 16'h04_00;  // COM1
            7:  dout <= 16'h40_D0;  // COM15
            8:  dout <= 16'h3A_04;  // TSLB
            9:  dout <= 16'h14_18;  // COM9
            10: dout <= 16'h4F_B3;  // MTX1
            11: dout <= 16'h50_B3;  // MTX2
            12: dout <= 16'h51_00;  // MTX3
            13: dout <= 16'h52_3D;  // MTX4
            14: dout <= 16'h53_A7;  // MTX5
            15: dout <= 16'h54_E4;  // MTX6
            16: dout <= 16'h58_9E;  // MTXS
            17: dout <= 16'h3D_C0;  // COM13
            18: dout <= 16'h17_15;  // HSTART
            19: dout <= 16'h18_03;  // HSTOP
            20: dout <= 16'h32_00;  // HREF
            21: dout <= 16'h19_03;  // VSTART
            22: dout <= 16'h1A_7B;  // VSTOP
            23: dout <= 16'h03_00;  // VREF
            24: dout <= 16'h0F_41;  // COM6
            25: dout <= 16'h1E_00;  // MVFP
            26: dout <= 16'h33_0B;  // CHLF
            27: dout <= 16'h3C_78;  // COM12
            28: dout <= 16'h69_00;  // GFIX
            29: dout <= 16'h74_00;  // REG74
            30: dout <= 16'hB0_84;  // magic color
            31: dout <= 16'hB1_0C;  // ABLC1
            32: dout <= 16'hB2_0E;  // RSVD
            33: dout <= 16'hB3_80;  // THL_ST
            // mystery scaling numbers
            34: dout <= 16'h70_3A;
            35: dout <= 16'h71_35;
            36: dout <= 16'h72_11;
            37: dout <= 16'h73_F1;
            38: dout <= 16'hA2_02;
            // gamma curve values
            39: dout <= 16'h7A_20;
            40: dout <= 16'h7B_10;
            41: dout <= 16'h7C_1E;
            42: dout <= 16'h7D_35;
            43: dout <= 16'h7E_5A;
            44: dout <= 16'h7F_69;
            45: dout <= 16'h80_76;
            46: dout <= 16'h81_80;
            47: dout <= 16'h82_88;
            48: dout <= 16'h83_8F;
            49: dout <= 16'h84_96;
            50: dout <= 16'h85_A3;
            51: dout <= 16'h86_AF;
            52: dout <= 16'h87_C4;
            53: dout <= 16'h88_D7;
            54: dout <= 16'h89_E8;
            // AGC / AEC
            55: dout <= 16'h13_E0;  // COM8, disable AGC/AEC
            56: dout <= 16'h00_00;  // GAIN = 0
            57: dout <= 16'h10_00;  // AECH
            58: dout <= 16'h0D_40;  // COM4
            59: dout <= 16'h14_18;  // COM9
            60: dout <= 16'hA5_05;  // BD50MAX
            61: dout <= 16'hAB_07;  // BD60MAX
            62: dout <= 16'h24_95;  // AEW
            63: dout <= 16'h25_33;  // AEB
            64: dout <= 16'h26_E3;  // VPT
            65: dout <= 16'h9F_78;  // HAECC1
            66: dout <= 16'hA0_68;  // HAECC2
            67: dout <= 16'hA1_03;  // magic
            68: dout <= 16'hA6_D8;  // HAECC3
            69: dout <= 16'hA7_D8;  // HAECC4
            70: dout <= 16'hA8_F0;  // HAECC5
            71: dout <= 16'hA9_90;  // HAECC6
            72: dout <= 16'hAA_94;  // HAECC7
            73: dout <= 16'h13_E7;  // COM8, enable AGC/AEC
            74: dout <= 16'h69_07;  // GFIX tweak
            default: dout <= 16'hFF_FF;  // mark end of ROM
        endcase
    end
endmodule
