`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date      : 2025/07/09
// Design Name      : Project_Clock
// Module Name      : Fnd_Controller
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Digit_Spliter + BCD Decoder
//
// Revision         : 2025/07/03    Calculator      --Finish--
//                    2025/07/04    Counter         --Finish--
//                    2025/07/09    Stop_Watch      --Start--
//                    2025/07/10    Mux_2X1         --> Mux_4X1
//                                  Mod4_Counter    --> Mod8_Counter
//                                  (Add) Dot_Comp     
//                    2025/07/11    Stop_Watch      --Finish--
//                    2025/07/12    Project_Clock   --Finish--
//                    
//////////////////////////////////////////////////////////////////////////////////

module Fnd_Controller(
    // Clock & Reset
    input           iClk,
    input           iRst,

    // Mode_Select
    input   [1:0]   iSet,
    input   [4:0]   iMode,
    input           iEnd,

    input   [31:0]  iData,

    // Output
    output  [7:0]   oFnd_Data,
    output  [3:0]   oFnd_Com,

    output  [3:0]   oLed_Alarm,
    output  [9:0]   oLed,

    //ASCII Encoder
    output  [3:0]   oDigit_Hour_10,
    output  [3:0]   oDigit_Hour_1,
    output  [3:0]   oDigit_Min_10,
    output  [3:0]   oDigit_Min_1,
    output  [3:0]   oDigit_Sec_10,
    output  [3:0]   oDigit_Sec_1
);

    /***********************************************
    // Reg & Wire
    ***********************************************/
    wire            wClk_1kHz;
    wire            wTick_100Hz;
    wire    [6:0]   wmSec;

    wire    [2:0]   wSel;

    wire    [3:0]   wDigit_mSec_1;
    wire    [3:0]   wDigit_mSec_10;
    wire    [3:0]   wDigit__off_mSec_1;
    wire    [3:0]   wDigit__off_mSec_10;

    wire    [3:0]   wDigit_Sec_1;
    wire    [3:0]   wDigit_Sec_10;
    wire    [3:0]   wDigit_off_Sec_1;
    wire    [3:0]   wDigit_off_Sec_10;

    wire    [3:0]   wDigit_Min_1;
    wire    [3:0]   wDigit_Min_10;

    wire    [3:0]   wDigit_Hour_1;
    wire    [3:0]   wDigit_Hour_10;

    wire    [3:0]   wDigit_Ultra_1;
    wire    [3:0]   wDigit_Ultra_10;
    wire    [3:0]   wDigit_Ultra_100;     

    wire    [3:0]   wDigit_Temp_Dec_1;
    wire    [3:0]   wDigit_Temp_Dec_10;

    wire    [3:0]   wDigit_Temp_int_1;
    wire    [3:0]   wDigit_Temp_int_10;

    wire    [3:0]   wDigit_Humid_Dec_1;
    wire    [3:0]   wDigit_Humid_Dec_10;

    wire    [3:0]   wDigit_Humid_int_1;
    wire    [3:0]   wDigit_Humid_int_10;

    wire    [3:0]   wBCD_Sec_mSec;
    wire    [3:0]   wBCD_Hour_Min;
    wire    [3:0]   wBCD_Set_Hour;
    wire    [3:0]   wBCD_Set_Min;
    wire    [3:0]   wBCD_Set_Sec;
    wire    [3:0]   wBCD_Ultra;
    wire    [3:0]   wBCD_Temp;
    wire    [3:0]   wBCD_Humid;
    wire    [3:0]   wSet;

    wire            wDot;

    wire    [3:0]   wBCD_Data;
    
    wire    [3:0]   wDigit_0;
    wire    [3:0]   wDigit_1;
    wire    [3:0]   wDigit_2;
    wire    [3:0]   wDigit_3;
    wire    [3:0]   wDigit_4;
    wire    [3:0]   wDigit_5;


    /***********************************************
    // Output
    ***********************************************/
    assign  oDigit_Hour_10  = wDigit_0;
    assign  oDigit_Hour_1   = wDigit_1;
    assign  oDigit_Min_10   = wDigit_2;
    assign  oDigit_Min_1    = wDigit_3;
    assign  oDigit_Sec_10   = wDigit_4;
    assign  oDigit_Sec_1    = wDigit_5;


    /***********************************************
    // Instantiation
    ***********************************************/

    // Clk Div
    Clk_Div_1kHz    U_Clk_1kHz  (
        .iClk               (iClk),
        .iRst               (iRst),
        .oClk_1kHz          (wClk_1kHz)
    );

    // Tick_gen
    Tick_gen_100Hz  U_Tick_100Hz    (
        .iClk               (iClk),
        .iRst               (iRst),
        .iRun_Stop          (1'b1),
        .iClear             (1'b0),
        .oTick              (wTick_100Hz)
    );

    // Counter
    Tick_Counter    #           (
        .TICK_COUNT         (100),
        .WIDTH              ($clog2(100)),
        .INIT_TIME          (0)
    )   U_CLK_mSec          (
        .iClk               (iClk),
        .iRst               (iRst),
        .iClear             (1'b0),
        .iDown              (1'b0),
        .iInc               (),
        .iDec               (),
        .iTick              (wTick_100Hz),
        .oTime              (wmSec),
        .oTick              ()
    );

    // Mod8_Counter
    Mod8_Counter    U_MOD8      (
        .iClk               (wClk_1kHz),
        .iRst               (iRst),
        .oSel               (wSel)
    );

    // Decoder for Segment7
    Decoder_2X4     U_Decoder   (
        .iSel               (wSel[1:0]),
        .oFnd_Com           (oFnd_Com)
    );

    // Hour_Min / Sec_mSec Select
    Mux_Seg7        U_Mux       (
    .iMode                  ({iMode[4:3], iMode[0]}),
    .iSet                   (iSet),
    .iDigit_Hour_Min        (wBCD_Hour_Min),
    .iDigit_Sec_mSec        (wBCD_Sec_mSec),
    .iDigit_Set_Hour        (wBCD_Set_Hour),
    .iDigit_Set_Min         (wBCD_Set_Min),
    .iDigit_Set_Sec         (wBCD_Set_Sec),
    .iDigit_Ultra           (wBCD_Ultra),
    .iDigit_Temp            (wBCD_Temp),
    .iDigit_Humid           (wBCD_Humid),
    .oBCD_Data              (wBCD_Data)
    );

    // Digit_Spliter - BCD_Decoder
    Mux_8X1         U_Hour_Min  (
        .iSel               (wSel),
        .iDigit_1           (wDigit_Min_1),
        .iDigit_10          (wDigit_Min_10),
        .iDigit_100         (wDigit_Hour_1),
        .iDigit_1000        (wDigit_Hour_10),
        .iDigit_off_1       (4'he),
        .iDigit_off_10      (4'he),
        .iDigit_off_100     ({3'b111,wDot}),
        .iDigit_off_1000    (4'he),
        .oBCD_Data          (wBCD_Hour_Min)
    );

    Mux_8X1         U_Sec_mSec  (
        .iSel               (wSel),
        .iDigit_1           (wDigit_mSec_1),
        .iDigit_10          (wDigit_mSec_10),
        .iDigit_100         (wDigit_Sec_1),
        .iDigit_1000        (wDigit_Sec_10),
        .iDigit_off_1       (4'he),
        .iDigit_off_10      (4'he),
        .iDigit_off_100     ({3'b111,wDot}),
        .iDigit_off_1000    (4'he),
        .oBCD_Data          (wBCD_Sec_mSec)
    );

    Mux_8X1         U_Set_Hour  (
        .iSel               ({wDot,wSel[1:0]}),
        .iDigit_1           (wDigit_Min_1),
        .iDigit_10          (wDigit_Min_10),
        .iDigit_100         (wDigit_Hour_1),
        .iDigit_1000        (wDigit_Hour_10),
        .iDigit_off_1       (wDigit_Min_1),
        .iDigit_off_10      (wDigit_Min_10),
        .iDigit_off_100     (4'he),
        .iDigit_off_1000    (4'he),
        .oBCD_Data          (wBCD_Set_Hour)
    );

    Mux_8X1         U_Set_Min  (
        .iSel               ({wDot,wSel[1:0]}),
        .iDigit_1           (wDigit_Min_1),
        .iDigit_10          (wDigit_Min_10),
        .iDigit_100         (wDigit_Hour_1),
        .iDigit_1000        (wDigit_Hour_10),
        .iDigit_off_1       (4'he),
        .iDigit_off_10      (4'he),
        .iDigit_off_100     (wDigit_Hour_1),
        .iDigit_off_1000    (wDigit_Hour_10),
        .oBCD_Data          (wBCD_Set_Min)
    );

    Mux_8X1         U_Set_Sec   (
        .iSel               ({wDot,wSel[1:0]}),
        .iDigit_1           (wDigit_mSec_1),
        .iDigit_10          (wDigit_mSec_10),
        .iDigit_100         (wDigit_Sec_1),
        .iDigit_1000        (wDigit_Sec_10),
        .iDigit_off_1       (wDigit_mSec_1),
        .iDigit_off_10      (wDigit_mSec_10),
        .iDigit_off_100     (4'he),
        .iDigit_off_1000    (4'he),
        .oBCD_Data          (wBCD_Set_Sec)
    );

    Mux_8X1         U_Ultra     (
        .iSel               (wSel),
        .iDigit_1           (wDigit_Ultra_1),
        .iDigit_10          (wDigit_Ultra_10),
        .iDigit_100         (wDigit_Ultra_100),
        .iDigit_1000        (4'h0),
        .iDigit_off_1       (wDigit_Ultra_1),
        .iDigit_off_10      (wDigit_Ultra_10),
        .iDigit_off_100     (wDigit_Ultra_100),
        .iDigit_off_1000    (4'h0),
        .oBCD_Data          (wBCD_Ultra)
    );

    Mux_8X1         U_Temp      (
        .iSel               (wSel),
        .iDigit_1           (wDigit_Temp_Dec_1),
        .iDigit_10          (wDigit_Temp_Dec_10),
        .iDigit_100         (wDigit_Temp_int_1),
        .iDigit_1000        (wDigit_Temp_int_10),
        .iDigit_off_1       (4'he),
        .iDigit_off_10      (4'he),
        .iDigit_off_100     ({3'b111,wDot}),
        .iDigit_off_1000    (4'he),
        .oBCD_Data          (wBCD_Temp)
    );

    Mux_8X1         U_Humid     (
        .iSel               (wSel),
        .iDigit_1           (wDigit_Humid_Dec_1),
        .iDigit_10          (wDigit_Humid_Dec_10),
        .iDigit_100         (wDigit_Humid_int_1),
        .iDigit_1000        (wDigit_Humid_int_10),
        .iDigit_off_1       (4'he),
        .iDigit_off_10      (4'he),
        .iDigit_off_100     ({3'b111,wDot}),
        .iDigit_off_1000    (4'he),
        .oBCD_Data          (wBCD_Humid)
    );

    
    // Segment7
    BCD_Decoder     U_BCD       (
        .iBcd               (wBCD_Data),
        .oFnd_Data          (oFnd_Data)
    );

    // Led
    Mode_Led        U_Mode_Led  (
        .iMode              (iMode),
        .oLed               (oLed)
    );

    // Digit_Spliter
    Digit_Spliter           #   (
        .DS_WIDTH           (5)
    )       U_DS_Hour           (
        .iData              (iData[23:19]),
        .oDigit_1           (wDigit_Hour_1),
        .oDigit_10          (wDigit_Hour_10),
        .oDigit_100         ()
    );

    Digit_Spliter           #   (
        .DS_WIDTH           (6)
    )       U_DS_Min            (
        .iData              (iData[18:13]),
        .oDigit_1           (wDigit_Min_1),
        .oDigit_10          (wDigit_Min_10),
        .oDigit_100         ()
    );

    Digit_Spliter           #   (
        .DS_WIDTH           (6)
    )       U_DS_Sec            (
        .iData              (iData[12:7]),
        .oDigit_1           (wDigit_Sec_1),
        .oDigit_10          (wDigit_Sec_10),
        .oDigit_100         ()
    );

    Digit_Spliter           #   (
        .DS_WIDTH           (7)
    )       U_DS_mSec           (
        .iData              (iData[6:0]),
        .oDigit_1           (wDigit_mSec_1),
        .oDigit_10          (wDigit_mSec_10),
        .oDigit_100         ()
    );

    Digit_Spliter           #   (
        .DS_WIDTH           (9)
    )       U_DS_Ultra          (
        .iData              (iData[8:0]),
        .oDigit_1           (wDigit_Ultra_1),
        .oDigit_10          (wDigit_Ultra_10),
        .oDigit_100         (wDigit_Ultra_100)
    );

    Digit_Spliter           #   (
        .DS_WIDTH           (8)
    )       U_DS_Temp_Dec       (
        .iData              (iData[7:0]),
        .oDigit_1           (wDigit_Temp_Dec_1),
        .oDigit_10          (wDigit_Temp_Dec_10),
        .oDigit_100         ()
    );

    Digit_Spliter           #   (
        .DS_WIDTH           (8)
    )       U_DS_Temp_Int       (
        .iData              (iData[15:8]),
        .oDigit_1           (wDigit_Temp_int_1),
        .oDigit_10          (wDigit_Temp_int_10),
        .oDigit_100         ()
    );

    Digit_Spliter           #   (
        .DS_WIDTH           (8)
    )       U_DS_Humid_Dec      (
        .iData              (iData[23:16]),
        .oDigit_1           (wDigit_Humid_Dec_1),
        .oDigit_10          (wDigit_Humid_Dec_10),
        .oDigit_100         ()
    );

    Digit_Spliter           #   (
        .DS_WIDTH           (8)
    )       U_DS_Humid_Int      (
        .iData              (iData[31:24]),
        .oDigit_1           (wDigit_Humid_int_1),
        .oDigit_10          (wDigit_Humid_int_10),
        .oDigit_100         ()
    );

    // Dot_Comp
    Dot_Comp        U_Dot       (
        .imSec              (wmSec),
        .oDot               (wDot)
    );

    // Alarm
    Alarm           U_Alarm     (
        .iEnd               (iEnd),
        .iDot               (wDot),
        .oLed_Alarm         (oLed_Alarm)
    );

    // Mux Out
    Mux_Out         U_Mux_Out0  (
        .iClk               (iClk),
        .iRst               (iRst),
        .iMode              (iMode[4:1]),
        .iDigit_0           (wDigit_Hour_10),
        .iDigit_1           (wDigit_Min_10),
        .iDigit_2           (wDigit_Hour_10),
        .iDigit_3           (1'b0),
        .iDigit_4           (wDigit_Temp_int_10),
        .oDigit             (wDigit_0)
    );

    Mux_Out         U_Mux_Out1  (
        .iClk               (iClk),
        .iRst               (iRst),
        .iMode              (iMode[4:1]),
        .iDigit_0           (wDigit_Hour_1),
        .iDigit_1           (wDigit_Min_1),
        .iDigit_2           (wDigit_Hour_1),
        .iDigit_3           (wDigit_Ultra_100),
        .iDigit_4           (wDigit_Temp_int_1),
        .oDigit             (wDigit_1)
    );

    Mux_Out         U_Mux_Out2  (
        .iClk               (iClk),
        .iRst               (iRst),
        .iMode              (iMode[4:1]),
        .iDigit_0           (wDigit_Min_10),
        .iDigit_1           (wDigit_Sec_10),
        .iDigit_2           (wDigit_Min_10),
        .iDigit_3           (wDigit_Ultra_10),
        .iDigit_4           (wDigit_Temp_Dec_10),
        .oDigit             (wDigit_2)
    );

    Mux_Out         U_Mux_Out3  (
        .iClk               (iClk),
        .iRst               (iRst),
        .iMode              (iMode[4:1]),
        .iDigit_0           (wDigit_Min_1),
        .iDigit_1           (wDigit_Sec_1),
        .iDigit_2           (wDigit_Min_1),
        .iDigit_3           (wDigit_Ultra_1),
        .iDigit_4           (wDigit_Humid_int_10),
        .oDigit             (wDigit_3)
    );

    Mux_Out         U_Mux_Out4  (
        .iClk               (iClk),
        .iRst               (iRst),
        .iMode              (iMode[4:1]),
        .iDigit_0           (wDigit_Sec_10),
        .iDigit_1           (wDigit_mSec_10),
        .iDigit_2           (wDigit_Sec_10),
        .iDigit_3           (1'b0),
        .iDigit_4           (wDigit_Humid_int_1),
        .oDigit             (wDigit_4)
    );

    Mux_Out         U_Mux_Out5  (
        .iClk               (iClk),
        .iRst               (iRst),
        .iMode              (iMode[4:1]),
        .iDigit_0           (wDigit_Sec_1),
        .iDigit_1           (wDigit_mSec_1),
        .iDigit_2           (wDigit_Sec_1),
        .iDigit_3           (1'b0),
        .iDigit_4           (wDigit_Humid_Dec_10),
        .oDigit             (wDigit_5)
    );

endmodule


/**********************************************************************

SubModules

***********************************************************************/
module Mux_Out (
    input           iClk,
    input           iRst,

    input   [3:0]   iMode,
    input   [3:0]   iDigit_0,
    input   [3:0]   iDigit_1,
    input   [3:0]   iDigit_2,
    input   [3:0]   iDigit_3,
    input   [3:0]   iDigit_4,

    output  [3:0]   oDigit
);

    reg     [3:0]   rDigit;

    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
            rDigit  <= 0;
        else
        begin
            case (iMode)
                4'b0000 : rDigit <= iDigit_0;
                4'b0001 : rDigit <= iDigit_1;
                4'b0010 : rDigit <= iDigit_2;
                4'b0100 : rDigit <= iDigit_3;
                4'b1000 : rDigit <= iDigit_4;
                default : rDigit <= iDigit_0;
            endcase
        end
    end

    assign  oDigit  = rDigit;
    
endmodule

module Alarm(
    input           iEnd,
    input           iDot,

    output  [3:0]   oLed_Alarm
);

    assign  oLed_Alarm  =   (iEnd && iDot ) ? 4'b1010   :
                            (iEnd && !iDot) ? 4'b0101   :   4'b0000;
                            
endmodule


module Dot_Comp(
    input   [6:0]   imSec,
    
    output          oDot
);

    assign  oDot    = (imSec >= 50) ? 1'b1 : 1'b0;

endmodule


module Clk_Div_1kHz(
    input           iClk,
    input           iRst,

    output          oClk_1kHz
);

    // Reg & Wire
    reg             rClk_1kHz;

    reg     [16:0]  rClk;

    // 1kHz Clk
    always @(posedge iClk, posedge iRst)
    begin
        if (iRst)
        begin
            rClk        <= 0;
            rClk_1kHz   <= 0;
        end else
        begin
            if (rClk == 100_000 - 1)
            begin
                rClk        <= 0;
                rClk_1kHz   <= 1'b1;
            end else
            begin
                rClk        <= rClk + 1;
                rClk_1kHz   <= 1'b0; 
            end
        end            
    end
    
    assign  oClk_1kHz = rClk_1kHz;

endmodule


module Mod8_Counter(
    input           iClk,
    input           iRst,

    output  [2:0]   oSel
    );

    // Reg & Wire
    reg     [2:0]   rCounter;

    // Mod4 Counter
    always @(posedge iClk, posedge iRst)
    begin
        if (iRst)   begin
            rCounter    <= 3'b0;
        end else    begin
            rCounter    <= rCounter + 1;
        end 
    end

    // Output Connect
    assign  oSel = rCounter;

endmodule


module Decoder_2X4(
    input   [1:0]   iSel,

    output  [3:0]   oFnd_Com
);

    // Reg & Wire
    reg     [3:0]   rFnd_Com;
    
    // Decoder
    always @(*)
    begin
        case (iSel)
            2'b00   : rFnd_Com = 4'b1110;
            2'b01   : rFnd_Com = 4'b1101;
            2'b10   : rFnd_Com = 4'b1011;
            2'b11   : rFnd_Com = 4'b0111;
            default : rFnd_Com = 4'b0000;
        endcase
    end

    // Output Connect
    assign  oFnd_Com = rFnd_Com;

endmodule

module Mode_Led(
    input   [4:0]  iMode,

    output  [9:0]   oLed
);

    // Reg & Wire
    reg     [9:0]   rLed;
    
    // Decoder
    always @(*)
    begin
        case (iMode)
            5'h0    : rLed = 10'b00_0000_0001;  // Clock_Sec
            5'h1    : rLed = 10'b00_0000_0010;  // Clock_Hour
            5'h2    : rLed = 10'b00_0000_0100;  // Stop_Watch_Sec
            5'h3    : rLed = 10'b00_0000_1000;  // Stop_Watch_Hour
            5'h4    : rLed = 10'b00_0001_0000;  // Timer_Sec
            5'h5    : rLed = 10'b00_0010_0000;  // Timer_Hour
            5'h8    : rLed = 10'b00_0100_0000;  // Ultra
            5'h9    : rLed = 10'b00_1000_0000;  // Ultra
            5'h10   : rLed = 10'b01_0000_0000;  // DHT_Temp
            5'h11   : rLed = 10'b10_0000_0000;  // DHT_Humid
            default : rLed = 10'b00_0000_0000;
        endcase
    end

    // Output Connect
    assign  oLed    = rLed;

endmodule

module Mux_8X1(
    input   [2:0]   iSel,
    input   [3:0]   iDigit_1,
    input   [3:0]   iDigit_10,
    input   [3:0]   iDigit_100,
    input   [3:0]   iDigit_1000,
    input   [3:0]   iDigit_off_1,
    input   [3:0]   iDigit_off_10,
    input   [3:0]   iDigit_off_100,
    input   [3:0]   iDigit_off_1000,

    output  [3:0]   oBCD_Data
    );

    // Reg & Wire
    reg     [3:0]   rBCD_Data;

    // Mux
    always @(*)
    begin
        case (iSel)
            3'b000  : rBCD_Data = iDigit_1; 
            3'b001  : rBCD_Data = iDigit_10; 
            3'b010  : rBCD_Data = iDigit_100; 
            3'b011  : rBCD_Data = iDigit_1000;
            3'b100  : rBCD_Data = iDigit_off_1; 
            3'b101  : rBCD_Data = iDigit_off_10; 
            3'b110  : rBCD_Data = iDigit_off_100; 
            3'b111  : rBCD_Data = iDigit_off_1000; 
            default : rBCD_Data = iDigit_1;
        endcase
    end

    // Output Connect
    assign  oBCD_Data = rBCD_Data;

endmodule


module Mux_Seg7(
    input   [2:0]   iMode,
    input   [1:0]   iSet,
    input   [3:0]   iDigit_Hour_Min,
    input   [3:0]   iDigit_Sec_mSec,
    input   [3:0]   iDigit_Set_Hour,
    input   [3:0]   iDigit_Set_Min,
    input   [3:0]   iDigit_Set_Sec,
    input   [3:0]   iDigit_Ultra,
    input   [3:0]   iDigit_Temp,
    input   [3:0]   iDigit_Humid,

    output  [3:0]   oBCD_Data
    );

    // Reg & Wire
    reg     [3:0]   rBCD_Data;

    // Mux
    always @(*)
    begin
        case ({iMode,iSet})
            5'h0    : rBCD_Data = iDigit_Sec_mSec;
            5'h4    : rBCD_Data = iDigit_Hour_Min;
            5'h6    : rBCD_Data = iDigit_Set_Hour;
            5'h5    : rBCD_Data = iDigit_Set_Min;
            5'h3    : rBCD_Data = iDigit_Set_Sec;
            5'h7    : rBCD_Data = iDigit_Hour_Min;
            5'h8    : rBCD_Data = iDigit_Ultra;
            5'hc    : rBCD_Data = iDigit_Ultra;
            5'h10   : rBCD_Data = iDigit_Temp;      // Temp
            5'h14   : rBCD_Data = iDigit_Humid;     // Humid
            default : rBCD_Data = iDigit_Sec_mSec;

        endcase
    end

    // Output Connect
    assign  oBCD_Data   = rBCD_Data;

endmodule

module BCD_Decoder(
    input   [3:0]   iBcd,

    output  [7:0]   oFnd_Data
    );

    // Reg & Wire
    reg     [7:0]   rFnd_Data;

    // BCD_Decoder
    always @(iBcd)  begin
        case (iBcd)
            4'h0    : rFnd_Data = 8'hc0;
            4'h1    : rFnd_Data = 8'hf9;
            4'h2    : rFnd_Data = 8'ha4;
            4'h3    : rFnd_Data = 8'hb0;
            4'h4    : rFnd_Data = 8'h99;
            4'h5    : rFnd_Data = 8'h92;
            4'h6    : rFnd_Data = 8'h82;
            4'h7    : rFnd_Data = 8'hf8;
            4'h8    : rFnd_Data = 8'h80;
            4'h9    : rFnd_Data = 8'h90;
            4'he    : rFnd_Data = 8'hff;
            4'hf    : rFnd_Data = 8'h7f;
            default : rFnd_Data = 8'hc0;
        endcase
    end

    // Output connect
    assign  oFnd_Data = rFnd_Data;

endmodule


module Digit_Spliter    #(
    parameter               DS_WIDTH = 7
)   (
    input   [DS_WIDTH-1:0]  iData,

    output  [3:0]           oDigit_1,
    output  [3:0]           oDigit_10,
    output  [3:0]           oDigit_100
);

    assign  oDigit_1    =   iData       % 10;
    assign  oDigit_10   =   iData / 10  % 10;
    assign  oDigit_100  =   iData / 100 % 10;

endmodule