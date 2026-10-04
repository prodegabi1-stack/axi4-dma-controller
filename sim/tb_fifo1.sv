`timescale 1ns / 1ps

module tb_fifo1;
    parameter DATASIZE = 8;
    parameter ADDRSIZE = 4;
    logic [DATASIZE-1:0] rdata;
    logic wfull;
    logic rempty;
    logic [DATASIZE-1:0] wdata;
    logic winc;
    logic wclk;
    logic wrst_n;
    logic rinc;
    logic rclk;
    logic rrst_n;

    fifo1 #(.DATASIZE (DATASIZE), .ADDRSIZE (ADDRSIZE)) dut (
        .rdata (rdata),
        .wfull (wfull),
        .rempty (rempty),
        .wdata (wdata),
        .winc (winc),
        .wclk (wclk),
        .wrst_n (wrst_n),
        .rinc (rinc),
        .rclk (rclk),
        .rrst_n (rrst_n));

    initial begin
        wclk = 0;
        forever #5 wclk = ~wclk;
    end

    initial begin
        rclk = 0;
        forever #12 rclk = ~rclk;
    end

    initial begin
        winc = 0;
        wdata = '0;
        wrst_n = 0;
        rinc = 0;
        rrst_n = 0;

        #40;
        @(posedge wclk) wrst_n = 1;
        @(posedge rclk) rrst_n = 1;
        #20;

        @(posedge wclk);
        winc = 1; wdata = 8'hA1;
        @(posedge wclk);
        wdata = 8'hA2;
        @(posedge wclk);
        wdata = 8'hA3;
        @(posedge wclk);
        wdata = 8'hA4;
        @(posedge wclk);
        winc = 0;
        wdata = 8'h00;

        repeat (6) @(posedge rclk);

        @(posedge rclk);
        rinc = 1;
        repeat (4) @(posedge rclk);
        rinc = 0;

        repeat (6) @(posedge rclk);

        @(posedge wclk);
        winc = 1;
        for (int i = 0; i < 16; i++) begin
            wdata = 8'h10 + i;
            @(posedge wclk);
        end
        winc = 0;

        repeat (6) @(posedge wclk);

        @(posedge rclk);
        rinc = 1;
        repeat (2) @(posedge rclk);
        rinc = 0;

        repeat (8) @(posedge wclk);
        $finish;
    end
endmodule