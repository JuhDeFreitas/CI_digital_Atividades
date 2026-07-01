/*
    gpio_simple = implementacao de um de controlador gpio bidirecional simples
    com suporte a parametro para definicao da regiao de enderecamento, numero de
    GPIOs (1 - 32) e mascara default (valor de inicializacao).addr

    Autor: Elivander Pereira @ 17/09/2025
*/
module gpio_simple #(
    parameter [31:0] GPIO_ADDR = 32'h0200_0000,
    parameter integer NUM_GPIO = 1,
    parameter [31:0] INIT_MASK = 32'h0000_0000
)(
    // interface de clock e reset
    input         clk,
    input         rst_n,
    // interface de memoria do periferico
    input  [31:0] addr,
    input  [31:0] wdata,
    output [31:0] rdata,
    input  [ 3:0] wstrb,
    input         valid,
    output        ready,
    output        select,
    // interface de saida do periferico
    input  [NUM_GPIO-1:0] pin_i,
    output [NUM_GPIO-1:0] pin_o,
    output [NUM_GPIO-1:0] pin_t 
);
    
    // Implementa o sinal de chip select
    wire gpio_cs = valid && (addr == GPIO_ADDR);

    // Implementa o sinal de write enable
    wire [3:0] gpio_wen = gpio_cs ? wstrb : 4'h0;

    // Declara os registradores de leitura e escrita
    reg [31:0] gpio_reg_i, gpio_reg_o;

    // Bloco procedural do registrador de escrita
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_reg_o <= INIT_MASK;
        end else begin
            if (gpio_wen[0]) gpio_reg_o[ 7: 0] <= wdata[ 7: 0];
            if (gpio_wen[1]) gpio_reg_o[15: 8] <= wdata[15: 8];
            if (gpio_wen[2]) gpio_reg_o[23:16] <= wdata[23:16];
            if (gpio_wen[3]) gpio_reg_o[31:24] <= wdata[31:24];  
        end
    end

    // Bloco procedural do registrador de leitura
    localparam ZERO_PADDING = 32-NUM_GPIO;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_reg_i <= INIT_MASK;
        end else begin
            gpio_reg_i <= {{ZERO_PADDING{1'b0}}, pin_i};
        end
    end

    // Atribui valores para as portas de saida
    assign ready = 1'b1;
    assign select = gpio_cs;
    assign rdata = gpio_reg_o; //gpio_reg_i;
    assign pin_o = gpio_reg_o[NUM_GPIO-1:0];
    assign pin_t = 1'b1;

endmodule