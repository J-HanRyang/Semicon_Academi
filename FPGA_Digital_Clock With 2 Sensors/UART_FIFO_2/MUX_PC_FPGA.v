`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/22
// Design Name      : MUX_PC_FPGA
// Module Name      : Project_UART
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Select PC_FPGA Mode
//////////////////////////////////////////////////////////////////////////////////


module MUX_PC_FPGA(
    input           iMode,

    input           iPC_Set,
    input   [4:0]   iPC_Mode,
    input           iPC_Btn_U,
    input           iPC_Btn_D,
    input           iPC_Btn_L,
    input           iPC_Btn_R,

    input           iFPGA_Set,
    input   [4:0]   iFPGA_Mode,
    input           iFPGA_Btn_U,
    input           iFPGA_Btn_D,
    input           iFPGA_Btn_L,
    input           iFPGA_Btn_R,

    output          oSet,
    output  [4:0]   oMode,
    output          oBtn_U,
    output          oBtn_D,
    output          oBtn_R,
    output          oBtn_L
    );

    assign  oSet    = iMode ? iPC_Set   : iFPGA_Set;
    assign  oMode   = iMode ? iPC_Mode  : iFPGA_Mode;
    assign  oBtn_U  = iMode ? iPC_Btn_U : iFPGA_Btn_U;
    assign  oBtn_D  = iMode ? iPC_Btn_D : iFPGA_Btn_D;
    assign  oBtn_L  = iMode ? iPC_Btn_L : iFPGA_Btn_L;
    assign  oBtn_R  = iMode ? iPC_Btn_R : iFPGA_Btn_R;
    
endmodule
