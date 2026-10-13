`timescale 1ns / 1ps

interface axi4_lite_if #(
    parameter int C_S_AXI_ADDR_WIDTH = 5,
    parameter int C_S_AXI_DATA_WIDTH = 32
);

    logic                           aclk;
    logic                           aresetn;
    logic [C_S_AXI_ADDR_WIDTH-1:0]  awaddr;
    logic [2:0]                     awprot;
    logic                           awvalid;
    logic                           awready;
    logic [C_S_AXI_DATA_WIDTH-1:0]  wdata;
    logic [C_S_AXI_DATA_WIDTH/8-1:0] wstrb;
    logic                           wvalid;
    logic                           wready;
    logic [1:0]                     bresp;
    logic                           bvalid;
    logic                           bready;
    logic [C_S_AXI_ADDR_WIDTH-1:0]  araddr;
    logic [2:0]                     arprot;
    logic                           arvalid;
    logic                           arready;
    logic [C_S_AXI_DATA_WIDTH-1:0]  rdata;
    logic [1:0]                     rresp;
    logic                           rvalid;
    logic                           rready;

    modport slave (
        input  aclk, aresetn,
        input  awaddr, awprot, awvalid,
        output awready,
        input  wdata, wstrb, wvalid,
        output wready,
        output bresp, bvalid,
        input  bready,
        input  araddr, arprot, arvalid,
        output arready,
        output rdata, rresp, rvalid,
        input  rready
    );

    modport master (
        input  aclk, aresetn,
        output awaddr, awprot, awvalid,
        input  awready,
        output wdata, wstrb, wvalid,
        input  wready,
        input  bresp, bvalid,
        output bready,
        output araddr, arprot, arvalid,
        input  arready,
        input  rdata, rresp, rvalid,
        output rready
    );

endinterface : axi4_lite_if
