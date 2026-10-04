`timescale 1ns / 1ps

module wptr_full #(parameter ADDRSIZE = 4)
(
    output logic [ADDRSIZE-1:0] waddr,
    output logic [ADDRSIZE:0]   wptr,
    output logic                wfull,
    input  logic [ADDRSIZE:0]   wq2_rptr,
    input  logic                wclk,
    input  logic                wrst_n,
    input  logic                winc
);

    logic [ADDRSIZE:0] wbin;
    logic [ADDRSIZE:0] wbinnext;
    logic [ADDRSIZE:0] wgraynext;
    logic              wfull_val;

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            {wbin, wptr} <= '0;
        end else begin
            {wbin, wptr} <= {wbinnext, wgraynext};
        end
    end

    assign waddr      = wbin[ADDRSIZE-1:0];
    assign wbinnext   = wbin + (winc & ~wfull);
    assign wgraynext  = (wbinnext >> 1) ^ wbinnext;
    assign wfull_val  = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1], wq2_rptr[ADDRSIZE-2:0]});

    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull <= 1'b0;
        end else begin
            wfull <= wfull_val;
        end
    end

endmodule