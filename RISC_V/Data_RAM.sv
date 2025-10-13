`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/09/22
// Design Name      : RV32I
// Module Name      : Data_RAM
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : Data_RAM
//
// Revision 	    : 2025/09/22    RAM_Upgrade V1.1(Add Type Select)
//                  : 2025/09/23    Word Align -> Byte Align
//////////////////////////////////////////////////////////////////////////////////

module Data_RAM(
    input   logic           iClk,

    input   logic   [2:0]   iFunct3,
    input   logic           iData_WrEn,
    input   logic   [31:0]  iData_Addr,
    input   logic   [31:0]  iData_WrData,

    output  logic   [31:0]  oData_RdData
    );

    logic   [31:0]  rData_Mem[0:99];
    logic   [31:2]  wAddr_Word;
    logic   [1:0]   wAddr_Byte;
    logic   [31:0]  wRaw_RdData;

    assign  wAddr_Word  = iData_Addr[31:2];
    assign  wAddr_Byte  = iData_Addr[1:0];
    assign  wRaw_RdData = rData_Mem[wAddr_Word];

    // initial
    // begin
    //     for (int i = 0; i < 32 ; i++)
    //     begin
    //         rData_Mem[i] = 32'bx;
    //     end
    // end

    always_ff @(posedge iClk)
    begin
        if (iData_WrEn)
            case (iFunct3)
                3'b000  : 
                begin
                    case (wAddr_Byte)
                        2'b00   : rData_Mem[wAddr_Word][7:0]    <= iData_WrData[7:0];
                        2'b01   : rData_Mem[wAddr_Word][15:8]   <= iData_WrData[7:0];
                        2'b10   : rData_Mem[wAddr_Word][23:16]  <= iData_WrData[7:0];
                        2'b11   : rData_Mem[wAddr_Word][31:24]  <= iData_WrData[7:0];
                        default : rData_Mem[wAddr_Word][7:0]    <= iData_WrData[7:0];
                    endcase
                end

                3'b001  : 
                begin
                    case (wAddr_Byte[1])
                        1'b0    : rData_Mem[wAddr_Word][15:0]   <= iData_WrData[15:0];
                        1'b1    : rData_Mem[wAddr_Word][31:16]  <= iData_WrData[15:0];
                        default : rData_Mem[wAddr_Word][15:0]   <= iData_WrData[15:0];
                    endcase
                end

                3'b010  :
                    rData_Mem[wAddr_Word] <= iData_WrData;

                default : ;
            endcase
    end

    always_comb
    begin
        logic   [7:0]   wTemp_Byte;
        logic   [15:0]  wTemp_Half;

        oData_RdData = wRaw_RdData;

        case (iFunct3)
            3'b000  :
            begin
                case (wAddr_Byte)
                    2'b00   : wTemp_Byte = wRaw_RdData[7:0];
                    2'b01   : wTemp_Byte = wRaw_RdData[15:8];
                    2'b10   : wTemp_Byte = wRaw_RdData[23:16];
                    2'b11   : wTemp_Byte = wRaw_RdData[31:24];
                    default : wTemp_Byte = wRaw_RdData[7:0];
                endcase
                oData_RdData = {{24{wTemp_Byte[7]}}, wTemp_Byte};
            end

            3'b001  :
            begin
                case (wAddr_Byte[1])
                    1'b0    : wTemp_Half = wRaw_RdData[15:0];
                    1'b1    : wTemp_Half = wRaw_RdData[31:16];
                    default : wTemp_Half = wRaw_RdData[15:0];
                endcase
                oData_RdData = {{16{wTemp_Half[15]}}, wTemp_Half};
            end

            3'b100  :
            begin
                case (wAddr_Byte)
                    2'b00   : wTemp_Byte = wRaw_RdData[7:0];
                    2'b01   : wTemp_Byte = wRaw_RdData[15:8];
                    2'b10   : wTemp_Byte = wRaw_RdData[23:16];
                    2'b11   : wTemp_Byte = wRaw_RdData[31:24];
                    default : wTemp_Byte = wRaw_RdData[7:0];
                endcase
                oData_RdData = {{24{1'b0}}, wTemp_Byte};
            end

            3'b101  :
            begin
                case (wAddr_Byte[1])
                    1'b0    : wTemp_Half = wRaw_RdData[15:0];
                    1'b1    : wTemp_Half = wRaw_RdData[31:16];
                    default : wTemp_Half = wRaw_RdData[15:0];
                endcase
                oData_RdData = {{16{1'b0}}, wTemp_Half};
            end

            default :
                oData_RdData = wRaw_RdData;
        endcase
    end

endmodule