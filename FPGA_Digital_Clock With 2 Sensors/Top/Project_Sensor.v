`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/24
// Design Name      : Project_Sensor
// Module Name      : Project_Sensor
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Final Project Top Module
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////

module Project_Sensor(
    // Clock & Reset
    input           iClk,
    input           iRst,

    // FPGA or PC
    input           iMode,

    // FPGA SW / Button
    input           iFPGA_Set,
    input   [4:0]   iFPGA_Mode,      // 0 : Hour / Sec, 1 : SW, 2 : Timer, 3 : Ultra, 4 : Temp/Humid
    input           iFPGA_Btn_U,
    input           iFPGA_Btn_D,
    input           iFPGA_Btn_R,
    input           iFPGA_Btn_L,

    // UART_FIFO
    input           iRx,
    output          oTx,

    // FND
    output  [3:0]   oFnd_Com,
    output  [7:0]   oFnd_Data,
    output  [3:0]   oLed_Alarm,
    output  [9:0]   oLed,

    // Ultra_Sensor
    input           iEcho,
    output          oTrig,

    // DHT_Sensor
    inout           ioDHT
    );


    /***********************************************
    // Reg & Wire
    ***********************************************/
   
    // FPGA Butten / SW
    wire            wFPGA_Set;
    wire    [4:0]   wFPGA_Mode;
    wire            wFPGA_Btn_U;
    wire            wFPGA_Btn_D;
    wire            wFPGA_Btn_L;
    wire            wFPGA_Btn_R;

    // PC Button / SW
    wire            wPC_Set;
    wire    [4:0]   wPC_Mode;
    wire            wPC_Btn_U;
    wire            wPC_Btn_D;
    wire            wPC_Btn_L;
    wire            wPC_Btn_R;

    // PC_FPGA Select
    wire            wSet;
    wire    [4:0]   wMode;
    wire            wBtn_U;
    wire            wBtn_D;
    wire            wBtn_L;
    wire            wBtn_R;

    // Decoder
    wire            wTime_En;

    // Clock & Sensor
    wire    [3:0]   wDigit_Hour_10;
    wire    [3:0]   wDigit_Hour_1;
    wire    [3:0]   wDigit_Min_10;
    wire    [3:0]   wDigit_Min_1;
    wire    [3:0]   wDigit_Sec_10;
    wire    [3:0]   wDigit_Sec_1;    
    
    // Encoder
    wire    [7:0]   wAscii_Hour_10;
    wire    [7:0]   wAscii_Hour_1;
    wire    [7:0]   wAscii_Min_10;
    wire    [7:0]   wAscii_Min_1;
    wire    [7:0]   wAscii_Sec_10;
    wire    [7:0]   wAscii_Sec_1;    
    
    // UART_FIFO
    wire    [7:0]   wRx_Data;
    wire    [7:0]   wAscii_data;
    wire    [7:0]   wAscii_DHT11, wAscii_CTS, wAscii_ULTRA;
    wire            wTx_Push, wTx_CTS_Push, wTx_ULTRA_Push, wTx_UHT11_Push;
    wire            wTx_Full;
    wire    [7:0]   wTx_Data;
    //UART BTN 
    wire    [7:0]   w_btn_data;
    wire    [7:0]   w_uart_data;
    wire            w_en_btn;

    /***********************************************
    // Instantiation
    ***********************************************/
    //FPGA Button press sent to pc 
    btn_uart_message U_BTN_UART_MESSAGE(
        .iClk           (iClk),
        .iRst           (iRst),
        .iRx_Data       (wRx_Data),
        .iAscii_Hour_10 (wAscii_Hour_10),
        .iAscii_Hour_1  (wAscii_Hour_1),
        .iAscii_Min_10  (wAscii_Min_10),
        .iAscii_Min_1   (wAscii_Min_1),
        .iAscii_Sec_10  (wAscii_Sec_10),
        .iAscii_Sec_1   (wAscii_Sec_1),
        .iSet           (wSet),
        .iMode          (wMode[4:1]),
        .iBtn_U         (wBtn_U),
        .iBtn_D         (wBtn_D),
        .iBtn_R         (wBtn_R),
        .iBtn_L         (wBtn_L),
        .oBtn_data      (wTx_Data),
        .en_btn         (wTx_Push)
    );

    
    // Butten Debouncer
    Btn_Debounce    U_Btn_U     (
        .iClk           (iClk),
        .iRst           (iRst),
        .iBtn           (iFPGA_Btn_U),
        .oBtn           (wFPGA_Btn_U)
    );

    Btn_Debounce    U_Btn_D     (
        .iClk           (iClk),
        .iRst           (iRst),
        .iBtn           (iFPGA_Btn_D),
        .oBtn           (wFPGA_Btn_D)
    );

    Btn_Debounce    U_Btn_L     (
        .iClk           (iClk),
        .iRst           (iRst),
        .iBtn           (iFPGA_Btn_L),
        .oBtn           (wFPGA_Btn_L)
    );

    Btn_Debounce    U_Btn_R     (
        .iClk           (iClk),
        .iRst           (iRst),
        .iBtn           (iFPGA_Btn_R),
        .oBtn           (wFPGA_Btn_R)
    );
    // UART_FIFO
        
    UART_FIFO       U_UART_FIFO (
        .iClk           (iClk),
        .iRst           (iRst),
        .iRx            (iRx),
        .oTx            (oTx),
        .iRx_Pop        (),
        .oRx_Data       (wRx_Data),
        .iTx_Push       (wTx_Push),
        .iTx_Data       (wTx_Data),
        .oTx_Busy       (),
        .oTx_Full       (wTx_Full)
    );

    // ASCII Docoder
    Decoder         U_Decoder   (
        .iClk           (iClk),
        .iRst           (iRst),
        .iAscii         (wRx_Data),
        .oSet           (wPC_Set),
        .oMode          (wPC_Mode),
        .oBtn_U         (wPC_Btn_U),
        .oBtn_D         (wPC_Btn_D),
        .oBtn_L         (wPC_Btn_L),
        .oBtn_R         (wPC_Btn_R),
        .oTime_En       (wTime_En)
    );

    // Select PC_FPGA
    MUX_PC_FPGA     U_Select    (
        .iMode          (iMode),
        .iPC_Set        (wPC_Set),
        .iPC_Mode       (wPC_Mode),
        .iPC_Btn_U      (wPC_Btn_U),
        .iPC_Btn_D      (wPC_Btn_D),
        .iPC_Btn_L      (wPC_Btn_L),
        .iPC_Btn_R      (wPC_Btn_R),
        .iFPGA_Set      (iFPGA_Set),
        .iFPGA_Mode     (iFPGA_Mode),
        .iFPGA_Btn_U    (wFPGA_Btn_U),
        .iFPGA_Btn_D    (wFPGA_Btn_D),
        .iFPGA_Btn_L    (wFPGA_Btn_L),
        .iFPGA_Btn_R    (wFPGA_Btn_R),
        .oSet           (wSet),
        .oMode          (wMode),
        .oBtn_U         (wBtn_U),
        .oBtn_D         (wBtn_D),
        .oBtn_L         (wBtn_L),
        .oBtn_R         (wBtn_R)
    );

    // Digital Clock & SenSor
    Sensor_Clock   U_Sensor_Clock   (
        .iClk           (iClk),
        .iRst           (iRst),
        .iSet           (wSet),
        .iMode          (wMode),
        .iBtn_U         (wBtn_U),
        .iBtn_D         (wBtn_D),
        .iBtn_L         (wBtn_L),
        .iBtn_R         (wBtn_R),
        .oFnd_Com       (oFnd_Com),
        .oFnd_Data      (oFnd_Data),
        .oLed_Alarm     (oLed_Alarm),
        .oLed           (oLed),
        .oDigit_Hour_10 (wDigit_Hour_10),
        .oDigit_Hour_1  (wDigit_Hour_1),
        .oDigit_Min_10  (wDigit_Min_10),
        .oDigit_Min_1   (wDigit_Min_1),
        .oDigit_Sec_10  (wDigit_Sec_10),
        .oDigit_Sec_1   (wDigit_Sec_1),
        .iEcho          (iEcho),
        .oTrig          (oTrig),
        .ioDHT          (ioDHT)
    );
    
    // Encoder
    Encoder         U_EnHour_10 (
        .iClk           (iClk),
        .iRst           (iRst),
        .iDec           (wDigit_Hour_10),
        .oAscii         (wAscii_Hour_10)
    );

    Encoder         U_EnHour_1  (
        .iClk           (iClk),
        .iRst           (iRst),
        .iDec           (wDigit_Hour_1),
        .oAscii         (wAscii_Hour_1)
    );

    Encoder         U_EnMin_10  (
        .iClk           (iClk),
        .iRst           (iRst),
        .iDec           (wDigit_Min_10),
        .oAscii         (wAscii_Min_10)
    );

    Encoder         U_EnMin_1   (
        .iClk           (iClk),
        .iRst           (iRst),
        .iDec           (wDigit_Min_1),
        .oAscii         (wAscii_Min_1)
    );

    Encoder         U_EnSec_10  (
        .iClk           (iClk),
        .iRst           (iRst),
        .iDec           (wDigit_Sec_10),
        .oAscii         (wAscii_Sec_10)
    );

    Encoder         U_EnSec_1   (
        .iClk           (iClk),
        .iRst           (iRst),
        .iDec           (wDigit_Sec_1),
        .oAscii         (wAscii_Sec_1)
    );

endmodule