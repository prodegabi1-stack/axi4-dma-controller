`timescale 1ns / 1ps

module rptr_empty#(parameter ADDRSIZE = 4)
    (
    output logic [ADDRSIZE-1:0] raddr,
    output logic [ADDRSIZE:0] rptr,
    output logic rempty,
    input logic [ADDRSIZE:0] rq2_wptr,
    input logic rclk,
    input logic rrst_n,
    input logic rinc);
    
    logic [ADDRSIZE:0] rbin;
    logic [ADDRSIZE:0] rbinnext;
    logic [ADDRSIZE:0] rgraynext;
    logic rempty_val;

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            {rbin, rptr} <= '0;
        end else begin
            {rbin, rptr} <= {rbinnext, rgraynext};
        end
    end

    assign raddr      = rbin[ADDRSIZE-1:0];
    assign rbinnext   = rbin + (rinc & ~rempty);
    assign rgraynext  = (rbinnext >> 1) ^ rbinnext;
    assign rempty_val = (rgraynext == rq2_wptr);

    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty <= 1'b1;
        end else begin
            rempty <= rempty_val;
        end
    end
endmodule
