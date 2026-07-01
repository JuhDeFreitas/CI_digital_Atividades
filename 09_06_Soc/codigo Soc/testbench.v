`timescale 1 ns / 1 ps

module testbench;
    reg clk = 1;
    reg resetn = 0;
    wire led = 0;
	
    always #5 clk = ~clk;
    
    initial begin
        #20 resetn = 1;
    end

    fpga_rv32 #(
        .INIT_RAM_FILE("firmware.hex.txt")
    ) soc_inst (
        .clk(clk),
        .resetn(resetn),
        .led(led)
    );

endmodule
