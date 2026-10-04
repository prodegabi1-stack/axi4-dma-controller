# Timing Constraints for AXI4 DMA with Async FIFO

# Read clock domain
create_clock -period 10.000 -name clk_read [get_ports m_axi_rclk]

# Write clock domain
create_clock -period 6.000 -name clk_write [get_ports m_axi_wclk]

set_clock_groups -asynchronous \
    -group [get_clocks clk_read] \
    -group [get_clocks clk_write]