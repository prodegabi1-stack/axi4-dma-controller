`timescale 1ns / 1ps

module fifo1 #(parameter DATASIZE = 8, parameter ADDRSIZE = 4)
(
    output logic [DATASIZE-1:0] rdata,
    output logic wfull,
    output logic rempty,
    input  logic [DATASIZE-1:0] wdata,
    input  logic winc,
    input  logic wclk,
    input  logic wrst_n,
    input  logic rinc,
    input  logic rclk,
    input  logic rrst_n);

    logic [ADDRSIZE-1:0] waddr, raddr;
    logic [ADDRSIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;
    logic wclken;

    assign wclken = winc & ~wfull;

    sync_r2w #(.ADDRSIZE(ADDRSIZE)) u_sync_r2w (
        .wq2_rptr (wq2_rptr),
        .rptr (rptr),
        .wclk (wclk),
        .wrst_n (wrst_n));

    sync_w2r #(.ADDRSIZE(ADDRSIZE)) u_sync_w2r (
        .rq2_wptr (rq2_wptr),
        .wptr (wptr),
        .rclk (rclk),
        .rrst_n (rrst_n));

    fifomem #(.DATASIZE (DATASIZE), .ADDRSIZE (ADDRSIZE)) u_fifomem (
        .rdata (rdata),
        .wdata (wdata),
        .raddr (raddr),
        .waddr (waddr),
        .wclken (wclken),
        .wclk (wclk));

    rptr_empty #(.ADDRSIZE(ADDRSIZE)) u_rptr_empty (
        .raddr (raddr),
        .rptr (rptr),
        .rempty (rempty),
        .rq2_wptr (rq2_wptr),
        .rclk (rclk),
        .rrst_n (rrst_n),
        .rinc (rinc));

    wptr_full #(.ADDRSIZE(ADDRSIZE)) u_wptr_full (
        .waddr (waddr),
        .wptr (wptr),
        .wfull (wfull),
        .wq2_rptr (wq2_rptr),
        .wclk (wclk),
        .wrst_n (wrst_n),
        .winc (winc));
endmodule
