`timescale 1ns / 1ps

module axi_read_master #(
    parameter int ADDRWIDTH = 32,
    parameter int DATAWIDTH = 32
) (
    input logic clk,
    input logic rst_n,

    input logic start,
    input logic [ADDRWIDTH-1:0] src_addr,
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

    output logic [DATAWIDTH-1:0] wdata,
    output logic winc,
    input logic wfull
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        AR_STATE = 2'b01,
        R_STATE = 2'b10,
        DONE_STATE = 2'b11
    } state;

    state state_reg, state_next;

    logic [ADDRWIDTH-1:0] addr_reg;
    logic [7:0] len_reg;
    logic [7:0] count_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE;
            addr_reg <= '0;
            len_reg <= '0;
            count_reg <= '0;
        end else begin
            state_reg <= state_next;

            if (state_reg == IDLE && start) begin
                addr_reg <= src_addr;
                len_reg <= burst_len - 8'd1;
                count_reg <= '0;
            end else if (state_reg == R_STATE) begin
                if (rvalid && rready) begin
                    if ((count_reg == len_reg) || rlast) begin
                        count_reg <= '0;
                    end else begin
                        count_reg <= count_reg + 8'd1;
                    end
                end
            end
        end
    end

    always_comb begin
        state_next = state_reg;

        case (state_reg)
            IDLE: begin
                if (start) begin
                    state_next = AR_STATE;
                end
            end

            AR_STATE: begin
                if (arvalid && arready) begin
                    state_next = R_STATE;
                end
            end

            R_STATE: begin
                if (rvalid && rready && ((count_reg == len_reg) || rlast)) begin
                    state_next = DONE_STATE;
                end
            end

            DONE_STATE: begin
                state_next = IDLE;
            end

            default: state_next = IDLE;
        endcase
    end

    assign araddr = addr_reg;
    assign arlen = len_reg;
    assign arsize = 3'($clog2(DATAWIDTH / 8));
    assign arburst = 2'b01;
    assign arvalid = (state_reg == AR_STATE);

    assign rready = (state_reg == R_STATE) && (!wfull);
    assign wdata = rdata;
    assign winc = rvalid && rready;

    assign done = (state_reg == DONE_STATE);
    assign busy = (state_reg != IDLE);

endmodule