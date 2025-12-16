`timescale 1ns / 1ps

module video_timing (
    input  logic       clk,
    input  logic       reset,
    output logic       h_sync,
    output logic       v_sync,
    output logic       pclk,
    output logic       DE,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel

);

    logic sys_clk;
    assign pclk = sys_clk;

    pixel_clk_gen U_PXL_CLK_GEN (
        .clk  (clk),
        .reset(reset),
        .pclk (sys_clk)
    );

    VGA_Syncher U_VGA_Syncher (
        .clk    (sys_clk),
        .reset  (reset),
        .h_sync (h_sync),
        .v_sync (v_sync),
        .DE     (DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel)
    );
endmodule
