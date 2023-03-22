module  FullConnect_CoreWriteMaster #(
    parameter                   WriteNum = 9'h1,
    parameter                       AvalonByteEnable_WIDTH        =   64,
    parameter                       AvalonData_WIDTH        =   512
)   (
    input   wire                clk,
    input   wire                rstn,
    input   wire  [63:0]        InitialAddr,

    //  From WriteBuffer
    input   wire    [AvalonData_WIDTH-1:0]     WriteData_i,
    input   wire                WriteReq_i,
    output  wire                WriteAck_o,
    

    //  Write Only Master Side
    output  wire    [63:0]      AvalonAddr_o,
    output  wire                AvalonRead_o,
    output  wire                AvalonWrite_o,
    output  wire    [AvalonByteEnable_WIDTH-1:0]      AvalonByteEnable_o,
    output  wire    [AvalonData_WIDTH-1:0]     AvalonWriteData_o,
    input   wire    [AvalonData_WIDTH-1:0]     AvalonReadData_i,
    output  wire                AvalonLock_o,
    input   wire                AvalonWaitReq_i,

    //  To TOP FSM
    output  wire                Done_o      
);

//  Ack to WriteBuffer
assign  WriteAck_o  =   WriteReq_i ? (~AvalonWaitReq_i) : 1'b1;

//  Avalon Side
assign  AvalonAddr_o        =   InitialAddr;
assign  AvalonRead_o        =   1'b0;
assign  AvalonWrite_o       =   WriteReq_i;
assign  AvalonByteEnable_o  =   {AvalonByteEnable_WIDTH{1'b1}};
assign  AvalonWriteData_o   =   WriteReq_i ? WriteData_i : {AvalonData_WIDTH{1'b0}};
assign  AvalonLock_o        =   WriteReq_i;

//  TOP FSM
wire    [8:0]   WriteAddr;
wire    [8:0]   WriteAddrNxt;
wire            WriteDone;
wire            WriteDoneReg1;


FullConnectDFF #(
    .WIDTH          (9),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   WriteAddrCnt (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (Done_o),
    .Enable_i       (AvalonWrite_o & ~AvalonWaitReq_i),
    .D_i            (WriteAddrNxt),
    .Q_o            (WriteAddr)                
);

assign  WriteAddrNxt  =   WriteAddr + 1'b1;
assign  WriteDone     =   WriteAddr ==  WriteNum;  

assign  Done_o  =   WriteDone;  

endmodule