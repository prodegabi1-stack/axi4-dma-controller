`timescale 1ns / 1ps

module sync_w2r #(parameter ADDRSIZE = 4)
    (
    output logic [ADDRSIZE:0] rq2_wptr,
    input logic [ADDRSIZE:0] wptr,
    input logic rclk,
    input logic rrst_n);
    
    (* ASYNC_REG = "TRUE" *) logic [ADDRSIZE:0] rq1_wptr;
    (* ASYNC_REG = "TRUE" *) logic [ADDRSIZE:0] rq2_wptr_reg;
    
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            {rq2_wptr_reg, rq1_wptr} <= '0;
        end else begin
            {rq2_wptr_reg, rq1_wptr} <= {rq1_wptr, wptr};
        end
    end
    
    assign rq2_wptr = rq2_wptr_reg;
endmodule
