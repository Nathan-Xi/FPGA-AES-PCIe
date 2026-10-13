`timescale 1ns / 1ps

interface axi4_stream_if #(
    parameter int TDATA_WIDTH = 128
);

    logic                      aclk;
    logic                      aresetn;
    logic [TDATA_WIDTH-1:0] tdata;
    logic [TDATA_WIDTH/8-1:0] tstrb;
    logic                      tlast;
    logic                      tvalid;
    logic                      tready;

    modport slave (
        input  aclk, aresetn,
        input  tdata, tstrb, tlast, tvalid,
        output tready
    );

    modport master (
        input  aclk, aresetn,
        output tdata, tstrb, tlast, tvalid,
        input  tready
    );

endinterface : axi4_stream_if
