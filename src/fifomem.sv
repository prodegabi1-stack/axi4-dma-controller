`timescale 1ns / 1ps

module fifomem #(parameter DATASIZE = 8, parameter ADDRSIZE = 4)
    (
    output logic [DATASIZE-1:0] rdata,
    input logic [DATASIZE-1:0] wdata,
    input logic [ADDRSIZE-1:0] raddr,
    input logic [ADDRSIZE-1:0] waddr,
    input logic wclken,
    input logic wclk);
    
    localparam int DEPTH = 1 << ADDRSIZE;
    logic [DATASIZE-1:0] mem [DEPTH];
    assign rdata = mem[raddr];
    
    always_ff @(posedge wclk) begin
        if (wclken) begin
            mem[waddr] <= wdata;
        end
    end
endmodule
