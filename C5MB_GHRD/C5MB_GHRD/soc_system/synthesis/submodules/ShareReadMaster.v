module  ShareReadMaster #(
    parameter                   InitialDataAddr     =   64'h0,
    parameter                   InitialWeightAddr   =   64'h0
)   (
    input   wire                clk,
    input   wire                rstn,

    //  From Top FSM
    input   wire                Start_i,
    input   wire    [8:0]       Height_i,
    input   wire                Share_i,

    input   wire                Halt_i,

    //  Read Only Master Side
    output  wire    [63:0]      AvalonAddr_o,
    output  wire                AvalonRead_o,
    output  wire                AvalonWrite_o,
    output  wire    [63:0]     AvalonByteEnable_o,
    // output  wire    [1023:0]    AvalonWriteData_o,
    // input   wire    [1023:0]    AvalonReadData_i,
    output  wire    [511:0]    AvalonWriteData_o,
    input   wire    [511:0]    AvalonReadData_i,	
    output  wire                AvalonLock_o,
    input   wire                AvalonWaitReq_i,       

    //  To IFBuffer
    output  wire                IBValid_o,
    // output  wire    [1023:0]    IBLine_o,
    output  wire    [511:0]    IBLine_o,	
    output  wire                IBFirst_o,
    output  wire                IBLast_o,

    output  wire                WBReady_o,

    //  To WeightBuffer
    // output  wire    [1023:0]    WBLine_o,
    output  wire    [511:0]    WBLine_o,	
    output  wire                WBValid_o

);

//  Weight Read State Reg
wire            WBState;


ConvDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   WgtStateReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (WBState & ~AvalonWaitReq_i),
    .Enable_i       (Start_i),
    .D_i            (1'b1),
    .Q_o            (WBState)
);

wire            WBStateReg;
wire            WaitReg;

ConvDFF #(
    .WIDTH          (2),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   WBCtrlReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (~Halt_i),
    .D_i            ({WBState,AvalonWaitReq_i}),
    .Q_o            ({WBStateReg,WaitReg})
);


//  IF Read IBState Reg
wire            IBState;

//  Address Counter
wire    [8:0]   AddrCounter;
wire    [8:0]   AddrCounterNxt;

assign    AddrCounterNxt  =   AddrCounter +   9'h1;

ConvDFF #(
    .WIDTH          (9),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   AddrCnt (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (WBState & Share_i),
    .Enable_i       (IBState & ~Halt_i & ~AvalonWaitReq_i),
    .D_i            (AddrCounterNxt),
    .Q_o            (AddrCounter)
);

wire            AddrCountDone;
assign  AddrCountDone   =   AddrCounter ==  Height_i - 1'b1;

ConvDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   StateReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (IBState & AddrCountDone & ~AvalonWaitReq_i),
    .Enable_i       (WBState & Share_i & ~AvalonWaitReq_i),
    .D_i            (1'b1),
    .Q_o            (IBState)
);

wire            HaltReg;
wire            AddrDoneReg;
wire            IBStateReg;

ConvDFF #(
    .WIDTH          (3),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   IBCtrlReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (1'b1),
    .D_i            ({Halt_i,AddrCountDone,IBState}),
    .Q_o            ({HaltReg,AddrDoneReg,IBStateReg})
);

wire    First;

ConvDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   FirstReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (IBStateReg),
    .Enable_i       (Start_i),
    .D_i            (1'b1),
    .Q_o            (First)
);

//  Avalon Side 
assign  AvalonAddr_o        =   ({64{WBState}} & (InitialWeightAddr)) |
                                ({64{IBState}} & (AddrCounter + InitialDataAddr)) ;
assign  AvalonRead_o        =   IBState | WBState;
assign  AvalonWrite_o       =   1'b0;
assign  AvalonByteEnable_o  =   {64{1'b1}};
assign  AvalonLock_o        =   IBState;
assign  AvalonWriteData_o   =   512'b0;

//  IFBuffer Side
assign  IBValid_o           =   IBStateReg  &   ~WaitReg;
assign  IBLine_o            =   AvalonReadData_i;
assign  IBFirst_o           =   IBStateReg  &   First       &   ~WaitReg;
assign  IBLast_o            =   IBStateReg  &   AddrDoneReg &   ~WaitReg; 

//  WgtBuffer Side
assign  WBLine_o            =   AvalonReadData_i;
assign  WBReady_o           =   WBStateReg;
assign  WBValid_o           =   ~WaitReg    &   WBStateReg;


endmodule