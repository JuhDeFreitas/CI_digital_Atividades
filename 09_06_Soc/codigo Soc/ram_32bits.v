/*
    ram_32bits = implementacao de uma memoria RAM com interface 32 bits para 
    ser utilizada com processador RISC-V, com suporte a parametro para definicao 
    da regiao de enderecamento e numero de palavras (base 2).

    Autor: Elivander Pereira @ 17/09/2025
*/
module ram_32bits #(
    parameter [31:0] BASE_ADDR = 32'h0000_0000,
    parameter integer NUM_WORDS = 1024
)(
    input         clk,
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    input  [ 3:0] wstrb,
    input         valid,
    output        ready,
    output        select
);
    // Parametros internos
    localparam ADDR_WIDTH = $clog2(NUM_WORDS);
    localparam [31:0] LAST_ADDR = BASE_ADDR + 4*(NUM_WORDS-1);
    
    // Offset no endereco de memoria e deslocamento (divisao por 4)
    wire [ADDR_WIDTH-1:0] mem_addr = (addr - BASE_ADDR) >> 2;

    // Implementa o sinal de chip select
    wire mem_cs = valid && (addr >= BASE_ADDR) && (addr <= LAST_ADDR);
      
    // Implementa o sinal de write enable
    wire [3:0] mem_wen = mem_cs ? wstrb : 4'h0;

    // Declara a memoria RAM e regs (FFs) de saida
    reg [31:0] mem_ram[0:NUM_WORDS-1];
    reg [31:0] mem_q;
    reg        mem_ready;

    // Bloco procedural da memoria
    always @(posedge clk) begin
        // Write
        if (mem_wen[0]) mem_ram[mem_addr][ 7: 0] <= wdata[ 7: 0];
        if (mem_wen[1]) mem_ram[mem_addr][15: 8] <= wdata[15: 8];
        if (mem_wen[2]) mem_ram[mem_addr][23:16] <= wdata[23:16];
        if (mem_wen[3]) mem_ram[mem_addr][31:24] <= wdata[31:24];  
        // Read
        mem_q <= mem_ram[mem_addr];
        // Ready
        mem_ready <= mem_cs;
    end

    // Liga os regs na saida da memoria
    assign rdata = mem_q;
    assign ready = mem_ready;
    assign select = mem_cs;

endmodule
