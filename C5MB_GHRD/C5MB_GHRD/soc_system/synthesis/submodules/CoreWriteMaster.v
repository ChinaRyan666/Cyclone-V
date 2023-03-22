module  CoreWriteMaster #(
    parameter                   InitialAddr = 64'h0
)   (
    input   wire                clk,
    input   wire                rstn,

    //  From WriteBuffer
    input   wire    [511:0]    WriteBuffer_i,
    input   wire                WriteReq_i,
    output  wire                WriteAck_o,
    input   wire                First_i,
    input   wire                Last_i,

    //  Write Only Master Side
    output  wire    [63:0]      AvalonAddr_o,
    output  wire                AvalonRead_o,
    output  wire                AvalonWrite_o,
    output  wire    [63:0]     AvalonByteEnable_o,
    output  wire    [511:0]    AvalonWriteData_o,
    input   wire    [511:0]    AvalonReadData_i,
    output  wire                AvalonLock_o,
    input   wire                AvalonWaitReq_i,

    //  To TOP FSM
    input   wire                AccuEn_i,
    output  wire                Done_o      
);


wire    FirstReg;

wire    [8:0]    AddrCounter;
wire    [8:0]    AddrCounterNxt;

assign      AddrCounterNxt  =   (First_i  | FirstReg) ?   9'h1    :   AddrCounter +   9'b1;

ConvDFF #(
    .WIDTH          (9),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   LineCnt (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (WriteReq_i & ~AvalonWaitReq_i),
    .D_i            (AddrCounterNxt),
    .Q_o            (AddrCounter)
);

//  Ack to WriteBuffer
assign  WriteAck_o  =   WriteReq_i & ~AvalonWaitReq_i;

//  Avalon Side
assign  AvalonAddr_o[62:0]  =   ((First_i | FirstReg) ?   9'h0    :   AddrCounter) + InitialAddr;
assign  AvalonAddr_o[63]    =   AccuEn_i;
assign  AvalonRead_o        =   1'b0;
assign  AvalonWrite_o       =   WriteReq_i;
assign  AvalonByteEnable_o  =   {64{1'b1}};
assign  AvalonWriteData_o   =   WriteBuffer_i;
assign  AvalonLock_o        =   WriteReq_i;

//  TOP FSM
wire    Last;

ConvDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   LastRegister (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (Done_o),
    .Enable_i       (Last_i),
    .D_i            (1'b1),
    .Q_o            (Last)
);


ConvDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   FirstRegister (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (~AvalonWaitReq_i),
    .Enable_i       (First_i),
    .D_i            (1'b1),
    .Q_o            (FirstReg)
);


assign  Done_o  =   Last & ~WriteReq_i;

endmodule