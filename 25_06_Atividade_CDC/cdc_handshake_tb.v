// Testbench: cdc_handshake
// Envia 4 palavras com clocks assincronos (src=10ns, dest=7ns) e verifica a recepcao.

`timescale 1ns/1ps

module cdc_handshake_tb;

    // Parametros
    localparam DATA_WIDTH  = 8;
    localparam SYNC_STAGES = 2;
    localparam SRC_PERIOD  = 10;    // 100 MHz
    localparam DEST_PERIOD = 7;     // ~142 MHz

    // Sinais
    reg                  src_clk, src_arstn;
    reg                  dest_clk, dest_arstn;
    reg  [DATA_WIDTH-1:0] src_data;
    reg                  src_valid;
    wire                 src_ready;
    wire [DATA_WIDTH-1:0] dest_data;
    wire                 dest_valid;

    // DUT
    cdc_handshake #(
        .DATA_WIDTH (DATA_WIDTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) dut (
        .src_clk   (src_clk),
        .src_arstn (src_arstn),
        .src_data  (src_data),
        .src_valid (src_valid),
        .src_ready (src_ready),
        .dest_clk  (dest_clk),
        .dest_arstn(dest_arstn),
        .dest_data (dest_data),
        .dest_valid(dest_valid)
    );

    // Geracao dos clocks independentes
    initial src_clk  = 0;
    always  #(SRC_PERIOD/2)  src_clk  = ~src_clk;

    initial dest_clk = 0;
    always  #(DEST_PERIOD/2) dest_clk = ~dest_clk;

    // Tarefa: envia um dado e espera ready
    task send_data;
        input [DATA_WIDTH-1:0] data;
        begin
            @(posedge src_clk);
            while (!src_ready) @(posedge src_clk);
            src_data  = data;
            src_valid = 1'b1;
            @(posedge src_clk);
            src_valid = 1'b0;
        end
    endtask

    // Monitor no dominio destino
    always @(posedge dest_clk) begin
        if (dest_valid)
            $display("[%0t ns] dest recebeu: 0x%02X (%0d)", $time, dest_data, dest_data);
    end

    // Estimulo principal
    initial begin
        src_arstn  = 0;
        dest_arstn = 0;
        src_data   = 8'h00;
        src_valid  = 0;

        repeat(4) @(posedge src_clk);
        src_arstn  = 1;
        dest_arstn = 1;
        repeat(4) @(posedge src_clk);

        $display("[%0t ns] Iniciando transferencias...", $time);

        send_data(8'hA5);
        send_data(8'h3C);
        send_data(8'hFF);
        send_data(8'h00);

        // Aguarda ultimo ACK retornar
        repeat(30) @(posedge src_clk);

        $display("[%0t ns] Simulacao concluida.", $time);
        $finish;
    end

endmodule
