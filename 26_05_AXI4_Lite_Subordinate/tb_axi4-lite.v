
// tb_axi4_lite_regs.v
`timescale 1ns/1ps

module tb_axi4_lite_regs;
reg         ACLK, ARESETn;

reg  [31:0] S_AXI_AWADDR;
reg         S_AXI_AWVALID;
wire        S_AXI_AWREADY;

reg  [31:0] S_AXI_WDATA;
reg  [3:0]  S_AXI_WSTRB;
reg         S_AXI_WVALID;
wire        S_AXI_WREADY;

wire [1:0]  S_AXI_BRESP;
wire        S_AXI_BVALID;
reg         S_AXI_BREADY;

reg  [31:0] S_AXI_ARADDR;
reg         S_AXI_ARVALID;
wire        S_AXI_ARREADY;

wire [31:0] S_AXI_RDATA;
wire [1:0]  S_AXI_RRESP;
wire        S_AXI_RVALID;
reg         S_AXI_RREADY;

reg  [31:0] reg0_din, reg1_din, reg2_din, reg3_din;
wire [31:0] reg0_dout, reg1_dout, reg2_dout, reg3_dout;

// --- Contador de erros -------------------------------------------------------
integer erros = 0;

// --- Instencia do DUT --------------------------------------------------------
axi4_lite_regs dut (
    .ACLK(ACLK), .ARESETn(ARESETn),
    .S_AXI_AWADDR(S_AXI_AWADDR), .S_AXI_AWVALID(S_AXI_AWVALID), .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_WDATA(S_AXI_WDATA),   .S_AXI_WSTRB(S_AXI_WSTRB),    .S_AXI_WVALID(S_AXI_WVALID),  .S_AXI_WREADY(S_AXI_WREADY),
    .S_AXI_BRESP(S_AXI_BRESP),   .S_AXI_BVALID(S_AXI_BVALID),  .S_AXI_BREADY(S_AXI_BREADY),
    .S_AXI_ARADDR(S_AXI_ARADDR), .S_AXI_ARVALID(S_AXI_ARVALID),.S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_RDATA(S_AXI_RDATA),   .S_AXI_RRESP(S_AXI_RRESP),    .S_AXI_RVALID(S_AXI_RVALID),  .S_AXI_RREADY(S_AXI_RREADY),
    .reg0_din(reg0_din), .reg1_din(reg1_din), .reg2_din(reg2_din), .reg3_din(reg3_din),
    .reg0_dout(reg0_dout), .reg1_dout(reg1_dout), .reg2_dout(reg2_dout), .reg3_dout(reg3_dout)
);

// --- Clock: periodo de 10ns ---------------------------------------------------
initial ACLK = 0;
always #5 ACLK = ~ACLK;

// ==============================================================================
// TASKS AUXILIARES
// ==============================================================================

// Escreve num registrador via AXI (AW + W simultaneos, espera B)
task axi_write;
    input [31:0] addr;
    input [31:0] data;
    begin
        @(posedge ACLK);
        S_AXI_AWADDR  = addr;
        S_AXI_AWVALID = 1;
        S_AXI_WDATA   = data;
        S_AXI_WSTRB   = 4'hF;   // escreve todos os 4 bytes
        S_AXI_WVALID  = 1;
        S_AXI_BREADY  = 1;

        // Aguarda handshake AW
        @(posedge ACLK);
        while (!(S_AXI_AWREADY && S_AXI_AWVALID)) @(posedge ACLK);
        S_AXI_AWVALID = 0;

        // Aguarda handshake W
        while (!(S_AXI_WREADY && S_AXI_WVALID)) @(posedge ACLK);
        S_AXI_WVALID = 0;

        // Aguarda resposta B
        while (!(S_AXI_BVALID && S_AXI_BREADY)) @(posedge ACLK);
        S_AXI_BREADY = 0;

        @(posedge ACLK);
    end
endtask

// Le um registrador via AXI e retorna valor em rdata
task axi_read;
    input  [31:0] addr;
    output [31:0] rdata;
    begin
        @(posedge ACLK);
        S_AXI_ARADDR  = addr;
        S_AXI_ARVALID = 1;
        S_AXI_RREADY  = 1;

        // Aguarda handshake AR
        @(posedge ACLK);
        while (!(S_AXI_ARREADY && S_AXI_ARVALID)) @(posedge ACLK);
        S_AXI_ARVALID = 0;

        // Aguarda dado valido em R
        while (!(S_AXI_RVALID && S_AXI_RREADY)) @(posedge ACLK);
        rdata = S_AXI_RDATA;
        S_AXI_RREADY = 0;

        @(posedge ACLK);
    end
endtask

// Verifica valor e imprime resultado
task check;
    input [31:0] got;
    input [31:0] expected;
    input [63:0] teste_num;   // numero do teste para o log
    begin
        if (got === expected)
            $display("[PASS] Teste %0d: got=0x%08X", teste_num, got);
        else begin
            $display("[FAIL] Teste %0d: esperado=0x%08X  obtido=0x%08X", teste_num, expected, got);
            erros = erros + 1;
        end
    end
endtask


// ==============================================================================
// TESTES
// ==============================================================================

reg [31:0] lido;

initial begin
    $dumpfile("tb_axi4_lite_regs.vcd");
    $dumpvars(0, tb_axi4_lite_regs);

    // Inicializa todos os sinais
    ARESETn = 0;
    S_AXI_AWVALID = 0; S_AXI_WVALID = 0; S_AXI_BREADY = 0;
    S_AXI_ARVALID = 0; S_AXI_RREADY = 0;
    reg0_din = 0; reg1_din = 0; reg2_din = 0; reg3_din = 0;

    // --- TESTE 1: Reset ------------------------------------------------------
    $display("\n=== TESTE 1: Reset ===");
    repeat(4) @(posedge ACLK);
    ARESETn = 1;
    @(posedge ACLK);
    check(reg0_dout, 32'h00000000, 1);
    check(reg1_dout, 32'h00000000, 1);

    // --- TESTE 2: Escrever em reg0 via AXI -----------------------------
    $display("\n=== TESTE 2: Escrita em reg0 (0x00) ===");
    axi_write(32'h00, 32'h00000011);
    check(reg0_dout, 32'h00000011, 2);

    // --- TESTE 3: Escrever em reg1 via AXI -----------------------------
    $display("\n=== TESTE 3: Escrita em reg1 (0x04) ===");
    axi_write(32'h04, 32'h00000022);
    check(reg1_dout, 32'h00000022, 3);

    // --- TESTE 4: Aplicar valor externo em reg2_din -------------------
    $display("\n=== TESTE 4: Valor externo reg2_din ===");
    reg2_din = 32'h00000033;
    @(posedge ACLK);
    check(reg2_dout, 32'h00000033, 4);

    // --- TESTE 5: Aplicar valor externo em reg3_din -------------------
    $display("\n=== TESTE 5: Valor externo reg3_din ===");
    reg3_din = 32'h00000044;
    @(posedge ACLK);
    check(reg3_dout, 32'h00000044, 5);

    // --- TESTE 6: Ler reg0 via AXI ------------------------------------
    $display("\n=== TESTE 6: Leitura de reg0 (0x00) ===");
    axi_read(32'h00, lido);
    check(lido, 32'h00000011, 6);
    if (S_AXI_RRESP === 2'b00)
        $display("[PASS] Teste 6: RRESP=OKAY");
    else begin
        $display("[FAIL] Teste 6: RRESP=%b", S_AXI_RRESP);
        erros = erros + 1;
    end

    // --- TESTE 7: Ler reg1 via AXI -----------------------------------
    $display("\n=== TESTE 7: Leitura de reg1 (0x04) ===");
    axi_read(32'h04, lido);
    check(lido, 32'h00000022, 7);

    // --- TESTE 8: Ler reg2 via AXI ---------------------------------
    $display("\n=== TESTE 8: Leitura de reg2 (0x08) ===");
    axi_read(32'h08, lido);
    check(lido, 32'h00000033, 8);

    // --- TESTE 9: Ler reg3 via AXI --------------------------------
    $display("\n=== TESTE 9: Leitura de reg3 (0x0C) ===");
    axi_read(32'h0C, lido);
    check(lido, 32'h00000044, 9);

    // --- TESTE 10: Verificar saidas dout ---------------------------
    $display("\n=== TESTE 10: Saidas dout ===");
    check(reg0_dout, 32'h00000011, 10);
    check(reg1_dout, 32'h00000022, 10);
    check(reg2_dout, 32'h00000033, 10);
    check(reg3_dout, 32'h00000044, 10);

    //--- TESTE 11: Tentativa de escrita em reg2 --------------
    $display("\n=== TESTE 11: Escrita em reg2 ignorada ===");
    reg2_din = 32'h00000033;   // mantém valor externo
    axi_write(32'h08, 32'hDEADBEEF);
    @(posedge ACLK);
    check(reg2_dout, 32'h00000033, 11);  // deve continuar como reg2_din

    // --- TESTE 12: Tentativa de escrita em reg3 -------------
    $display("\n=== TESTE 12: Escrita em reg3 ignorada ===");
    reg3_din = 32'h00000044;   // mantém valor externo
    axi_write(32'h0C, 32'hDEADBEEF);
    @(posedge ACLK);
    check(reg3_dout, 32'h00000044, 12);  // deve continuar como reg3_din

    // ---- Resultado------------------------------------------------------
    $display("\n==========================================");
    if (erros == 0)
        $display("TODOS OS TESTES PASSARAM!");
    else
        $display("%0d TESTE(S) FALHARAM.", erros);
    $display("==========================================\n");

    $finish;
end

// Timeout
initial begin
    #100000;
    $display("[TIMEOUT] Simulacao travada.");
    $finish;
end

endmodule