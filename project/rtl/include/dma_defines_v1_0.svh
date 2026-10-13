
`ifndef IF_PCIE_DMA_RCV_SV
`define IF_PCIE_DMA_RCV_SV

`define TAG_WIDTH 8
`define DADR_WIDTH 9
`define RID_WIDTH 6 
`define CHN_WIDTH 5 
`define DAT_WIDTH 256 
`define LEN_WIDTH 28 
`define ADR_WIDTH 64 



typedef struct packed {
    logic [`TAG_WIDTH-1:0]  tag;
    logic [`RID_WIDTH-1:0]  rid;
    logic [`DADR_WIDTH-1:0] dadr;
    logic [`CHN_WIDTH-1:0]  chn;
} mrd_info_t;

typedef struct packed {
    logic [`ADR_WIDTH-1:0] adr;
    logic [`RID_WIDTH-1:0] rid;
    logic [`LEN_WIDTH-1:0] len;   // byte length
    logic [`DADR_WIDTH-1:0] dadr;
} rd_req_t;

typedef struct packed {
    logic            sop;
    logic            eop;
    logic            wbk;
    logic [4:0]      err;
    logic [`RID_WIDTH-1:0]    rid;
    logic [`DADR_WIDTH-1:0]   dadr;
    logic [5:0]               ivb;    
    logic [`DAT_WIDTH-1:0]    dat;
} rd_cpl_t;

typedef struct packed {
    logic [3:0]   strb;
    logic         wr;
    logic         rd;
    logic [31:0]  adr;
    logic [31:0]  dat;
} cfg_req_t;

typedef struct packed {
    logic            dvld;
    logic [31:0]     dat;
} cfg_cpl_t;

typedef struct packed {
    logic   [63:0]    wadr;
    logic   [63:0]    radr;
    logic   [27:0]    len;
    logic             eop;
    logic             irq;
    logic             stop;
} dsc_dat_t;

typedef struct packed {
    logic [`ADR_WIDTH-1:0] adr;
    logic [`RID_WIDTH-1:0] rid;
    logic [`LEN_WIDTH-1:0] len;   // byte length
    logic [5:0]            off;   // Source offset
    logic                  eop;
    logic                  eod;
    logic                  eor;
} wr_req_t;

typedef struct packed {
    logic                  start ;
    logic                  fixed ;
    logic                  nowb  ;
    logic [63:0]           pm_adr;
} reg_t;

typedef struct packed {
    logic    [9:0]       len;
    logic    [6:0]       lowaddr;
    logic    [11:0]      bytecnt;
    logic    [2:0]       tc;
    logic    [2:0]       attr;
    logic    [15:0]      reqid;
    logic    [7:0]       tag;
    logic    [3:0]       off;
    logic                eor;
} brdg_rd_req_t;

typedef struct packed {
    logic    [9:0]       dwlen;
    logic    [6:0]       lowaddr;
    logic    [11:0]      bytecnt;
    logic    [2:0]       tc;
    logic    [2:0]       attr;
    logic    [15:0]      reqid;
    logic    [7:0]       tag;
    logic    [9:0]       bt;
    logic                bte1;
    logic                eloc;
    logic                eor;
} rhdr_t;

typedef struct packed {
    logic    [9:0]       len;
    logic    [11:0]      addr;
    logic    [7:0]       dwbe;
    logic    [2:0]       tc;
    logic    [2:0]       attr;
    logic    [15:0]      id;
    logic    [7:0]       tag;
} brdg_dsc_t;

`endif
