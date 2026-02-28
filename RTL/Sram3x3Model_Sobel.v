// Module: Sram3x3Model_Sobel
// Description: A behavioral model of the 3x3 SRAM array for Sobel.
//              This is a simple 9x8-bit Read-Only Memory.

module Sram3x3Model_Sobel (
    input  wire [3:0] read_addr,   // Read address from FSM
    output wire [7:0] pixel_out    // 8-bit pixel data out
);

    // --- 3x3 Memory Array (9 locations, 8 bits wide) ---
    reg [7:0] mem [0:8];

    // --- Read Logic (Combinational) ---
    // Output the data from the requested address
    assign pixel_out = mem[read_addr];

    // --- Public Task: load_pixel ---
    // This is a helper task so your testbench can
    // easily load initial data into the array.
    task load_pixel (
        input [3:0] addr,
        input [7:0] data
    );
        begin
            mem[addr] = data;
        end
    endtask
    
    // --- Initialize Memory (optional) ---
    initial begin
        mem[0] = 8'd0;
        mem[1] = 8'd0;
        mem[2] = 8'd0;
        mem[3] = 8'd0;
        mem[4] = 8'd0;
        mem[5] = 8'd0;
        mem[6] = 8'd0;
        mem[7] = 8'd0;
        mem[8] = 8'd0;
    end

endmodule