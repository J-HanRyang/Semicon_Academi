`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/15
// Design Name      : UART_FIFO
// Module Name      : Baud_Tick_Gen
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : 9600Hz Tick_Generator
//
// Revision         : 16X Divide
//////////////////////////////////////////////////////////////////////////////////

module Baud_Tick_Gen(
    input               iClk,
    input               iRst,

    output              oB_Tick
    );

    // Tick_bps = 9600
    // Parameter
    parameter           BARD    = 100_000_000/(9600*16),
                        WIDTH   = $clog2(BARD);
    
    // Reg & Wire
    reg     [WIDTH-1:0] Tick_Counter;
    reg                 r_Tick;

    // Tick_Counter
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            Tick_Counter    <= 0;
            r_Tick          <= 0;
        end else
        begin
            if (Tick_Counter == (BARD - 1))
            begin
                Tick_Counter    <= 0;
                r_Tick          <= 1;
            end else
            begin
                Tick_Counter    <= Tick_Counter + 1;
                r_Tick          <= 0;
            end
        end
    end

    // Output Decision
    assign  oB_Tick =   r_Tick;

endmodule
