module  CoreReadMaster #(
    parameter                   InitialAddr =   64'h0
)   (
    input   wire                clk,
    input   wire                rstn,

    //  From Top FSM
    input   wire                Start_i,
    input   wire    [8:0]       Height_i,
    input   wire                Share_i,

    //  Read Only Master Side
    output  wire    [63:0]      AvalonAddr_o,
    output  wire                AvalonRead_o,
    output  wire                AvalonWrite_o,
    output  wire    [127:0]     AvalonByteEnable_o,
    output  wire    [1023:0]    AvalonWriteData_o,
    input   wire    [1023:0]    AvalonReadData_i,
    output  wire                AvalonLock_o,
    input   wire                AvalonWaitReq_i,    

    //  To IFBuffer
    output  wire                Valid_o,
    output  wire    [1023:0]    Line_o,
    output  wire                First_o,
    output  wire                Last_o,

    //  PIPE HALT
    input   wire                Halt_i
);

//  State Reg
wire            State;

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
    .Set_i          (Start_i & ~Share_i),
    .Enable_i       (State & ~Halt_i & ~AvalonWaitReq_i),
    .D_i            (AddrCounterNxt),
    .Q_o            (AddrCounter)
);

wire            AddrCountDone;
assign  AddrCountDone   =   AddrCounter  ==  Height_i - 1'b1;

ConvDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   IBState (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (State & AddrCountDone & ~AvalonWaitReq_i),
    .Enable_i       (Start_i & ~Share_i),
    .D_i            (1'b1),
    .Q_o            (State)
);

wire            HaltReg;
wire            AddrDoneReg;
wire            StateReg;
wire            WaitReg;

ConvDFF #(
    .WIDTH          (4),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   CtrlReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (1'b1),
    .D_i            ({Halt_i,AvalonWaitReq_i,AddrCountDone,State}),
    .Q_o            ({HaltReg,WaitReg,AddrDoneReg,StateReg})
);

wire    First;

ConvDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b1)
)   FirstReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (Start_i),
    .Enable_i       (~WaitReg),
    .D_i            (1'b0),
    .Q_o            (First)
);


//  Avalon Side 
assign  AvalonAddr_o        =   AddrCounter +   InitialAddr;
assign  AvalonRead_o        =   State;
assign  AvalonWrite_o       =   1'b0;
assign  AvalonByteEnable_o  =   {128{1'b1}};
assign  AvalonLock_o        =   State;
assign  AvalonWriteData_o   =   1024'b0;

//  IFBuffer Side
assign  Valid_o             =   StateReg    &   ~WaitReg;
assign  Line_o              =   AvalonReadData_i;
assign  First_o             =   StateReg    &   First       &   ~WaitReg;
assign  Last_o              =   StateReg    &   AddrDoneReg &   ~WaitReg;

endmodule