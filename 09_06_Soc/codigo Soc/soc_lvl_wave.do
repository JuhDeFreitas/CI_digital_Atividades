onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/soc_inst/clk
add wave -noupdate /testbench/soc_inst/resetn
add wave -noupdate -divider CPU
add wave -noupdate /testbench/soc_inst/cpu_mem_addr
add wave -noupdate /testbench/soc_inst/cpu_mem_instr
add wave -noupdate /testbench/soc_inst/cpu_mem_wdata
add wave -noupdate /testbench/soc_inst/cpu_mem_rdata
add wave -noupdate /testbench/soc_inst/cpu_mem_wstrb
add wave -noupdate /testbench/soc_inst/cpu_mem_valid
add wave -noupdate /testbench/soc_inst/cpu_mem_ready
add wave -noupdate -divider SRAM
add wave -noupdate /testbench/soc_inst/sram_mem_rdata
add wave -noupdate /testbench/soc_inst/sram_mem_select
add wave -noupdate /testbench/soc_inst/sram_mem_ready
add wave -noupdate -divider GPIO
add wave -noupdate /testbench/soc_inst/gpio_mem_rdata
add wave -noupdate /testbench/soc_inst/gpio_mem_select
add wave -noupdate /testbench/soc_inst/gpio_mem_ready
add wave -noupdate -divider LED
add wave -noupdate -color Magenta /testbench/soc_inst/led_o
add wave -noupdate /testbench/soc_inst/led_i
add wave -noupdate /testbench/soc_inst/led_t
add wave -noupdate /testbench/soc_inst/led
add wave -noupdate -divider {MEMORY INTERNAL}
add wave -noupdate -radix unsigned /testbench/soc_inst/main_mem/mem_addr
add wave -noupdate /testbench/soc_inst/main_mem/mem_wen
add wave -noupdate /testbench/soc_inst/main_mem/mem_q
add wave -noupdate /testbench/soc_inst/main_mem/mem_cs
add wave -noupdate /testbench/soc_inst/main_mem/mem_ready
add wave -noupdate -divider PARAMETERS
add wave -noupdate /testbench/soc_inst/GPIO_LED_ADDR
add wave -noupdate /testbench/soc_inst/RAM_ADDR
add wave -noupdate -radix unsigned /testbench/soc_inst/RAM_NWORDS
add wave -noupdate /testbench/soc_inst/main_mem/BASE_ADDR
add wave -noupdate /testbench/soc_inst/main_mem/LAST_ADDR
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {287900 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ms
update
WaveRestoreZoom {0 ps} {1050 ns}
