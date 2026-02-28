// Module: SobelDatapath
// Description: The "calculator" for the Sobel kernel.

module SobelDatapath (
    input  wire clk,
    input  wire rst_n,

    // Control signals from FSM
    input  wire accumulate_en,   // "Add to sum now"
    input  wire clear_sum,       // "Reset sums to 0"

    // Data from FSM
    input  wire [7:0] pixel_in,      // 8-bit pixel data
    input  wire [2:0] weight_Gx_in,  // Gx weight
    input  wire [2:0] weight_Gy_in,  // Gy weight

    // Final results
    // --- FIX IS HERE: Changed 'output reg' to 'output wire signed' ---
    output wire signed [11:0] Gx_out,
    output wire signed [11:0] Gy_out
);

    // --- Internal Registers ---
    reg  signed [11:0] Gx_sum;
    reg  signed [11:0] Gy_sum;

    // --- Internal Wires ---
    wire signed [11:0] Gx_product;
    wire signed [11:0] Gy_product;
    
    // --- FIX IS HERE: Treat pixel as unsigned extended to signed 12-bit positive ---
    wire signed [11:0] pixel_ext;
    assign pixel_ext = {{4{1'b0}}, pixel_in};
    
    wire signed [2:0] Gx_weight_signed;
    wire signed [2:0] Gy_weight_signed;

    assign Gx_weight_signed = weight_Gx_in;
    // --- FIX IS HERE: Fixed typo 'Gy_weight_in' -> 'weight_Gy_in' ---
    assign Gy_weight_signed = weight_Gy_in;

    // --- FIX IS HERE: Full signed multiply with proper extension ---
    wire signed [11:0] Gx_weight_ext;
    wire signed [11:0] Gy_weight_ext;
    assign Gx_weight_ext = {{9{Gx_weight_signed[2]}}, Gx_weight_signed};
    assign Gy_weight_ext = {{9{Gy_weight_signed[2]}}, Gy_weight_signed};
    
    assign Gx_product = pixel_ext * Gx_weight_ext;
    assign Gy_product = pixel_ext * Gy_weight_ext;

    // --- Accumulator Logic ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Gx_sum <= 12'sd0;
            Gy_sum <= 12'sd0;
        end else if (clear_sum) begin
            Gx_sum <= 12'sd0;
            Gy_sum <= 12'sd0;
        end else if (accumulate_en) begin
            Gx_sum <= Gx_sum + Gx_product;
            Gy_sum <= Gy_sum + Gy_product;
        end
    end

    // --- Output Assignment ---
    assign Gx_out = Gx_sum;
    assign Gy_out = Gy_sum;

endmodule