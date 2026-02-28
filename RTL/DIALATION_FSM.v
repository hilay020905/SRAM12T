module DilationFSM (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    output wire busy,
    output wire done,
    output wire precharge_en,
    output wire assert_wl_en,
    output wire write_back_en
);

    localparam [1:0] 
        IDLE       = 2'b00,
        EVALUATE   = 2'b01,
        WRITE_BACK = 2'b10;
    
    reg [1:0] state_reg, state_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE;
        end else begin
            state_reg <= state_next;
        end
    end

    always @(*) begin
        state_next = state_reg;

        case (state_reg)
            IDLE: begin
                if (start) begin
                    state_next = EVALUATE;
                end
            end
            EVALUATE: begin
                state_next = WRITE_BACK;
            end
            WRITE_BACK: begin
                state_next = IDLE;
            end
            default: begin
                state_next = IDLE;
            end
        endcase
    end

    assign precharge_en  = (state_reg == EVALUATE);
    assign assert_wl_en  = (state_reg == EVALUATE);
    assign write_back_en = (state_reg == WRITE_BACK);
    
    assign busy = (state_reg != IDLE);
    assign done = (state_reg == WRITE_BACK);

endmodule