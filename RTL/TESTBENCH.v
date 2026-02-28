`timescale 1ns/1ps

module tb_dilation;

    reg clk;
    reg rst_n;
    
    reg  start_dilation;
    wire dilation_done;
    
    wire [8:0] sa_lines;
    wire       precharge_sig;
    wire       assert_wl_sig;
    wire       write_en_sig;
    wire       write_data_sig;
    
    DilationKernel u_kernel (
        .clk           (clk),
        .rst_n         (rst_n),
        .start_dilation(start_dilation),
        .dilation_done (dilation_done),
        .sa_in_discharged(sa_lines),
        .array_precharge (precharge_sig),
        .array_assert_wl (assert_wl_sig),
        .array_write_en  (write_en_sig),
        .array_write_data(write_data_sig)
    );
    
    Sram3x3Model u_sram (
        .clk             (clk),
        .rst_n           (rst_n),
        .array_precharge (precharge_sig),
        .array_assert_wl (assert_wl_sig),
        .array_write_en  (write_en_sig),
        .array_write_data(write_data_sig),
        .sa_out_discharged(sa_lines)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("--- Testbench Started ---");
        rst_n = 0;
        start_dilation = 0;
        #20;
        rst_n = 1;
        #10;
        
        $display("[%0t] TEST 1: All neighbors '0'", $time);
        
        start_dilation = 1;
        @(posedge clk);
        #1;             
        start_dilation = 0;

        wait (dilation_done);
        
        @(posedge clk); 
        @(posedge clk); 
        #1; 
        $display("[%0t] Test 1 Complete. Center pixel is: %b", 
                 $time, u_sram.mem[1][1]);
        
        #50;
        
        $display("[%0t] TEST 2: One neighbor '1'", $time);
        
        u_sram.mem[0][1] = 1'b1;
        $display("[%0t] Loaded mem[0][1] with '1'", $time);

        @(posedge clk); 
        
        start_dilation = 1;
        @(posedge clk);
        #1;             
        start_dilation = 0;

        wait (dilation_done);
        
        @(posedge clk); 
        @(posedge clk); 
        #1; 
        $display("[%0t] Test 2 Complete. Center pixel is: %b", 
                 $time, u_sram.mem[1][1]);

        #50;
        $display("--- Testbench Finished ---");
        $stop;
    end

endmodule