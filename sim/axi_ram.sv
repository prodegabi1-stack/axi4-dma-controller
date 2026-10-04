`timescale 1ns / 1ps

module axi_ram #(
    parameter int ADDRWIDTH = 32,
    parameter int DATAWIDTH = 32,
    parameter int MEM_DEPTH = 256
) (
    input logic clk,
    input logic rst_n,

    input logic [ADDRWIDTH-1:0] awaddr,
    input logic [7:0] awlen,
    input logic [2:0] awsize,
    input logic [1:0] awburst,
    input logic awvalid,
    output logic awready,

    input logic [DATAWIDTH-1:0] wdata,
    input logic [(DATAWIDTH/8)-1:0] wstrb,
    input logic wlast,
    input logic wvalid,
    output logic wready,

    output logic [1:0] bresp,
    output logic bvalid,
    input logic bready,

    input logic [ADDRWIDTH-1:0] araddr,
    input logic [7:0] arlen,
    input logic [2:0] arsize,
    input logic [1:0] arburst,
    input logic arvalid,
    output logic arready,

    output logic [DATAWIDTH-1:0] rdata,
    output logic [1:0] rresp,
    output logic rlast,
    output logic rvalid,
    input logic rready
);

    localparam int BYTE_OFFSET = $clog2(DATAWIDTH / 8);
    logic [DATAWIDTH-1:0] mem [0:MEM_DEPTH-1];

    logic [ADDRWIDTH-1:0] r_addr_reg;
    logic [7:0] r_len_reg;
    logic [7:0] r_count_reg;
    logic r_busy;

    wire [$clog2(MEM_DEPTH)-1:0] r_index = r_addr_reg[BYTE_OFFSET +: $clog2(MEM_DEPTH)];

    assign arready = !r_busy;
    assign rvalid = r_busy;
    assign rresp = 2'b00;
    assign rdata = mem[r_index];
    assign rlast = r_busy && (r_count_reg == r_len_reg);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            r_busy <= 1'b0;
            r_addr_reg <= '0;
            r_len_reg <= '0;
            r_count_reg <= '0;
        end 
        else 
        begin
            if (arvalid && arready) 
            begin
                r_busy <= 1'b1;
                r_addr_reg <= araddr;
                r_len_reg <= arlen;
                r_count_reg <= '0;
            end 
            else if (rvalid && rready) 
            begin
                if (rlast) 
                begin
                    r_busy <= 1'b0;
                end 
                else 
                begin
                    r_count_reg <= r_count_reg + 8'd1;
                    r_addr_reg <= r_addr_reg + (DATAWIDTH / 8);
                end
            end
        end
    end

    logic [ADDRWIDTH-1:0] w_addr_reg;
    logic [7:0] w_len_reg;
    logic [7:0] w_count_reg;
    logic w_addr_done;
    logic w_data_done;
    logic b_valid_reg;

    wire [$clog2(MEM_DEPTH)-1:0] w_index = w_addr_reg[BYTE_OFFSET +: $clog2(MEM_DEPTH)];

    assign awready = !w_addr_done;
    assign wready = w_addr_done && !w_data_done;
    assign bresp = 2'b00;
    assign bvalid = b_valid_reg;

    always_ff @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) begin
            w_addr_done <= 1'b0;
            w_data_done <= 1'b0;
            b_valid_reg <= 1'b0;
            w_addr_reg <= '0;
            w_len_reg <= '0;
            w_count_reg <= '0;
        end 
        else 
        begin
            if (awvalid && awready) 
            begin
                w_addr_done <= 1'b1;
                w_addr_reg <= awaddr;
                w_len_reg <= awlen;
                w_count_reg <= '0;
            end

            if (wvalid && wready) 
            begin
                for (int i = 0; i < (DATAWIDTH/8); i++) begin
                    if (wstrb[i]) 
                    begin
                        mem[w_index][i*8 +: 8] <= wdata[i*8 +: 8];
                    end
                end

                if (wlast) 
                begin
                    w_data_done <= 1'b1;
                    b_valid_reg <= 1'b1;
                end 
                else 
                begin
                    w_count_reg <= w_count_reg + 8'd1;
                    w_addr_reg <= w_addr_reg + (DATAWIDTH / 8);
                end
            end

            if (bvalid && bready) 
            begin
                b_valid_reg <= 1'b0;
                w_addr_done <= 1'b0;
                w_data_done <= 1'b0;
            end
        end
    end

endmodule