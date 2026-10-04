`timescale 1ns / 1ps

module axi_write_master #(
    parameter int ADDRWIDTH = 32,
    parameter int DATAWIDTH = 32
) (
    input logic clk,
    input logic rst_n,

    input logic start,
    input logic [ADDRWIDTH-1:0] dst_addr,
    input logic [7:0] burst_len,
    output logic done,
    output logic busy,

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
    output logic bready,

    input logic [DATAWIDTH-1:0] rdata,
    output logic rinc,
    input logic rempty
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        WRITE_STATE = 2'b01,
        B_STATE = 2'b10,
        DONE_STATE = 2'b11
    } state;

    state state_reg, state_next;

    logic [ADDRWIDTH-1:0] addr_reg;
    logic [7:0] len_reg;
    logic [7:0] count_reg;
    logic aw_done;
    logic w_done;
    logic next_aw_done;
    logic next_w_done;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE;
            addr_reg <= '0;
            len_reg <= '0;
            count_reg <= '0;
            aw_done <= 1'b0;
            w_done <= 1'b0;
        end else begin
            state_reg <= state_next;

            if (state_reg == IDLE && start) begin
                addr_reg <= dst_addr;
                len_reg <= burst_len - 8'd1;
                count_reg <= '0;
                aw_done <= 1'b0;
                w_done <= 1'b0;
            end else if (state_reg == WRITE_STATE) begin
                if (awvalid && awready) begin
                    aw_done <= 1'b1;
                end
                if (wvalid && wready) begin
                    if (wlast) begin
                        w_done <= 1'b1;
                    end else begin
                        count_reg <= count_reg + 8'd1;
                    end
                end
            end
        end
    end

    always_comb begin
        state_next = state_reg;
        next_aw_done = aw_done || (awvalid && awready);
        next_w_done = w_done || (wvalid && wready && wlast);

        case (state_reg)
            IDLE: begin
                if (start) begin
                    state_next = WRITE_STATE;
                end
            end

            WRITE_STATE: begin
                if (next_aw_done && next_w_done) begin
                    state_next = B_STATE;
                end
            end

            B_STATE: begin
                if (bvalid && bready) begin
                    state_next = DONE_STATE;
                end
            end

            DONE_STATE: begin
                state_next = IDLE;
            end

            default: state_next = IDLE;
        endcase
    end

    assign awaddr = addr_reg;
    assign awlen = len_reg;
    assign awsize = 3'($clog2(DATAWIDTH / 8));
    assign awburst = 2'b01;
    assign awvalid = (state_reg == WRITE_STATE) && (!aw_done);

    assign wdata = rdata;
    assign wstrb = '1;
    assign wvalid = (state_reg == WRITE_STATE) && (!w_done) && (!rempty);
    assign wlast = (state_reg == WRITE_STATE) && (!w_done) && (count_reg == len_reg);
    assign rinc = wvalid && wready;

    assign bready = (state_reg == B_STATE);

    assign done = (state_reg == DONE_STATE);
    assign busy = (state_reg != IDLE);

endmodule