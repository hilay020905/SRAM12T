// Module: SharpenFSM
// Description: The "brain" for the Unsharp Masking pipeline.
//              This version is flexible for any image size.

module SharpenFSM (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire [5:0] base_addr_in, // Top-left corner of the 3x3 kernel
    input  wire [5:0] stride_in,    // Width of the image (e.g., 6)
    
    output wire busy,
    output wire done,

    // --- Interface to SRAM ---
    output reg [5:0] sram_read_addr,  // Address of pixel to read

    // --- Interface to Datapath ---
    output reg datapath_clear_sum_en,
    output reg datapath_accum_en,
    output reg datapath_do_sharpen_en,
    output wire [2:0] weight_out
);

    // --- State Definitions (13 states) ---
    localparam [3:0]
        IDLE            = 4'd0,
        PIXEL_0         = 4'd1, PIXEL_1         = 4'd2, PIXEL_2         = 4'd3,
        PIXEL_3         = 4'd4, PIXEL_4         = 4'd5, PIXEL_5         = 4'd6,
        PIXEL_6         = 4'd7, PIXEL_7         = 4'd8, PIXEL_8         = 4'd9,
        GET_ORIG_PIXEL  = 4'd10, CALC_SHARPEN   = 4'd11, DONE           = 4'd12;

    reg [3:0] state_reg, state_next;
    reg [5:0] base_addr_reg, stride_reg;
    reg [5:0] center_pixel_addr;

    // --- Blur Weight ROM (unsigned) ---
    reg [2:0] Blur_Weights [0:8];
    
    // --- Kernel Offset ROM (relative to base_addr) ---
    reg [3:0] kernel_offset_x [0:8];
    reg [3:0] kernel_offset_y [0:8];

    // --- State Register ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE;
            base_addr_reg <= 6'd0;
            stride_reg <= 6'd0;
            center_pixel_addr <= 6'd0;
        end else begin
            state_reg <= state_next;
            if (state_reg == IDLE && start) begin
                base_addr_reg <= base_addr_in;
                stride_reg <= stride_in;
                // Center pixel is (base_addr + 1*stride + 1)
                center_pixel_addr <= base_addr_in + stride_in + 1;
            end
        end
    end

    // --- FSM Next State & Output Logic ---
    always @(*) begin
        // Default values
        state_next              = state_reg;
        sram_read_addr          = 6'd0;
        datapath_clear_sum_en   = 1'b0;
        datapath_accum_en       = 1'b0;
        datapath_do_sharpen_en  = 1'b0;

        case (state_reg)
            IDLE: begin
                if (start) begin
                    datapath_clear_sum_en = 1'b1; // Clear old sum
                    state_next = PIXEL_0;
                end
            end
            
            // --- Stage 1: Blur (9 cycles) ---
            PIXEL_0: begin datapath_accum_en = 1'b1; state_next = PIXEL_1; end
            PIXEL_1: begin datapath_accum_en = 1'b1; state_next = PIXEL_2; end
            PIXEL_2: begin datapath_accum_en = 1'b1; state_next = PIXEL_3; end
            PIXEL_3: begin datapath_accum_en = 1'b1; state_next = PIXEL_4; end
            PIXEL_4: begin datapath_accum_en = 1'b1; state_next = PIXEL_5; end
            PIXEL_5: begin datapath_accum_en = 1'b1; state_next = PIXEL_6; end
            PIXEL_6: begin datapath_accum_en = 1'b1; state_next = PIXEL_7; end
            PIXEL_7: begin datapath_accum_en = 1'b1; state_next = PIXEL_8; end
            PIXEL_8: begin datapath_accum_en = 1'b1; state_next = GET_ORIG_PIXEL; end
            
            // --- Stage 2 & 3: Sharpen ---
            GET_ORIG_PIXEL: begin
                sram_read_addr = center_pixel_addr; // Read original center pixel
                state_next = CALC_SHARPEN;
            end
            
            CALC_SHARPEN: begin
                datapath_do_sharpen_en = 1'b1;
                state_next = DONE;
            end
            
            DONE: begin
                state_next = IDLE;
            end
            
            default: state_next = IDLE;
        endcase
        
        // --- Address Calculation for Blur Pixels ---
        if (state_reg >= PIXEL_0 && state_reg <= PIXEL_8) begin
            sram_read_addr = base_addr_reg + (kernel_offset_y[state_reg-1] * stride_reg) + kernel_offset_x[state_reg-1];
        end
    end
    
    // --- Weight ROM Output ---
    assign weight_out = Blur_Weights[state_reg-1];

    // --- Status Flags ---
    assign busy = (state_reg != IDLE);
    assign done = (state_reg == DONE);
    
    // --- Initialize ROMs ---
    initial begin
        // [1, 2, 1, 2, 4, 2, 1, 2, 1]
        Blur_Weights[0] = 3'b001; Blur_Weights[1] = 3'b010; Blur_Weights[2] = 3'b001;
        Blur_Weights[3] = 3'b010; Blur_Weights[4] = 3'b100; Blur_Weights[5] = 3'b010;
        Blur_Weights[6] = 3'b001; Blur_Weights[7] = 3'b010; Blur_Weights[8] = 3'b001;
        
        // Kernel Offsets (x, y) relative to base_addr
        // (0,0), (1,0), (2,0)
        kernel_offset_x[0] = 0; kernel_offset_y[0] = 0;
        kernel_offset_x[1] = 1; kernel_offset_y[1] = 0;
        kernel_offset_x[2] = 2; kernel_offset_y[2] = 0;
        // (0,1), (1,1), (2,1)
        kernel_offset_x[3] = 0; kernel_offset_y[3] = 1;
        kernel_offset_x[4] = 1; kernel_offset_y[4] = 1;
        kernel_offset_x[5] = 2; kernel_offset_y[5] = 1;
        // (0,2), (1,2), (2,2)
        kernel_offset_x[6] = 0; kernel_offset_y[6] = 2;
        kernel_offset_x[7] = 1; kernel_offset_y[7] = 2;
        kernel_offset_x[8] = 2; kernel_offset_y[8] = 2;
    end

endmodule