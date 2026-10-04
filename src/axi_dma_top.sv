`timescale 1ns / 1ps

module axi_dma_top #(
    parameter int ADDRWIDTH = 32,
    parameter int DATAWIDTH = 32,
    parameter int FIFO_DEPTH = 64
) (
    input logic m_axi_rclk,
    input logic m_axi_rrst_n,
    input logic m_axi_wclk,
    input logic m_axi_wrst_n,
    input logic start,
    input logic [ADDRWIDTH-1:0] src_addr,
    input logic [ADDRWIDTH-1:0] dst_addr,
    input logic [7:0] burst_len,
    output logic done,
    output logic busy,
    output logic [ADDRWIDTH-1:0] araddr,
    output logic [7:0] arlen,
    output logic [2:0] arsize,
    output logic [1:0] arburst,
    output logic arvalid,
    input logic arready,
    input logic [DATAWIDTH-1:0] rdata,
    input logic [1:0] rresp,
    input logic rlast,
    input logic rvalid,
    output logic rready,
    output logic [ADDRWIDTH-1:0] awaddr,
    output logic [7:0] awlen,
    output logic [2:0] awsize,
    output logic [1:0] awburst,
    output logic awvalid,
    input logic awready,
    output logic [DATAWIDTH-1:0] wdata,
    output logic [(DATAWIDTH/8)-1:0] wstrb,
    output logic wlast,
    output logic wvalid,
    input logic wready,
    input logic [1:0] bresp,
    input logic bvalid,
    output logic bready
);

    localparam int FIFO_ADDRSIZE = $clog2(FIFO_DEPTH);

    logic [DATAWIDTH-1:0] fifo_wdata;
    logic fifo_winc, fifo_wfull;
    logic [DATAWIDTH-1:0] fifo_rdata;
    logic fifo_rinc, fifo_rempty;

    logic read_done, read_busy;
    logic write_done, write_busy;

    (* ASYNC_REG = "TRUE" *) logic start_rclk_sync1, start_rclk_sync2;
    logic start_rclk_dly;
    logic start_rclk_pulse;

    always_ff @(posedge m_axi_rclk or negedge m_axi_rrst_n) begin
        if (!m_axi_rrst_n) begin
            start_rclk_sync1 <= 1'b0;
            start_rclk_sync2 <= 1'b0;
            start_rclk_dly <= 1'b0;
        end else begin
            start_rclk_sync1 <= start;
            start_rclk_sync2 <= start_rclk_sync1;
            start_rclk_dly <= start_rclk_sync2;
        end
    end

    assign start_rclk_pulse = start_rclk_sync2 && !start_rclk_dly;

    (* ASYNC_REG = "TRUE" *) logic read_busy_wclk_sync1, read_busy_wclk_sync2;

    always_ff @(posedge m_axi_wclk or negedge m_axi_wrst_n) begin
        if (!m_axi_wrst_n) begin
            read_busy_wclk_sync1 <= 1'b0;
            read_busy_wclk_sync2 <= 1'b0;
        end else begin
            read_busy_wclk_sync1 <= read_busy;
            read_busy_wclk_sync2 <= read_busy_wclk_sync1;
        end
    end

    axi_read_master #(
        .ADDRWIDTH(ADDRWIDTH),
        .DATAWIDTH(DATAWIDTH)
    ) u_read_master (
        .clk(m_axi_rclk),
        .rst_n(m_axi_rrst_n),
        .start(start_rclk_pulse),
        .src_addr(src_addr),
        .burst_len(burst_len),
        .done(read_done),
        .busy(read_busy),
        .araddr(araddr),
        .arlen(arlen),
        .arsize(arsize),
        .arburst(arburst),
        .arvalid(arvalid),
        .arready(arready),
        .rdata(rdata),
        .rresp(rresp),
        .rlast(rlast),
        .rvalid(rvalid),
        .rready(rready),
        .wdata(fifo_wdata),
        .winc(fifo_winc),
        .wfull(fifo_wfull)
    );

    fifo1 #(
        .DATASIZE(DATAWIDTH),
        .ADDRSIZE(FIFO_ADDRSIZE)
    ) u_async_fifo (
        .wclk(m_axi_rclk),
        .wrst_n(m_axi_rrst_n),
        .winc(fifo_winc),
        .wdata(fifo_wdata),
        .wfull(fifo_wfull),
        .rclk(m_axi_wclk),
        .rrst_n(m_axi_wrst_n),
        .rinc(fifo_rinc),
        .rdata(fifo_rdata),
        .rempty(fifo_rempty)
    );

    axi_write_master #(
        .ADDRWIDTH(ADDRWIDTH),
        .DATAWIDTH(DATAWIDTH)
    ) u_write_master (
        .clk(m_axi_wclk),
        .rst_n(m_axi_wrst_n),
        .start(start),
        .dst_addr(dst_addr),
        .burst_len(burst_len),
        .done(write_done),
        .busy(write_busy),
        .awaddr(awaddr),
        .awlen(awlen),
        .awsize(awsize),
        .awburst(awburst),
        .awvalid(awvalid),
        .awready(awready),
        .wdata(wdata),
        .wstrb(wstrb),
        .wlast(wlast),
        .wvalid(wvalid),
        .wready(wready),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),
        .rdata(fifo_rdata),
        .rinc(fifo_rinc),
        .rempty(fifo_rempty)
    );

    assign done = write_done;
    assign busy = read_busy_wclk_sync2 || write_busy;

endmodule