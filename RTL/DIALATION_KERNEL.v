module DilationKernel (
    input  wire clk,
    input  wire rst_n,
    input  wire start_dilation,
    output wire dilation_done,
    input  wire [8:0] sa_in_discharged, 
    output wire array_precharge,
    output wire array_assert_wl,
    output wire array_write_en,
    output wire array_write_data
);

    wire sense_amp_result;
    assign sense_amp_result = |sa_in_discharged;

    reg latched_sense;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latched_sense <= 1'b0;
        end else if (array_assert_wl) begin
            latched_sense <= sense_amp_result;
        end
    end

    wire fsm_busy, fsm_done;
    wire fsm_precharge, fsm_assert_wl, fsm_write_back;

    DilationFSM u_fsm (
        .clk           (clk),
        .rst_n         (rst_n),
        .start         (start_dilation),
        .busy          (fsm_busy),
        .done          (fsm_done),
        .precharge_en  (fsm_precharge),
        .assert_wl_en  (fsm_assert_wl),
        .write_back_en (fsm_write_back)
    );
    
    assign array_precharge  = fsm_precharge;
    assign array_assert_wl  = fsm_assert_wl;
    assign array_write_en   = fsm_write_back;
    
    assign array_write_data = latched_sense;
    assign dilation_done    = fsm_done;

endmodule