
// axi4_lite_regs.v
module axi4_lite_regs (
    input  wire        ACLK,
    input  wire        ARESETn,

    // Canal AW - Write Address
    input  wire [31:0] S_AXI_AWADDR,
    input  wire        S_AXI_AWVALID,
    output reg         S_AXI_AWREADY,

    // Canal W - Write Data
    input  wire [31:0] S_AXI_WDATA,
    input  wire [3:0]  S_AXI_WSTRB,
    input  wire        S_AXI_WVALID,
    output reg         S_AXI_WREADY,

    // Canal B - Write Response
    output reg  [1:0]  S_AXI_BRESP,
    output reg         S_AXI_BVALID,
    input  wire        S_AXI_BREADY,

    // Canal AR - Read Address
    input  wire [31:0] S_AXI_ARADDR,
    input  wire        S_AXI_ARVALID,
    output reg         S_AXI_ARREADY,

    // Canal R - Read Data
    output reg  [31:0] S_AXI_RDATA,
    output reg  [1:0]  S_AXI_RRESP,
    output reg         S_AXI_RVALID,
    input  wire        S_AXI_RREADY,

    // Entradas externas
    input  wire [31:0] reg0_din,
    input  wire [31:0] reg1_din,
    input  wire [31:0] reg2_din,  // status externo -> reg2
    input  wire [31:0] reg3_din,  // status externo -> reg3

    // Saídas dos registradores
    output wire [31:0] reg0_dout,
    output wire [31:0] reg1_dout,
    output wire [31:0] reg2_dout,
    output wire [31:0] reg3_dout
);

// ---- Registradores internos ---------------------------------------------------
reg [31:0] reg0, reg1;

// reg2 e reg3 são apenas passagem do valor externo
assign reg2_dout = reg2_din;
assign reg3_dout = reg3_din;

assign reg0_dout = reg0;
assign reg1_dout = reg1;

// --- Endereços dos registradores -------------------------------------------------
localparam ADDR_REG0 = 32'h00;
localparam ADDR_REG1 = 32'h04;
localparam ADDR_REG2 = 32'h08;
localparam ADDR_REG3 = 32'h0C;

// --- Registrador interno para capturar o endereço de escrita --------------------
reg [31:0] aw_addr_lat;  // endereço latched quando AW é aceito

// ===============================================================================
// ESCRITA (canais AW + W + B)
// ===============================================================================

always @(posedge ACLK) begin
    if (!ARESETn) begin
        reg0          <= 32'h0;
        reg1          <= 32'h0;
        S_AXI_AWREADY <= 1'b0;
        S_AXI_WREADY  <= 1'b0;
        S_AXI_BVALID  <= 1'b0;
        S_AXI_BRESP   <= 2'b00;
        aw_addr_lat   <= 32'h0;
    end else begin

        // aceita endereço e dado assim que chegam
        S_AXI_AWREADY <= 1'b1;
        S_AXI_WREADY  <= 1'b1;

        // Latch do endereço quando AW é aceito
        if (S_AXI_AWVALID && S_AXI_AWREADY)
            aw_addr_lat <= S_AXI_AWADDR;

        // Escrita acontece quando AW e W foram ambos aceitos
        if (S_AXI_AWVALID && S_AXI_AWREADY &&
            S_AXI_WVALID  && S_AXI_WREADY) begin

            case (S_AXI_AWADDR[3:0])           // usa só os 4 bits baixos
                ADDR_REG0[3:0]: reg0 <= S_AXI_WDATA;
                ADDR_REG1[3:0]: reg1 <= S_AXI_WDATA;
                // reg2 e reg3: ignora escrita AXI (são status externos)
                default: ;
            endcase

            S_AXI_BVALID <= 1'b1;
            S_AXI_BRESP  <= 2'b00;  // OKAY
        end

        // Limpa BVALID quando master aceitou a resposta
        if (S_AXI_BVALID && S_AXI_BREADY)
            S_AXI_BVALID <= 1'b0;
    end
end

// ===============================================================================
// LEITURA (canais AR + R)
// ===============================================================================

always @(posedge ACLK) begin
    if (!ARESETn) begin
        S_AXI_ARREADY <= 1'b0;
        S_AXI_RVALID  <= 1'b0;
        S_AXI_RDATA   <= 32'h0;
        S_AXI_RRESP   <= 2'b00;
    end else begin

        S_AXI_ARREADY <= 1'b1;  // sempre pronto para aceitar endereço

        if (S_AXI_ARVALID && S_AXI_ARREADY) begin
            // Seleciona qual registrador retornar
            case (S_AXI_ARADDR[3:0])
                ADDR_REG0[3:0]: S_AXI_RDATA <= reg0;
                ADDR_REG1[3:0]: S_AXI_RDATA <= reg1;
                ADDR_REG2[3:0]: S_AXI_RDATA <= reg2_din;
                ADDR_REG3[3:0]: S_AXI_RDATA <= reg3_din;
                default:        S_AXI_RDATA <= 32'hDEADBEEF; // endereço inválido
            endcase

            S_AXI_RVALID <= 1'b1;
            S_AXI_RRESP  <= 2'b00;  // OKAY
        end

        // Limpa RVALID quando master aceitou o dado
        if (S_AXI_RVALID && S_AXI_RREADY)
            S_AXI_RVALID <= 1'b0;
    end
end

endmodule