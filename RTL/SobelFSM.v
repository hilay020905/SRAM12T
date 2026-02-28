// Module: SobelFSM
// Description: The "brain" for the Sobel kernel.

module SobelFSM (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    output wire busy,
    output wire done,

    // Interface to SRAM
    output reg [3:0] sram_read_addr,  // Address of pixel to read (0-8)

    // Interface to Datapath
    output reg datapath_accum_en,
    output reg datapath_clear_sum,
    output wire [2:0] weight_Gx_out,
    output wire [2:0] weight_Gy_out
);

    // --- State Definitions ---
    localparam [3:0]
        IDLE    = 4'd0,
        PIXEL_0 = 4'd1,
        PIXEL_1 = 4'd2,
        PIXEL_2 = 4'd3,
        PIXEL_3 = 4'd4,
        PIXEL_4 = 4'd5,
        PIXEL_5 = 4'd6,
        PIXEL_6 = 4'd7,
        PIXEL_7 = 4'd8,
        PIXEL_8 = 4'd9,
        DONE    = 4'd10;

    reg [3:0] state_reg, state_next;

    // --- Sobel Weight ROMs ---
    reg signed [2:0] Gx_Weights [0:8];
    reg signed [2:0] Gy_Weights [0:8];

    // --- State Register ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE;
        end else begin
            state_reg <= state_next;
        end
    end

    // --- FSM Next State & Output Logic ---
    always @(*) begin
        // Default values
        state_next          = state_reg;
        sram_read_addr      = 4'd0;
        datapath_accum_en   = 1'b0;
        datapath_clear_sum  = 1'b0;

        case (state_reg)
            IDLE: begin
                if (start) begin
                    datapath_clear_sum = 1'b1; // Clear old sum
                    state_next = PIXEL_0;
                end
            end
            
            PIXEL_0: begin sram_read_addr = 0; datapath_accum_en = 1'b1; state_next = PIXEL_1; end
            PIXEL_1: begin sram_read_addr = 1; datapath_accum_en = 1'b1; state_next = PIXEL_2; end
            PIXEL_2: begin sram_read_addr = 2; datapath_accum_en = 1'b1; state_next = PIXEL_3; end
            PIXEL_3: begin sram_read_addr = 3; datapath_accum_en = 1'b1; state_next = PIXEL_4; end
            PIXEL_4: begin sram_read_addr = 4; datapath_accum_en = 1'b1; state_next = PIXEL_5; end
            PIXEL_5: begin sram_read_addr = 5; datapath_accum_en = 1'b1; state_next = PIXEL_6; end
            PIXEL_6: begin sram_read_addr = 6; datapath_accum_en = 1'b1; state_next = PIXEL_7; end
            PIXEL_7: begin sram_read_addr = 7; datapath_accum_en = 1'b1; state_next = PIXEL_8; end
            PIXEL_8: begin sram_read_addr = 8; datapath_accum_en = 1'b1; state_next = DONE;  end
            
            DONE: begin
                state_next = IDLE;
            end
            
            default: state_next = IDLE;
        endcase
    end
    
    // --- Weight ROM Output ---
    assign weight_Gx_out = Gx_Weights[sram_read_addr];
    assign weight_Gy_out = Gy_Weights[sram_read_addr];

    // --- Status Flags ---
    assign busy = (state_reg != IDLE);
    assign done = (state_reg == DONE);
    
    // --- Initialize ROMs (THIS IS THE CRITICAL PART) ---
    initial begin
        // Gx = [-1, 0, +1, -2, 0, +2, -1, 0, +1]
        Gx_Weights[0] = 3'b111; // -1
        Gx_Weights[1] = 3'b000; // 0
        Gx_Weights[2] = 3'b001; // +1
        Gx_Weights[3] = 3'b110; // -2
        Gx_Weights[4] = 3'b000; // 0
        Gx_Weights[5] = 3'b010; // +2
        Gx_Weights[6] = 3'b111; // -1
        Gx_Weights[7] = 3'b000; // 0
        Gx_Weights[8] = 3'b001; // +1
        
        // Gy = [+1, +2, +1, 0, 0, 0, -1, -2, -1]
        Gy_Weights[0] = 3'b001; // +1
        Gy_Weights[1] = 3'b010; // +2
        Gy_Weights[2] = 3'b001; // +1
        Gy_Weights[3] = 3'b000; // 0
        Gy_Weights[4] = 3'b000; // 0
        Gy_Weights[5] = 3'b000; // 0
        Gy_Weights[6] = 3'b111; // -1
        Gy_Weights[7] = 3'b110; // -2
        Gy_Weights[8] = 3'b111; // -1
    end

endmodule