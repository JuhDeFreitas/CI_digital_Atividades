# ============================================================
# Constraints de timing - CDC handshake
# ============================================================

#  Definicao dos clocks  
create_clock -period 10.000 -name src_clk  [get_ports src_clk]
create_clock -period  7.000 -name dest_clk [get_ports dest_clk]

# Clock Assíncrono 
# Declaração de que src_clk e dest_clk nao tem relacao temporal.
set_clock_groups -asynchronous \
    -group [get_clocks src_clk] \
    -group [get_clocks dest_clk]


