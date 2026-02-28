// Module: Sram6x6Model
// Description: A 6x6 (36-pixel) 8-bit memory.

module Sram6x6Model (
    input  wire [5:0] read_addr,   // Read address (0-35)
    output wire [7:0] pixel_out    // 8-bit pixel data out
);

    // --- 6x6 Memory Array (36 locations, 8 bits wide) ---
    reg [7:0] mem [0:35];
    
    // --- FIX IS HERE: Moved declaration to the module scope ---
    integer i;

    // --- Read Logic (Combinational) ---
    assign pixel_out = mem[read_addr];

    // --- Public Task: load_pixel ---
    task load_pixel (
        input [5:0] addr,
        input [7:0] data
    );
        begin
            mem[addr] = data;
        end
    endtask
    
    // --- Initialize Memory ---
    initial begin
        // 'i' is now declared above
        for (i = 0; i < 36; i = i + 1) begin
            mem[i] = 8'd0;
        end
    end

endmodule