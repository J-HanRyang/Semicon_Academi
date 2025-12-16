`timescale 1ns / 1ps

module ImgMemReader (
    input  logic                         DE,
    input  logic [                  9:0] x_pixel,
    input  logic [                  9:0] y_pixel,
    output logic [$clog2(160*120)-1 : 0] addr,
    input  logic [                 15:0] imgData,
    output logic [                  3:0] r_port,
    output logic [                  3:0] g_port,
    output logic [                  3:0] b_port,
    output logic                         cam_part
);
    //logic cam_part;

    assign cam_part = DE && (x_pixel < 160) && (y_pixel < 120);
    assign addr = cam_part ? (160 * y_pixel + x_pixel) : 'bz;  // 16분의 1

    // 4분의 1
    // logic img_display_en;
    // assign img_display_en = DE && (x_pixel < 320) && (y_pixel < 240);
    // assign addr = img_display_en ? (320 * y_pixel + x_pixel) : 'bz;
    // assign {r_port, g_port, b_port} = img_display_en ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0;

    // assign addr = DE ? (320 * y_pixel[9:1] + x_pixel[9:1]) : 'bz;
    // assign {r_port, g_port, b_port} = DE ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0;

endmodule

// module ImgMemReader_upscaler (
//     input  logic                         DE,
//     input  logic [                  9:0] x_pixel,
//     input  logic [                  9:0] y_pixel,
//     output logic [$clog2(320*240)-1 : 0] addr,
//     input  logic [                 15:0] imgData,
//     output logic [                  3:0] r_port,
//     output logic [                  3:0] g_port,
//     output logic [                  3:0] b_port
// );

//     assign addr = DE ? (320 * y_pixel[9:1] + x_pixel[9:1]) : 'bz;
//     assign {r_port, g_port, b_port} = DE ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 0;

// endmodule
