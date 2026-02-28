module Sram3x3Model (
    input  wire clk,
    input  wire rst_n,
    input  wire array_precharge,
    input  wire array_assert_wl,
    input  wire array_write_en,
    input  wire array_write_data,
    output reg [8:0] sa_out_discharged 
);
    
    reg mem [2:0] [2:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem[0][0] <= 1'b0;
            mem[0][1] <= 1'b0; mem[0][2] <= 1'b0;
            mem[1][0] <= 1'b0; mem[1][1] <= 1'b0; mem[1][2] <= 1'b0;
            mem[2][0] <= 1'b0;
            mem[2][1] <= 1'b0; mem[2][2] <= 1'b0;
        end else if (array_write_en) begin
            mem[1][1] <= array_write_data;
        end
    end
    
    always @(*) begin
        if (array_assert_wl) begin
            sa_out_discharged[0] = mem[0][0];
            sa_out_discharged[1] = mem[0][1];
            sa_out_discharged[2] = mem[0][2];
            sa_out_discharged[3] = mem[1][0];
            sa_out_discharged[4] = mem[1][1];
            sa_out_discharged[5] = mem[1][2];
            sa_out_discharged[6] = mem[2][0];
            sa_out_discharged[7] = mem[2][1];
            sa_out_discharged[8] = mem[2][2];
        end else begin
            sa_out_discharged = 9'b0;
        end
    end

endmodule