// CDC com protocolo de handshake 4 fases

module cdc_handshake #(
    parameter DATA_WIDTH  = 8,
    parameter SYNC_STAGES = 2       // numero de estagios nas cadeias de sincronismo
)(
    // Dominio fonte
    input  wire                  src_clk,
    input  wire                  src_arstn,
    input  wire [DATA_WIDTH-1:0] src_data,
    input  wire                  src_valid,  // pulsa 1 ciclo para enviar dado
    output wire                  src_ready,  // indica que a fonte pode enviar

    // Dominio destino
    input  wire                  dest_clk,
    input  wire                  dest_arstn,
    output reg  [DATA_WIDTH-1:0] dest_data,
    output reg                   dest_valid  // pulsa 1 ciclo ao capturar dado
);

    // -------------------------------------------------------------------------
    // Dominio fonte: ff_src + geracao de REQ
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] ff_src;
    reg                  src_req;   // 1 => dado aguardando transferencia

    reg                   dest_ack;
    wire                  dest_ack_out;

    // Sincronismo de ACK para o dominio fonte (cadeia de retorno)
    reg [SYNC_STAGES-1:0] src_ack_sync;

    always @(posedge src_clk or negedge src_arstn) begin
        if (!src_arstn) begin
            src_ack_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            // deslocamento, MSB recebe saida do dominio destino
            src_ack_sync <= {src_ack_sync[SYNC_STAGES-2:0], dest_ack_out};
        end
    end

    wire src_ack_synced = src_ack_sync[SYNC_STAGES-1];

    // ff_src e controle de req
    always @(posedge src_clk or negedge src_arstn) begin
        if (!src_arstn) begin
            ff_src  <= {DATA_WIDTH{1'b0}};
            src_req <= 1'b0;
        end else begin
            if (src_valid && src_ready) begin
                ff_src  <= src_data;    // registra //guarda dado no ff_src
                src_req <= 1'b1;        // levanta REQ
            end else if (src_ack_synced && src_req) begin
                src_req <= 1'b0;        // abaixa REQ apos ACK confirmado
            end
        end
    end

    // Fonte esta pronta quando nao ha transferencia em andamento
    assign src_ready = !src_req && !src_ack_synced;

    // -------------------------------------------------------------------------
    // dominio destino: sincronismo de REQ + ff_dest + ACK
    // -------------------------------------------------------------------------
    reg [SYNC_STAGES-1:0] dest_req_sync;

    always @(posedge dest_clk or negedge dest_arstn) begin
        if (!dest_arstn) begin
            dest_req_sync <= {SYNC_STAGES{1'b0}};
        end else begin
            dest_req_sync <= {dest_req_sync[SYNC_STAGES-2:0], src_req};
        end
    end

    wire dest_req_synced = dest_req_sync[SYNC_STAGES-1];

    // ff_dest e controle de ACK
    reg dest_valid_r;

    always @(posedge dest_clk or negedge dest_arstn) begin
        if (!dest_arstn) begin
            dest_data    <= {DATA_WIDTH{1'b0}};
            dest_ack     <= 1'b0;
            dest_valid_r <= 1'b0;
        end else begin
            dest_valid_r <= 1'b0;                   // pulso de 1 ciclo por padrao

            if (dest_req_synced && !dest_ack) begin
                // REQ chegou mas ainda nao respondeu: captura dado e levanta ACK
                dest_data    <= ff_src;
                dest_ack     <= 1'b1;
                dest_valid_r <= 1'b1;               // sinaliza dado valido por 1 ciclo
            end else if (!dest_req_synced && dest_ack) begin
                // Fonte abaixou REQ (viu nosso ACK): podemos abaixar ACK
                dest_ack <= 1'b0;
            end
        end
    end

    assign dest_ack_out = dest_ack;

    always @(*) dest_valid = dest_valid_r;

endmodule
