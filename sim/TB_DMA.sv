`timescale 1ns / 1ps

module TB_DMA;

    localparam int ADDRWIDTH = 32;
    localparam int DATAWIDTH = 32;
    localparam int MEM_DEPTH = 256;
    localparam int FIFO_DEPTH = 64;
    localparam int LEN = 8;

    logic m_axi_rclk;
    logic m_axi_rrst_n;
    logic m_axi_wclk;
    logic m_axi_wrst_n;
    logic start;
    logic [ADDRWIDTH-1:0] src_addr;
    logic [ADDRWIDTH-1:0] dst_addr;
    logic [7:0] burst_len;
    logic done;
    logic busy;
    logic [ADDRWIDTH-1:0] araddr;
    logic [7:0] arlen;
    logic [2:0] arsize;
    logic [1:0] arburst;
    logic arvalid;
    logic arready;
    logic [DATAWIDTH-1:0] rdata;
    logic [1:0] rresp;
    logic rlast;
    logic rvalid;
    logic rready;
    logic [ADDRWIDTH-1:0] awaddr;
    logic [7:0] awlen;
    logic [2:0] awsize;
    logic [1:0] awburst;
    logic awvalid;
    logic awready;
    logic [DATAWIDTH-1:0] wdata;
    logic [(DATAWIDTH/8)-1:0] wstrb;
    logic wlast;
    logic wvalid;
    logic wready;
    logic [1:0] bresp;
    logic bvalid;
    logic bready;

    initial begin
        m_axi_rclk = 0;
        forever #5 m_axi_rclk = ~m_axi_rclk;
    end

    initial begin
        m_axi_wclk = 0;
        forever #3 m_axi_wclk = ~m_axi_wclk;
    end

    axi_dma_top #(
        .ADDRWIDTH(ADDRWIDTH),
        .DATAWIDTH(DATAWIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .m_axi_rclk(m_axi_rclk),
        .m_axi_rrst_n(m_axi_rrst_n),
        .m_axi_wclk(m_axi_wclk),
        .m_axi_wrst_n(m_axi_wrst_n),
        .start(start),
        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .burst_len(burst_len),
        .done(done),
        .busy(busy),
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
        .bready(bready)
    );

    axi_ram #(
        .ADDRWIDTH(ADDRWIDTH),
        .DATAWIDTH(DATAWIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) u_src_mem (
        .clk(m_axi_rclk),
        .rst_n(m_axi_rrst_n),
        .awaddr('0),
        .awlen('0),
        .awsize('0),
        .awburst('0),
        .awvalid(1'b0),
        .awready(),
        .wdata('0),
        .wstrb('0),
        .wlast(1'b0),
        .wvalid(1'b0),
        .wready(),
        .bresp(),
        .bvalid(),
        .bready(1'b0),
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
        .rready(rready)
    );

    axi_ram #(
        .ADDRWIDTH(ADDRWIDTH),
        .DATAWIDTH(DATAWIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) u_dst_mem (
        .clk(m_axi_wclk),
        .rst_n(m_axi_wrst_n),
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
        .araddr('0),
        .arlen('0),
        .arsize('0),
        .arburst('0),
        .arvalid(1'b0),
        .arready(),
        .rdata(),
        .rresp(),
        .rlast(),
        .rvalid(),
        .rready(1'b0)
    );

    initial begin
        start = 0;
        src_addr = '0;
        dst_addr = '0;
        burst_len = '0;
        m_axi_rrst_n = 0;
        m_axi_wrst_n = 0;

        repeat (5) @(posedge m_axi_wclk);
        m_axi_rrst_n = 1;
        m_axi_wrst_n = 1;
        repeat (2) @(posedge m_axi_wclk);

        for (int i = 0; i < LEN; i++) begin
            u_src_mem.mem[i] = 32'hA000_0000 + i;
        end

        @(posedge m_axi_wclk);
        src_addr = 32'h0000_0000;
        dst_addr = 32'h0000_0000;
        burst_len = LEN;
        start = 1;
        
        repeat (3) @(posedge m_axi_rclk);
        start = 0;

        wait (done);
        repeat (5) @(posedge m_axi_wclk);

        for (int i = 0; i < LEN; i++) begin
            if (u_dst_mem.mem[i] !== (32'hA000_0000 + i)) begin
                $display("FAIL idx=%0d exp=%h got=%h", i, 32'hA000_0000 + i, u_dst_mem.mem[i]);
            end else begin
                $display("PASS idx=%0d val=%h", i, u_dst_mem.mem[i]);
            end
        end

        $display("DMA transfer complete");
    end

    initial begin
        #100000;
        $display("TIMEOUT");
        $finish;
    end

endmodule