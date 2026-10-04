`timescale 1ns / 1ps

module sync_r2w #(parameter ADDRSIZE = 4)
    (
    output logic [ADDRSIZE:0] wq2_rptr,
    input logic [ADDRSIZE:0] rptr,
    input logic wclk,
    input logic wrst_n);
    
    (* ASYNC_REG = "TRUE" *) logic [ADDRSIZE:0] wq1_rptr;
    (* ASYNC_REG = "TRUE" *) logic [ADDRSIZE:0] wq2_rptr_reg;
    
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            {wq2_rptr_reg, wq1_rptr} <= '0;
        end else begin
            {wq2_rptr_reg, wq1_rptr} <= {wq1_rptr, rptr};
        end
    end
    
    assign wq2_rptr=wq2_rptr_reg;
endmodule
