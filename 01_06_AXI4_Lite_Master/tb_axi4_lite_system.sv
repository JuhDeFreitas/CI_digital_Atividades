// tb_axi4_lite_system.sv
// Testbench de integração: AXI4-Lite Master + Subordinate

`timescale 1ns/1ps

module tb_axi4_lite_system;

// =====================================================================
// Sinais
// =====================================================================
reg        ACLK;
reg        ARESETn;

reg        start;
reg        write_en;
reg        read_en;
reg [31:0] addr;
reg [31:0] write_data;
reg [31:0] reg2_din;
reg [31:0] reg3_din;

wire [31:0] read_data;
wire        done;
wire        error;
wire [31:0] reg0_dout, reg1_dout, reg2_dout, reg3_dout;

// =====================================================================
// Clock: período de 10 ns
// =====================================================================
initial ACLK = 0;
always #5 ACLK = ~ACLK;

// =====================================================================
// DUT
// =====================================================================
axi4_lite_system_top dut (
    .ACLK       (ACLK),
    .ARESETn    (ARESETn),
    .start      (start),
    .write_en   (write_en),
    .read_en    (read_en),
    .addr       (addr),
    .write_data (write_data),
    .reg2_din   (reg2_din),
    .reg3_din   (reg3_din),
    .read_data  (read_data),
    .done       (done),
    .error      (error),
    .reg0_dout  (reg0_dout),
    .reg1_dout  (reg1_dout),
    .reg2_dout  (reg2_dout),
    .reg3_dout  (reg3_dout)
);

// =====================================================================
// dump p/ visualização das formas de onda
// =====================================================================
initial begin
    $dumpfile("tb_axi4_lite_system.vcd");
    $dumpvars(0, tb_axi4_lite_system);
end

// Contador de erros
integer erros;

// =====================================================================
// Task: escreve via AXI4-Lite
// =====================================================================
task do_write;
    input [31:0] a;
    input [31:0] d;
    begin
        @(posedge ACLK);
        addr       = a;
        write_data = d;
        write_en   = 1;
        read_en    = 0;
        start      = 1;
        @(posedge ACLK);
        start = 0;
        wait (done);
        @(posedge ACLK);
        if (error) begin
            $display("  [AVISO] BRESP != OKAY na escrita em 0x%02h", a);
            erros = erros + 1;
        end
    end
endtask

// =====================================================================
// Task: lê via AXI4-Lite
// =====================================================================
task do_read;
    input [31:0] a;
    begin
        @(posedge ACLK);
        addr     = a;
        write_en = 0;
        read_en  = 1;
        start    = 1;
        @(posedge ACLK);
        start = 0;
        wait (done);
        @(posedge ACLK);
        if (error) begin
            $display("  [AVISO] RRESP != OKAY na leitura em 0x%02h", a);
            erros = erros + 1;
        end
    end
endtask

// =====================================================================
// Sequência de testes
// =====================================================================
initial begin
    erros     = 0;
    ARESETn   = 0;
    start     = 0;
    write_en  = 0;
    read_en   = 0;
    addr      = 32'h0;
    write_data = 32'h0;
    reg2_din  = 32'h0;
    reg3_din  = 32'h0;

    // --- Teste 1: Reset ---
    #20;
    ARESETn = 1;
    #10;
    $display("=== Teste 1: Reset aplicado ===");
    $display("  reg0_dout = 0x%08h (esperado 0x00000000)", reg0_dout);
    $display("  reg1_dout = 0x%08h (esperado 0x00000000)", reg1_dout);

    // --- Teste 2: Escreve em reg0 ---
    $display("\n=== Teste 2: Escrita em reg0 (addr=0x00, data=0x00000011) ===");
    do_write(32'h00, 32'h00000011);
    $display("  Escrita concluida");

    // --- Teste 3: Escreve em reg1 ---
    $display("\n=== Teste 3: Escrita em reg1 (addr=0x04, data=0x00000022) ===");
    do_write(32'h04, 32'h00000022);
    $display("  Escrita concluida");

    // --- Teste 4: Valor externo em reg2 ---
    $display("\n=== Teste 4: Aplicando reg2_din = 0x00000033 ===");
    reg2_din = 32'h00000033;
    #10;
    $display("  reg2_din aplicado");

    // --- Teste 5: Valor externo em reg3 ---
    $display("\n=== Teste 5: Aplicando reg3_din = 0x00000044 ===");
    reg3_din = 32'h00000044;
    #10;
    $display("  reg3_din aplicado");

    // --- Teste 6: Lê reg0 ---
    $display("\n=== Teste 6: Leitura de reg0 (addr=0x00) ===");
    do_read(32'h00);
    if (read_data !== 32'h00000011) begin
        $display("  ERRO: leitura de reg0 = 0x%08h, esperado 0x00000011", read_data);
        erros = erros + 1;
    end else
        $display("  OK: leitura de reg0 correta = 0x%08h", read_data);

    // --- Teste 7: Lê reg1 ---
    $display("\n=== Teste 7: Leitura de reg1 (addr=0x04) ===");
    do_read(32'h04);
    if (read_data !== 32'h00000022) begin
        $display("  ERRO: leitura de reg1 = 0x%08h, esperado 0x00000022", read_data);
        erros = erros + 1;
    end else
        $display("  OK: leitura de reg1 correta = 0x%08h", read_data);

    // --- Teste 8: Lê reg2 ---
    $display("\n=== Teste 8: Leitura de reg2 (addr=0x08) ===");
    do_read(32'h08);
    if (read_data !== 32'h00000033) begin
        $display("  ERRO: leitura de reg2 = 0x%08h, esperado 0x00000033", read_data);
        erros = erros + 1;
    end else
        $display("  OK: leitura de reg2 correta = 0x%08h", read_data);

    // --- Teste 9: Lê reg3 ---
    $display("\n=== Teste 9: Leitura de reg3 (addr=0x0C) ===");
    do_read(32'h0C);
    if (read_data !== 32'h00000044) begin
        $display("  ERRO: leitura de reg3 = 0x%08h, esperado 0x00000044", read_data);
        erros = erros + 1;
    end else
        $display("  OK: leitura de reg3 correta = 0x%08h", read_data);

    // --- Teste 10: BRESP/RRESP OK ---
    // Verificado dentro das tasks do_write e do_read (flag error)
    $display("\n=== Teste 10: Respostas AXI (verificado nas tasks acima) ===");
    if (erros == 0)
        $display("  OK: nenhum BRESP/RRESP com erro ate aqui");

    // --- Teste 11: Tenta escrever em reg2 (deve manter valor externo) ---
    $display("\n=== Teste 11: Tentativa de escrita em reg2 (addr=0x08) ===");
    do_write(32'h08, 32'hDEADBEEF);
    do_read(32'h08);
    if (read_data !== 32'h00000033) begin
        $display("  ERRO: reg2 foi alterado! valor = 0x%08h", read_data);
        erros = erros + 1;
    end else
        $display("  OK: reg2 manteve o valor externo = 0x%08h", read_data);

    // --- Teste 12: Tenta escrever em reg3 (deve manter valor externo) ---
    $display("\n=== Teste 12: Tentativa de escrita em reg3 (addr=0x0C) ===");
    do_write(32'h0C, 32'hDEADBEEF);
    do_read(32'h0C);
    if (read_data !== 32'h00000044) begin
        $display("  ERRO: reg3 foi alterado! valor = 0x%08h", read_data);
        erros = erros + 1;
    end else
        $display("  OK: reg3 manteve o valor externo = 0x%08h", read_data);

    // --- Resultado final ---
    #20;
    $display("\n==========================================");
    if (erros == 0)
        $display("RESULTADO: TODOS OS TESTES PASSARAM!");
    else
        $display("RESULTADO: %0d TESTE(S) FALHARAM!", erros);
    $display("==========================================");

    $finish;
end

endmodule
