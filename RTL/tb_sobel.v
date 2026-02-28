// Module: tb_sobel
// Description: Testbench for the Sobel Kernel.
//              This version tests the "Vertical Edge" kernel.
//
`timescale 1ns/1ps

module tb_sobel;

    // --- Clock and Reset ---
    reg clk;
    reg rst_n;

    // --- Control Wires ---
    reg  start_sobel;
    wire sobel_done;

    // --- Wires connecting modules ---
    wire [3:0] sram_addr;
    wire [7:0] sram_pixel_out;
    wire       dp_accum_en;
    wire       dp_clear_sum;
    wire [2:0] dp_weight_gx;
    wire [2:0] dp_weight_gy;
    wire signed [11:0] final_Gx;
    wire signed [11:0] final_Gy;

    // --- Instantiate the FSM (Brain) ---
    SobelFSM u_fsm (
        .clk                (clk),
        .rst_n              (rst_n),
        .start              (start_sobel),
        .busy               (),
        .done               (sobel_done),
        .sram_read_addr     (sram_addr),
        .datapath_accum_en  (dp_accum_en),
        .datapath_clear_sum (dp_clear_sum),
        .weight_Gx_out      (dp_weight_gx),
        .weight_Gy_out      (dp_weight_gy)
    );

    // --- Instantiate the SRAM (Memory) ---
    Sram3x3Model_Sobel u_sram (
        .read_addr (sram_addr),
        .pixel_out (sram_pixel_out)
    );

    // --- Instantiate the Datapath (Calculator) ---
    SobelDatapath u_datapath (
        .clk            (clk),
        .rst_n          (rst_n),
        .accumulate_en  (dp_accum_en),
        .clear_sum      (dp_clear_sum),
        .pixel_in       (sram_pixel_out),
        .weight_Gx_in   (dp_weight_gx),
        .weight_Gy_in   (dp_weight_gy),
        .Gx_out         (final_Gx),
        .Gy_out         (final_Gy)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // --- Test Sequence ---
    initial begin
        $display("--- Sobel Testbench Started (Vertical Edge Test) ---");
        rst_n = 0;
        start_sobel = 0;
        #20;
        rst_n = 1;
        #10;

        // --- Load the "Vertical Edge" kernel from the figure ---
        // [100, 155, 155]
        // [100, 155, 155]
        // [100, 155, 155]
        $display("[%0t] Loading vertical edge kernel...", $time);
        u_sram.load_pixel(0, 8'd100);
        u_sram.load_pixel(1, 8'd155);
        u_sram.load_pixel(2, 8'd155);
        
        u_sram.load_pixel(3, 8'd100);
        u_sram.load_pixel(4, 8'd155);
        u_sram.load_pixel(5, 8'd155);
        
        u_sram.load_pixel(6, 8'd100);
        u_sram.load_pixel(7, 8'd155);
        u_sram.load_pixel(8, 8'd155);
        
        @(posedge clk);
        #1;
        
        // --- Start the Kernel ---
        $display("[%0t] Starting Sobel FSM...", $time);
        start_sobel = 1;
        @(posedge clk);
        #1;
        start_sobel = 0;
        
        // --- Wait for it to finish ---
        wait (sobel_done);
        @(posedge clk);
        #1;
        
        // --- Check Results ---
        // Gx = (-1*100) + (1*155) + (-2*100) + (2*155) + (-1*100) + (1*155)
        // Gx = -100 + 155 - 200 + 310 - 100 + 155 = 220
        // Gy = (1*100) + (2*155) + (1*155) + (-1*100) + (-2*155) + (-1*155)
        // Gy = (100+310+155) - (100+310+155) = 0
        $display("[%0t] Sobel kernel finished.", $time);
        $display("Final Gx (signed): %d", final_Gx);
        $display("Final Gy (signed): %d", final_Gy);

        #50;
        $display("--- Testbench Finished ---");
        $stop;
    end

endmodule