// axi4_lite_system_top.sv
// Módulo top que integra o master e o subordinate AXI4-Lite

module axi4_lite_system_top (
    input  wire        ACLK,
    input  wire        ARESETn,

    // Controle vindo do testbench (vai pro master)
    input  wire        start,
    input  wire        write_en,
    input  wire        read_en,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,

    // Entradas externas (vai pro subordinate)
    input  wire [31:0] reg2_din,
    input  wire [31:0] reg3_din,

    // Saídas do master
    output wire [31:0] read_data,
    output wire        done,
    output wire        error,

    // Saídas dos registradores do subordinate
    output wire [31:0] reg0_dout,
    output wire [31:0] reg1_dout,
    output wire [31:0] reg2_dout,
    output wire [31:0] reg3_dout
);

// wires entre master e subordinate
wire [31:0] awaddr;
wire        awvalid, awready;
wire [31:0] wdata;
wire [3:0]  wstrb;
wire        wvalid, wready;
wire [1:0]  bresp;
wire        bvalid, bready;
wire [31:0] araddr;
wire        arvalid, arready;
wire [31:0] rdata;
wire [1:0]  rresp;
wire        rvalid, rready;

// Instância do Master
axi4_lite_master master (
    .ACLK          (ACLK),
    .ARESETn       (ARESETn),

    .M_AXI_AWADDR  (awaddr),
    .M_AXI_AWVALID (awvalid),
    .M_AXI_AWREADY (awready),

    .M_AXI_WDATA   (wdata),
    .M_AXI_WSTRB   (wstrb),
    .M_AXI_WVALID  (wvalid),
    .M_AXI_WREADY  (wready),

    .M_AXI_BRESP   (bresp),
    .M_AXI_BVALID  (bvalid),
    .M_AXI_BREADY  (bready),

    .M_AXI_ARADDR  (araddr),
    .M_AXI_ARVALID (arvalid),
    .M_AXI_ARREADY (arready),

    .M_AXI_RDATA   (rdata),
    .M_AXI_RRESP   (rresp),
    .M_AXI_RVALID  (rvalid),
    .M_AXI_RREADY  (rready),

    .start         (start),
    .write_en      (write_en),
    .read_en       (read_en),
    .addr          (addr),
    .write_data    (write_data),
    .read_data     (read_data),
    .done          (done),
    .error         (error)
);

// Instância do Subordinate
axi4_lite_subordinate subordinate (
    .ACLK          (ACLK),
    .ARESETn       (ARESETn),

    .S_AXI_AWADDR  (awaddr),
    .S_AXI_AWVALID (awvalid),
    .S_AXI_AWREADY (awready),

    .S_AXI_WDATA   (wdata),
    .S_AXI_WSTRB   (wstrb),
    .S_AXI_WVALID  (wvalid),
    .S_AXI_WREADY  (wready),

    .S_AXI_BRESP   (bresp),
    .S_AXI_BVALID  (bvalid),
    .S_AXI_BREADY  (bready),

    .S_AXI_ARADDR  (araddr),
    .S_AXI_ARVALID (arvalid),
    .S_AXI_ARREADY (arready),

    .S_AXI_RDATA   (rdata),
    .S_AXI_RRESP   (rresp),
    .S_AXI_RVALID  (rvalid),
    .S_AXI_RREADY  (rready),

    .reg2_din      (reg2_din),
    .reg3_din      (reg3_din),

    .reg0_dout     (reg0_dout),
    .reg1_dout     (reg1_dout),
    .reg2_dout     (reg2_dout),
    .reg3_dout     (reg3_dout)
);

endmodule
