// Module: tb_sharpen_6x6
// Description: Testbench for the Unsharp Masking Kernel on a 6x6 image.
//
`timescale 1ns/1ps

module tb_sharpen_6x6;

    // --- Clock and Reset ---
    reg clk;
    reg rst_n;

    // --- Control Wires ---
    reg  start_sharpen;
    reg  [5:0] base_addr_start;
    reg  [5:0] stride_start;
    wire sharpen_done;

    // --- Wires connecting modules ---
    wire [5:0] sram_addr;
    wire [7:0] sram_pixel_out;
    wire       dp_clear_sum;
    wire       dp_accum_en;
    wire       dp_sharpen_en;
    wire [2:0] dp_weight;
    wire [7:0] final_sharpened_pixel;

    // --- Instantiate the FSM (Brain) ---
    SharpenFSM u_fsm (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .start                  (start_sharpen),
        .base_addr_in           (base_addr_start),
        .stride_in              (stride_start),
        .busy                   (),
        .done                   (sharpen_done),
        .sram_read_addr         (sram_addr),
        .datapath_clear_sum_en  (dp_clear_sum),
        .datapath_accum_en      (dp_accum_en),
        .datapath_do_sharpen_en (dp_sharpen_en),
        .weight_out             (dp_weight)
    );

    // --- Instantiate the SRAM (Memory) ---
    Sram6x6Model u_sram (
        .read_addr (sram_addr),
        .pixel_out (sram_pixel_out)
    );

    // --- Instantiate the Datapath (Calculator) ---
    SharpenDatapath u_datapath (
        .clk                 (clk),
        .rst_n               (rst_n),
        .clear_sum_en        (dp_clear_sum),
        .accum_en            (dp_accum_en),
        .do_sharpen_en       (dp_sharpen_en),
        .pixel_in            (sram_pixel_out), // Used for blur
        .weight_in           (dp_weight),
        .original_pixel_in   (sram_pixel_out), // Used for sharpen
        .sharpened_pixel_out (final_sharpened_pixel)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // --- Test Sequence ---
    initial begin
        $display("--- 6x6 Sharpen Testbench Started ---");
        rst_n = 0;
        start_sharpen = 0;
        base_addr_start = 6'd0;
        stride_start = 6'd6;
        #20;
        rst_n = 1;
        #10;

        // --- Load the 6x6 kernel from your figure ---
        $display("[%0t] Loading 6x6 image kernel...", $time);
        // Row 0
        u_sram.load_pixel(0, 8'd100); u_sram.load_pixel(1, 8'd155); u_sram.load_pixel(2, 8'd155);
        u_sram.load_pixel(3, 8'd155); u_sram.load_pixel(4, 8'd155); u_sram.load_pixel(5, 8'd155);
        // Row 1
        u_sram.load_pixel(6, 8'd100); u_sram.load_pixel(7, 8'd155); u_sram.load_pixel(8, 8'd155);
        u_sram.load_pixel(9, 8'd155); u_sram.load_pixel(10, 8'd155); u_sram.load_pixel(11, 8'd155);
        // Row 2
        u_sram.load_pixel(12, 8'd155); u_sram.load_pixel(13, 8'd155); u_sram.load_pixel(14, 8'd100);
        u_sram.load_pixel(15, 8'd155); u_sram.load_pixel(16, 8'd155); u_sram.load_pixel(17, 8'd155);
        // Row 3
        u_sram.load_pixel(18, 8'd100); u_sram.load_pixel(19, 8'd155); u_sram.load_pixel(20, 8'd155);
        u_sram.load_pixel(21, 8'd155); u_sram.load_pixel(22, 8'd155); u_sram.load_pixel(23, 8'd155);
        // Row 4
        u_sram.load_pixel(24, 8'd100); u_sram.load_pixel(25, 8'd155); u_sram.load_pixel(26, 8'd155);
        u_sram.load_pixel(27, 8'd155); u_sram.load_pixel(28, 8'd155); u_sram.load_pixel(29, 8'd155);
        // Row 5
        u_sram.load_pixel(30, 8'd100); u_sram.load_pixel(31, 8'd155); u_sram.load_pixel(32, 8'd155);
        u_sram.load_pixel(33, 8'd155); u_sram.load_pixel(34, 8'd155); u_sram.load_pixel(35, 8'd155);
        
        @(posedge clk);
        #1;
        
        // --- Start the Kernel ---
        // We will process the 3x3 kernel around the pixel at [2][2]
        // The top-left corner [1][1] is address 7 (row 1 * 6 + col 1)
        $display("[%0t] Starting Sharpen FSM...", $time);
        base_addr_start = 6'd7; // Top-left is (1,1) = addr 7
        stride_start    = 6'd6; // Image width is 6
        start_sharpen = 1;
        @(posedge clk);
        #1;
        start_sharpen = 0;
        
        // --- Wait for it to finish (13 cycles) ---
        wait (sharpen_done);
        @(posedge clk);
        #1;
        
        // --- Check Results ---
        // Kernel is [155, 155, 155]
        //          [155, 100, 155]
        //          [155, 155, 155]
        // Blur Sum = (155*1 + 155*2 + 155*1) + (155*2 + 100*4 + 155*2) + (155*1 + 155*2 + 155*1)
        // Blur Sum = (155*12) + (100*4) = 1860 + 400 = 2260
        //
        // Blurred Pixel = 2260 / 16 = 141.25 --> 141 (in hardware)
        // Original Pixel (center [2][2]) = 100
        //
        // Mask = Original - Blurred = 100 - 141 = -41
        // Sharpened = Original + Mask = 100 + (-41) = 59
        
        $display("[%0t] Sharpen kernel finished.", $time);
        $display("Final Sharpened Pixel: %d (Signed: %d)", final_sharpened_pixel, $signed(final_sharpened_pixel));
        
        if (final_sharpened_pixel == 8'd59) begin
            $display("TEST PASSED!");
        end else begin
            $display("TEST FAILED! Expected 59.");
        end

        #50;
        $display("--- Testbench Finished ---");
        $stop;
    end

endmodule