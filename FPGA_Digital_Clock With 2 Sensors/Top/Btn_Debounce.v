`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/08
// Design Name      : Counter_FSM
// Module Name      : Btn_Debounce
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Debounce --> Tick
//
// Revision 	    : 2025/07/08    --Start--
//                    2025/07/10    --Finish--
//                    2025/07/17    Add parameter
//////////////////////////////////////////////////////////////////////////////////


module Btn_Debounce(
    input               iClk,
    input               iRst,

    input               iBtn,

    output              oBtn
    );

    // Parameter
    parameter           COUNT   = 100_000,
                        WIDTH   = $clog2(COUNT),
                        SHIFT   = 10;
    // Reg & Wire
    reg     [SHIFT-1:0] rReg;
    reg     [SHIFT-1:0] rNext;

    reg                 rBtn;
    reg                 rEdge_reg;

    wire                wDebounce;

    reg     [WIDTH-1:0] rCounter;
    reg                 rDB_Clk;


    // Clk Diveder 1Mhz
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            rCounter    <= 0;
            rDB_Clk     <= 0;
        end
        else
        begin
            if  (rCounter == COUNT)
            begin
                rCounter    <= 0;
                rDB_Clk     <= 1'b1;
            end else
            begin
                rCounter    <= rCounter + 1'b1;
                rDB_Clk     <= 1'b0;
            end
        end
    end

    // Shift_Register
    always  @(posedge rDB_Clk, posedge iRst)
    begin
        if  (iRst)
            rReg        <= 0;
        else
            rReg        <= rNext;
    end

    always  @(*)
    begin
        rNext   = {iBtn, rReg[SHIFT-1:1]};
    end

    // AND4 Logic
    assign  wDebounce   = &rReg;

    // Edge_Detector, Shift Logic(SIPO)
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
            rEdge_reg   <= 1'b0;
        else
            rEdge_reg   <= wDebounce;
    end

    assign  oBtn    = ~rEdge_reg & wDebounce;
    
endmodule
