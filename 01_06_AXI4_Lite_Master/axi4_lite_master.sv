// axi4_lite_master.sv
// Master AXI4-Lite com FSM simples: IDLE -> escrita/leitura -> DONE

module axi4_lite_master (
    input  wire        ACLK,
    input  wire        ARESETn,

    // Canal AW - Write Address
    output reg  [31:0] M_AXI_AWADDR,
    output reg         M_AXI_AWVALID,
    input  wire        M_AXI_AWREADY,

    // Canal W - Write Data
    output reg  [31:0] M_AXI_WDATA,
    output reg  [3:0]  M_AXI_WSTRB,
    output reg         M_AXI_WVALID,
    input  wire        M_AXI_WREADY,

    // Canal B - Write Response
    input  wire [1:0]  M_AXI_BRESP,
    input  wire        M_AXI_BVALID,
    output reg         M_AXI_BREADY,

    // Canal AR - Read Address
    output reg  [31:0] M_AXI_ARADDR,
    output reg         M_AXI_ARVALID,
    input  wire        M_AXI_ARREADY,

    // Canal R - Read Data
    input  wire [31:0] M_AXI_RDATA,
    input  wire [1:0]  M_AXI_RRESP,
    input  wire        M_AXI_RVALID,
    output reg         M_AXI_RREADY,

    // Sinais de controle para o testbench
    input  wire        start,
    input  wire        write_en,
    input  wire        read_en,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data,
    output reg         done,
    output reg         error
);

// Estados da FSM
localparam IDLE     = 3'd0;
localparam WR_ADDR  = 3'd1;
localparam WR_BRESP = 3'd2;
localparam RD_ADDR  = 3'd3;
localparam RD_DATA  = 3'd4;
localparam DONE_ST  = 3'd5;

reg [2:0] state;

// Flags para saber se AW e W já foram aceitos (handshake independente)
reg aw_done, w_done;

// Guarda a resposta da última transação
reg [1:0] last_resp;

always @(posedge ACLK) begin
    if (!ARESETn) begin
        state         <= IDLE;
        M_AXI_AWADDR  <= 32'h0;
        M_AXI_AWVALID <= 1'b0;
        M_AXI_WDATA   <= 32'h0;
        M_AXI_WSTRB   <= 4'hF;
        M_AXI_WVALID  <= 1'b0;
        M_AXI_BREADY  <= 1'b0;
        M_AXI_ARADDR  <= 32'h0;
        M_AXI_ARVALID <= 1'b0;
        M_AXI_RREADY  <= 1'b0;
        read_data     <= 32'h0;
        done          <= 1'b0;
        error         <= 1'b0;
        aw_done       <= 1'b0;
        w_done        <= 1'b0;
        last_resp     <= 2'b00;
    end else begin
        done <= 1'b0; // pulso de 1 ciclo para indicar done

        case (state)

            IDLE: begin
                error <= 1'b0;
                if (start) begin
                    if (write_en) begin
                        M_AXI_AWADDR  <= addr;
                        M_AXI_AWVALID <= 1'b1;
                        M_AXI_WDATA   <= write_data;
                        M_AXI_WSTRB   <= 4'hF;
                        M_AXI_WVALID  <= 1'b1;
                        aw_done       <= 1'b0;
                        w_done        <= 1'b0;
                        state         <= WR_ADDR;
                    end else if (read_en) begin
                        M_AXI_ARADDR  <= addr;
                        M_AXI_ARVALID <= 1'b1;
                        state         <= RD_ADDR;
                    end
                end
            end

            WR_ADDR: begin
                // Handshake do canal AW
                if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                    M_AXI_AWVALID <= 1'b0;
                    aw_done       <= 1'b1;
                end
                // Handshake do canal W
                if (M_AXI_WVALID && M_AXI_WREADY) begin
                    M_AXI_WVALID <= 1'b0;
                    w_done       <= 1'b1;
                end
                // Quando os dois canais foram aceitos, vai esperar resposta B
                if ((aw_done || (M_AXI_AWVALID && M_AXI_AWREADY)) &&
                    (w_done  || (M_AXI_WVALID  && M_AXI_WREADY))) begin
                    M_AXI_BREADY <= 1'b1;
                    state        <= WR_BRESP;
                end
            end

            WR_BRESP: begin
                if (M_AXI_BVALID && M_AXI_BREADY) begin
                    last_resp    <= M_AXI_BRESP;
                    M_AXI_BREADY <= 1'b0;
                    state        <= DONE_ST;
                end
            end

            RD_ADDR: begin
                if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                    M_AXI_ARVALID <= 1'b0;
                    M_AXI_RREADY  <= 1'b1;
                    state         <= RD_DATA;
                end
            end

            RD_DATA: begin
                if (M_AXI_RVALID && M_AXI_RREADY) begin
                    read_data    <= M_AXI_RDATA;
                    last_resp    <= M_AXI_RRESP;
                    M_AXI_RREADY <= 1'b0;
                    state        <= DONE_ST;
                end
            end

            DONE_ST: begin
                done  <= 1'b1;
                error <= (last_resp != 2'b00);
                state <= IDLE;
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
