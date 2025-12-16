`timescale 1ns / 1ps

module frame_buffer (
    // write side
    input  logic        wclk,
    input  logic        we,
    input  logic [14:0] wAddr,
    input  logic [15:0] wData,
    // read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [14:0] rAddr,
    output logic [15:0] rData
);
    logic [15:0] mem[0:(160*120)-1];

    // write side
    always_ff @(posedge wclk) begin
        if (we) mem[wAddr] <= wData;
    end

    // read side
    always_ff @(posedge rclk) begin
        if (oe) rData <= mem[rAddr];
    end

endmodule
