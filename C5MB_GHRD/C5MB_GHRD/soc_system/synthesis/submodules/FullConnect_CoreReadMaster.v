module  FullConnect_CoreReadMaster #(
    parameter                   InitialWeightAddr   =   64'h0,
    parameter                       AvalonByteEnable_WIDTH        =   64,
    parameter                       AvalonData_WIDTH        =   512
)   (
    input   wire                clk,
    input   wire                rstn,
    input   wire[63:0]          InitialDataAddr,

    //  From Top FSM
    input   wire                Start_i,        
    input   wire    [8:0]       Height_i,
    

    //  Read Only Master Side
    output  wire    [63:0]      AvalonAddr_o,
    output  wire                AvalonRead_o,
    output  wire                AvalonWrite_o,
    output  wire    [AvalonByteEnable_WIDTH-1:0]     AvalonByteEnable_o,
    output  wire    [AvalonData_WIDTH-1:0]           AvalonWriteData_o,
    input   wire    [AvalonData_WIDTH-1:0]           AvalonReadData_i,
    output  wire                AvalonLock_o,
    input   wire                AvalonWaitReq_i,       

    //  To MulAc
    output  wire                WgtValid_o ,    
    output  wire                DataValid_o,
    output  wire                DataDone_o,     
    output  wire    [AvalonData_WIDTH-1:0]     Weight_o ,
    output  wire    [AvalonData_WIDTH-1:0]     Data_o
    

);

//  Weight and Data Read State Reg
wire            WBState;
wire            IBState;
//  Weight and Data AddrCounter 
wire    [8:0]   WgtAddr;
wire    [8:0]   WgtAddrNxt;
wire            WgtDone;
wire    [8:0]   DataAddr;
wire    [8:0]   DataAddrNxt;
wire            DataDone;
wire            WBStateReg;
wire    [8:0]   WgtAddrReg;
wire            WgtDoneReg;
wire            IBStateReg;
wire    [8:0]   DataAddrReg;
wire            DataDoneReg;
wire            DataDoneReg2;
wire            WaitReg;
wire            WgtValid ;
wire            DataValid;


FullConnectDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b1)
)   WgtStateReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (Start_i | (IBState & ~AvalonWaitReq_i & ~WgtDone)),
    .Enable_i       (WBState & ~AvalonWaitReq_i),
    .D_i            (1'b0),
    .Q_o            (WBState)                
);

FullConnectDFF #(
    .WIDTH          (9),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   WgtAddrCnt (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (Start_i),
    .Enable_i       (WBState & ~AvalonWaitReq_i),
    .D_i            (WgtAddrNxt),
    .Q_o            (WgtAddr)                
);


assign  WgtAddrNxt  =   WgtAddr + 1'b1;
assign  WgtDone     =   WgtAddr ==  Height_i;  

FullConnectDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b1)
)   DataStateReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (WBState & ~AvalonWaitReq_i),
    .Enable_i       (IBState & ~AvalonWaitReq_i),
    .D_i            (1'b0),
    .Q_o            (IBState)                
);

FullConnectDFF #(
    .WIDTH          (9),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   DataAddrCnt (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (Start_i),
    .Enable_i       (IBState & ~AvalonWaitReq_i),
    .D_i            (DataAddrNxt),
    .Q_o            (DataAddr)                
);

assign  DataAddrNxt  =   DataAddr + 1'b1;
assign  DataDone     =   DataAddr ==  Height_i;  

FullConnectDFF #(
    .WIDTH          (11),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   WBCtrlReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (1'b1),
    .D_i            ({WgtAddr,WBState,WgtDone}),
    .Q_o            ({WgtAddrReg,WBStateReg,WgtDoneReg})
);

FullConnectDFF #(
    .WIDTH          (11),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   IBCtrlReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (1'b1),
    .D_i            ({DataAddr,IBState,DataDone}),
    .Q_o            ({DataAddrReg,IBStateReg,DataDoneReg})
);

FullConnectDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   AvalonWaitReqReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (1'b1),
    .D_i            (AvalonWaitReq_i),
    .Q_o            (WaitReg)
);

FullConnectDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   DataDoneReg_2 (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (1'b1),
    .D_i            (DataDoneReg),
    .Q_o            (DataDoneReg2)
);



assign WgtValid_o  = WBStateReg & ~WaitReg; // change register level corresponding to avalon mm read latency
assign DataValid_o = IBStateReg & ~WaitReg;
assign DataDone_o  = DataDoneReg & ~DataDoneReg2;
assign Weight_o    = AvalonReadData_i;
assign Data_o      = AvalonReadData_i;


//  Avalon Side 
assign  AvalonAddr_o        =   ({64{WBState}} & (WgtAddr + InitialWeightAddr)) |
                                ({64{IBState}} & (DataAddr + InitialDataAddr)) ;
assign  AvalonRead_o        =   IBState | WBState;
assign  AvalonWrite_o       =   1'b0;
assign  AvalonByteEnable_o  =   {AvalonByteEnable_WIDTH{1'b1}};
assign  AvalonLock_o        =   IBState | WBState;
assign  AvalonWriteData_o   =   {AvalonData_WIDTH{1'b0}};



endmodule