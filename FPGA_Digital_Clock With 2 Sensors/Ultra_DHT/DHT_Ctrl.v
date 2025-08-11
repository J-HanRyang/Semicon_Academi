`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/07/25
// Design Name      : Project_Sensor
// Module Name      : DHT_Ctrl
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Temp / Humid Sensor
//
// Revision 	    : 25/07/17      Error State Add
//////////////////////////////////////////////////////////////////////////////////

module DHT_Ctrl(
    input           iClk,
    input           iRst,

    input           iDHT,
    input           iStart,
    inout           ioDHT,
    input           iTick_10us,

    output  [7:0]   oHumid_int,
    output  [7:0]   oHumid_Dec,
    output  [7:0]   oTemp_int,
    output  [7:0]   oTemp_Dec,

    output          oDone
    );

    // Parameter
    parameter       p_Idle  = 0,
                    p_Start = 1,
                    p_Wait  = 2,
                    p_SyncL = 3,
                    p_SyncH = 4,
                    p_Data  = 5,
                    p_Check = 6,
                    p_Error = 7;

    parameter       TICK        = 1_800,
                    WIDTH       = $clog2(TICK),
                    TIME_OVER   = 2_000,
                    AUTOSTART   = $clog2(100_000);

    // Reg & Wire
    reg                 riDHT_Prev; // Rx
    reg                 riDHT_sync1;
    reg                 riDHT_sync2;
    wire                wiDHT_Raw;
    wire                wiDHT;

    reg                 roEn_Cur;       // 1 : Tx, 0 : Rx
    reg                 roEn_Nxt;

    reg                 roDHT_Cur;      // Tx
    reg                 roDHT_Nxt;
    

    reg     [2:0]       rState_Cur;
    reg     [2:0]       rState_Nxt;

    reg     [WIDTH-1:0] rTick_Cur;
    reg     [WIDTH-1:0] rTick_Nxt;

    reg     [5:0]       rCount_Cur;
    reg     [5:0]       rCount_Nxt;

    reg     [39:0]      rData_Cur;
    reg     [39:0]      rData_Nxt;

    reg     [AUTOSTART-1:0] rAutostart_Cur;
    reg     [AUTOSTART-1:0] rAutostart_Nxt;

    wire                wValid;

    // assign inout
    assign  ioDHT       = roEn_Cur  ? roDHT_Cur : 1'bz;
    assign  wiDHT_Raw   = ioDHT;
    assign  wiDHT       = riDHT_sync2;

    // Metastable Synchronizer
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            riDHT_sync1 <= 1;
            riDHT_sync2 <= 1;
        end else
        begin
            riDHT_sync1 <= wiDHT_Raw;
            riDHT_sync2 <= riDHT_sync1;
        end
    end

    /***********************************************
    // FSM 
    ***********************************************/
    // Current State Update
    always  @(posedge iClk, posedge iRst)
    begin
        if  (iRst)
        begin
            rState_Cur  <= p_Idle;
            rTick_Cur   <= 0;
            rCount_Cur  <= 0;
            riDHT_Prev  <= 0;
            rData_Cur   <= 0;
            roEn_Cur    <= 1;
            roDHT_Cur   <= 1;
            rAutostart_Cur <= 0;
        end else
        begin
            rState_Cur  <= rState_Nxt;
            rTick_Cur   <= rTick_Nxt;
            rCount_Cur  <= rCount_Nxt;
            riDHT_Prev  <= wiDHT;
            rData_Cur   <= rData_Nxt;
            roEn_Cur    <= roEn_Nxt;
            roDHT_Cur   <= roDHT_Nxt;
            rAutostart_Cur <= rAutostart_Nxt;
        end
    end

    // Next State Decision
    always  @(*)
    begin
        rState_Nxt  = rState_Cur;
        rTick_Nxt   = rTick_Cur;
        rCount_Nxt  = rCount_Cur;
        rData_Nxt   = rData_Cur;
        roEn_Nxt    = roEn_Cur;
        roDHT_Nxt   = roDHT_Cur;
        rAutostart_Nxt = rAutostart_Cur;    

        case (rState_Cur)
            p_Idle  :
            begin
                if  (iStart && iDHT)
                begin
                    rState_Nxt  = p_Start;
                    roEn_Nxt    = 1;
                    roDHT_Nxt   = 0;
                end else
                    rState_Nxt  = rState_Cur;

                if  (iTick_10us)
                begin
                    rAutostart_Nxt = rAutostart_Cur + 1;
                    if  (rAutostart_Cur >= 100_000)
                    begin
                        rState_Nxt     = p_Start;
                        rAutostart_Nxt = 0;
                        roEn_Nxt    = 1;
                        roDHT_Nxt   = 0;
                    end
                end
            end

            p_Start :
            begin
                if  (iTick_10us)
                begin
                    if  (rTick_Cur >= (TICK - 1))
                    begin
                        rTick_Nxt   = 0;
                        rState_Nxt  = p_Wait;
                        roDHT_Nxt   = 1;
                    end else
                    begin
                        rTick_Nxt   = rTick_Cur + 1;
                    end
                end else
                    rState_Nxt  = rState_Cur;
            end

            p_Wait  :
            begin
                if  (iTick_10us)              
                begin
                    if  (rTick_Cur  >= 2)
                    begin
                        rTick_Nxt   = 0;
                        rState_Nxt  = p_SyncL;
                        roEn_Nxt    = 0;
                    end else
                        rTick_Nxt   = rTick_Cur + 1;
                end else
                    rState_Nxt  = rState_Cur;
            end

            p_SyncL :
            begin
                if  (iTick_10us)
                    rTick_Nxt   = rTick_Cur + 1;
                else
                    rTick_Nxt   = rTick_Cur;

                if  (!riDHT_Prev && wiDHT && (rTick_Cur  >= 5))
                begin
                    rState_Nxt  = p_SyncH;
                    rTick_Nxt   = 0;
                end else
                    rState_Nxt  = rState_Cur;
            end

            p_SyncH :
            begin
                if  (iTick_10us)
                    rTick_Nxt   = rTick_Cur + 1;
                else
                    rTick_Nxt   = rTick_Cur;

                if  (riDHT_Prev && !wiDHT && (rTick_Cur >= 5))
                begin
                    rState_Nxt  = p_Data;
                    rTick_Nxt   = 0;
                end else
                    rState_Nxt  = rState_Cur;
            end

            p_Data  :
            begin
                if  (iTick_10us)
                begin
                    if  (wiDHT)
                        rTick_Nxt   = rTick_Cur + 1;
                    else
                        rTick_Nxt  = rTick_Cur;
                end else
                    rTick_Nxt   = rTick_Cur;

                if  (riDHT_Prev && !wiDHT)
                begin
                    if  (rCount_Cur == 39)
                    begin
                        rState_Nxt  = p_Check;
                        rCount_Nxt  = 0;
                        rTick_Nxt   = 0;
                    end else
                    begin
                        rState_Nxt  = p_Data;
                        rCount_Nxt  = rCount_Cur + 1;
                        rTick_Nxt   = 0;
                    end

                    if  (rTick_Cur >= 4)
                        rData_Nxt   = {rData_Cur[38:0],1'b1};
                    else
                        rData_Nxt   = {rData_Cur[38:0],1'b0};
                end else
                    rCount_Nxt  = rCount_Cur;
            end

            p_Check :
            begin
                if  (wValid == 1)
                begin
                    rState_Nxt  = p_Idle;
                    roEn_Nxt    = 1;
                    roDHT_Nxt   = 1;
                end else
                begin
                    rState_Nxt  = p_Error;
                    rTick_Nxt   = 0;
                end
            end

            p_Error :
            begin
                if (iStart)
                    rState_Nxt  = p_Idle;
                else
                    rState_Nxt  = rState_Cur;

                if (iTick_10us)
                begin
                    rAutostart_Nxt = rAutostart_Cur + 1;
                    if  (rAutostart_Cur >= 1_000)
                    begin
                        rState_Nxt      = p_Idle;
                        rTick_Nxt       = 0;
                        rCount_Nxt      = 0;
                        rData_Nxt       = 0;
                        rAutostart_Nxt  = 0;
                    end
                end
            end

            default: ;
        endcase
    end

    // Output
    assign  oHumid_int  =   rData_Cur[39:32];
    assign  oHumid_Dec  =   rData_Cur[31:24];
    assign  oTemp_int   =   rData_Cur[23:16];
    assign  oTemp_Dec   =   rData_Cur[15:8];
    assign  wValid      =   rState_Cur  == p_Check  &&
                            (rData_Cur[7:0] == (rData_Cur[39:32] + 
                                                rData_Cur[31:24] + 
                                                rData_Cur[23:16] + 
                                                rData_Cur[15:8]     ))  ? 1'b1 : 1'b0;
    assign  oDone       =   (rState_Cur == p_Check) && wValid           ? 1'b1 : 1'b0;

endmodule