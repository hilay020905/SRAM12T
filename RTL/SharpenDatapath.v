// Module: SharpenDatapath
// Description: The "calculator" for the Unsharp Masking pipeline.

module SharpenDatapath (
    input  wire clk,
    input  wire rst_n,

    // --- Control Signals from FSM ---
    input  wire clear_sum_en,     // "Reset sum to 0"
    input  wire accum_en,         // "Add to sum now"
    input  wire do_sharpen_en,    // "Perform final sharpen math"

    // --- Data Inputs ---
    input  wire [7:0] pixel_in,           // 8-bit pixel data (for blurring)
    input  wire [2:0] weight_in,          // Blur weight
    input  wire [7:0] original_pixel_in,  // Original center pixel (for sharpening)

    // --- Final Result ---
    output reg [7:0] sharpened_pixel_out
);

    // --- Internal Registers ---
    reg  [15:0] blur_sum_reg; // Holds the sum of 9 products (unsigned)

    // --- Internal Wires ---
    wire [10:0] product;  // Unsigned product
    
    wire [7:0]  blurred_pixel;
    wire signed [8:0]  original_ext;
    wire signed [8:0]  blurred_ext;
    wire signed [8:0]  mask;
    wire signed [8:0]  sharpened_pixel;
    wire [7:0]         sharpened_clamped;

    // --- Stage 1: Blur Accumulator (unsigned) ---
    assign product = pixel_in * weight_in;  // Unsigned multiplication

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            blur_sum_reg <= 16'd0;
        end else if (clear_sum_en) begin
            blur_sum_reg <= 16'd0;
        end else if (accum_en) begin
            blur_sum_reg <= blur_sum_reg + product;
        end
    end

    // --- Stage 2: Sharpening Math ---
    assign blurred_pixel = blur_sum_reg >> 4;  // Unsigned divide by 16
    assign original_ext  = {1'b0, original_pixel_in};  // Unsigned extend to signed 9-bit
    assign blurred_ext   = {1'b0, blurred_pixel};     // Unsigned extend to signed 9-bit
    assign mask          = original_ext - blurred_ext;
    assign sharpened_pixel = original_ext + mask;

    // --- Clamp to 0-255 for valid pixel output ---
    assign sharpened_clamped = (sharpened_pixel > 9'd255) ? 8'd255 :
                               (sharpened_pixel < 0)     ? 8'd0 :
                               sharpened_pixel[7:0];

    // --- Final Output Register ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sharpened_pixel_out <= 8'd0;
        end else if (do_sharpen_en) begin
            sharpened_pixel_out <= sharpened_clamped;
        end
    end

endmodule