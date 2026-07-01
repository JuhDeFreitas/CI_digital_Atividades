module fpga_rv32 #(
    parameter INIT_RAM_FILE = "firmware.hex"
)(
    input clk,
    input resetn,
    inout led
);

    /* ------------------------------------------------------------------------
        Defines do projeto - planejamento da regiao de memoria
    ------------------------------------------------------------------------ */
    localparam STACK_ADDR = 32'h0000_0000;
    localparam RAM_ADDR = 32'h0001_0094;
    localparam RAM_NWORDS = 1024;
    localparam GPIO_LED_ADDR = 32'h0002_0000;

    /* ------------------------------------------------------------------------
        Instancia do processador standalone - nucleo RISC-V 
    ------------------------------------------------------------------------ */
	wire [31:0] cpu_mem_addr, cpu_mem_wdata;
    reg [31:0] cpu_mem_rdata;
    wire [3:0] cpu_mem_wstrb;
    wire cpu_mem_valid, cpu_mem_instr, cpu_mem_ready;

    picorv32 #(
		.STACKADDR(STACK_ADDR),
		.PROGADDR_RESET(RAM_ADDR),
		.PROGADDR_IRQ(32'h0000_0000),
		.BARREL_SHIFTER(1),
		.COMPRESSED_ISA(1),
		.ENABLE_MUL(1),
		.ENABLE_DIV(1),
		.ENABLE_IRQ(0),
		.ENABLE_IRQ_QREGS(0)
    ) cpu_riscv (
        .clk         (clk           ),
        .resetn      (resetn        ),
        .trap        (),
        // Memory Interface
        .mem_valid   (cpu_mem_valid ),
        .mem_instr   (cpu_mem_instr ),
        .mem_ready   (cpu_mem_ready ),
        .mem_addr    (cpu_mem_addr  ),
        .mem_wdata   (cpu_mem_wdata ),
        .mem_wstrb   (cpu_mem_wstrb ),
        .mem_rdata   (cpu_mem_rdata ),

        // Look-Ahead Interface
        .mem_la_read (),
        .mem_la_write(),
        .mem_la_addr (),
        .mem_la_wdata(),
        .mem_la_wstrb(),
        // Pico Co-Processor Interface (PCPI)
        .pcpi_valid  (),
        .pcpi_insn   (),
        .pcpi_rs1    (),
        .pcpi_rs2    (),
        .pcpi_wr     (),
        .pcpi_rd     (),
        .pcpi_wait   (),
        .pcpi_ready  (),
        // IRQ Interface
        .irq         (),
        .eoi         (),
        // Trace Interface
        .trace_valid (),
        .trace_data  ()
	);

    /* ------------------------------------------------------------------------
        Decoder de enderecamento do barramento de leitura em memoria
    ------------------------------------------------------------------------ */
    wire [31:0] sram_mem_rdata, gpio_mem_rdata;         // saida do barramento de dados
    wire sram_mem_select, gpio_mem_select;              // sinais de select pro decoder de enderecos
    wire sram_mem_ready, gpio_mem_ready;

    // codifica o seletor do mux de acordo com os sinais de chip select (baseados no address)
    reg [0:0] rdata_addr_decode;
    always @(*) begin
        if (sram_mem_select) 
            rdata_addr_decode <= 1'b0;
        else if (gpio_mem_select) 
            rdata_addr_decode <= 1'b1;
    end

    // mux decoder de enderecamento do barramento de leitura
    always @(*) begin
        case(rdata_addr_decode)
            0: cpu_mem_rdata <= sram_mem_rdata;
            1: cpu_mem_rdata <= gpio_mem_rdata;
            default: cpu_mem_rdata <= 32'd0;
        endcase
    end

    // assign na linha de ready
    assign cpu_mem_ready = 1'b1 ^ sram_mem_ready;

    /* ------------------------------------------------------------------------
        Memoria principal - RAM do processador 
    ------------------------------------------------------------------------ */
    initial begin
        $readmemh(INIT_RAM_FILE, main_mem.mem_ram, 0, RAM_NWORDS-1);
    end

    ram_32bits #(
        .BASE_ADDR(RAM_ADDR     ),
        .NUM_WORDS(RAM_NWORDS   )
    ) main_mem (
        .clk    (clk            ),
        .addr   (cpu_mem_addr   ),
        .wdata  (cpu_mem_wdata  ),
        .rdata  (sram_mem_rdata ),
        .wstrb  (cpu_mem_wstrb  ),
        .valid  (cpu_mem_valid  ),
        .ready  (sram_mem_ready ),  // sem uso
        .select (sram_mem_select)
    );
    /* ------------------------------------------------------------------------
        Regiao de perifericos mapeados como memoria
    ------------------------------------------------------------------------ */ 
    // Controlador GPIO
    wire led_i, led_o, led_t;     // sinais para o buffer bidirecional (in de um liga no out do outro)
    
    gpio_simple #(                  
        .GPIO_ADDR(GPIO_LED_ADDR),
        .NUM_GPIO (1            ),
        .INIT_MASK(32'h0000_0000)
    ) led_gpio (
        .clk    (clk            ),
        .rst_n  (resetn         ),
        .addr   (cpu_mem_addr   ),
        .wdata  (cpu_mem_wdata  ),
        .rdata  (gpio_mem_rdata ),
        .wstrb  (cpu_mem_wstrb  ),
        .valid  (cpu_mem_valid  ),
        .ready  (gpio_mem_ready ),
        .select (gpio_mem_select),
        .pin_i  (led_i          ),
        .pin_o  (led_o          ),
        .pin_t  (led_t          )
    );

    /* ------------------------------------------------------------------------
        Outros
    ------------------------------------------------------------------------ */ 
    // instancia de primitiva de buffer bidirecional do FPGA
    ALT_IOBUF led_buff (            
        .i          (led_o          ), 
        .oe         (led_t          ), 
        .o          (led_i          ), 
        .io         (led            )
    ); 

endmodule