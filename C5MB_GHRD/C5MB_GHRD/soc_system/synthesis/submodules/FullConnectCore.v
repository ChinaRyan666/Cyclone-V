`define BUS_ADDR_1024BIT
module  FullConnectCore #(
    parameter                   WeightMemAddr     =   64'h0,
    parameter                       AvalonByteEnable_WIDTH        =   64,
    parameter                       AvalonData_WIDTH        =   512
)   (
    input   wire                clk,
    input   wire                rstn,
    input   wire [63:0]         DataMemAddr     ,
    input   wire [63:0]         WriteBackMemAddr,

    //  Config Information
    input   wire    [3:0]       DataBp_i,
    input   wire    [3:0]       WeightBp_i,
    input   wire    [3:0]       ResultBp_i,
    input   wire                Accu_i,

    //  PrivateMem Read Control
    input   wire    [8:0]       Height_i,
    input   wire                Start_i,

    //  Operation Complete Signal
    output  wire                Done_o,

  
    //  Avalon-MM Master
    output  wire    [63:0]      AvalonAddr_o,
    output  wire                AvalonRead_o,
    output  wire                AvalonWrite_o,
    output  wire    [AvalonByteEnable_WIDTH-1:0]    AvalonByteEnable_o,
    output  wire    [AvalonData_WIDTH-1:0]          AvalonWriteData_o,
    input   wire    [AvalonData_WIDTH-1:0]          AvalonReadData_i,   
    output  wire                AvalonLock_o,
    input   wire                AvalonWaitReq_i,

   
    output  wire                Halt_o  

);

wire                RdMstValid;
wire    [AvalonByteEnable_WIDTH-1:0]       RdMstEnable;
wire    [AvalonData_WIDTH-1:0]     RdMstLine;
wire                RdMstFirst;
wire                RdMstLast;
wire    [63:0]      RdMstAddr;
wire                RdMstRead;
wire                RdMstWrite;
wire    [AvalonByteEnable_WIDTH-1:0]     RdMstByteEnable;
wire    [AvalonData_WIDTH-1:0]           RdMstWriteData;
wire    [AvalonData_WIDTH-1:0]           RdMstReadData;
wire                RdMstLock;
wire                RdMstWaitReq;
wire                WgtValid;
wire                DataValid;
wire                DataDone;
wire    [AvalonData_WIDTH-1:0]     Weight;
wire    [AvalonData_WIDTH-1:0]     Data;
wire    [31:0]      MulAc_Result;
wire                Result_valid;

FullConnect_CoreReadMaster  #(
    .InitialWeightAddr          (WeightMemAddr  ),
    .AvalonByteEnable_WIDTH             (AvalonByteEnable_WIDTH),
    .AvalonData_WIDTH                   (AvalonData_WIDTH      )
    
)   CoreRdMst(
    .clk                        (clk),
    .rstn                       (rstn),
    .InitialDataAddr            (DataMemAddr),
    .Start_i                    (Start_i),
    .Height_i                   (Height_i),
    .AvalonAddr_o               (RdMstAddr),                // connect to CoreMaster
    .AvalonRead_o               (RdMstRead),
    .AvalonWrite_o              (RdMstWrite),
    .AvalonByteEnable_o         (RdMstByteEnable),
    .AvalonWriteData_o          (RdMstWriteData),
    .AvalonReadData_i           (RdMstReadData),
    .AvalonLock_o               (RdMstLock),
    .AvalonWaitReq_i            (RdMstWaitReq),
    .WgtValid_o                 (WgtValid),                 // connect to MulAc
    .DataValid_o                (DataValid),
    .DataDone_o                 (DataDone),
    .Weight_o                   (Weight),
    .Data_o                     (Data)
);
    

FullConnect_MulAc   #(
    .AvalonData_WIDTH                   (AvalonData_WIDTH      )
)    MAC(
    .clk                        (clk),
    .rstn                       (rstn),
    .Start_i                    (Start_i),
    .Halt_i                     (Halt_o),
    .Accu_i                     (Accu_i),
    .DataBp_i                   (DataBp_i),
    .WeightBp_i                 (WeightBp_i),
    .ResultBp_i                 (ResultBp_i),
    .WgtValid_i                 (WgtValid),
    .DataValid_i                (DataValid),
    .DataDone_i                 (DataDone),
    .Weight_i                   (Weight),
    .Data_i                     (Data),
    .MulAc_o                    (MulAc_Result),
    .Result_valid_o             (Result_valid)
);

wire    [63:0]      WrMstAddr;
wire                WrMstRead;
wire                WrMstWrite;
wire    [AvalonByteEnable_WIDTH-1:0]      WrMstByteEnable;
wire    [AvalonData_WIDTH-1:0]     WrMstWriteData;
wire    [AvalonData_WIDTH-1:0]     WrMstReadData;
wire                WrMstLock;
wire                WrMstWaitReq;
wire    [AvalonData_WIDTH-1:0]     WriteData;
wire                WriteReq;
wire                WriteAck;

FullConnect_WriteBuffer   #(
    .AvalonData_WIDTH                   (AvalonData_WIDTH      )
)    inst_WriteBuffer(
    .clk                        (clk),
    .rstn                       (rstn),
    .Valid_i                   (Result_valid),
    .Halt_o                    (Halt_o),
    .Data_i                    (MulAc_Result),
    .WriteData_o                (WriteData),
    .WriteReq_o                 (WriteReq),
    .WriteAck_i                 (WriteAck)
);


FullConnect_CoreWriteMaster #(
    .AvalonByteEnable_WIDTH             (AvalonByteEnable_WIDTH),
    .AvalonData_WIDTH                   (AvalonData_WIDTH      )
)   CoreWrMst (
    .clk                        (clk),
    .rstn                       (rstn),
    .InitialAddr                (WriteBackMemAddr),
    .WriteData_i             (WriteData),
    .WriteReq_i              (WriteReq),
    .WriteAck_o              (WriteAck),
    
    .AvalonAddr_o               (WrMstAddr),
    .AvalonRead_o               (WrMstRead),
    .AvalonWrite_o              (WrMstWrite),
    .AvalonByteEnable_o         (WrMstByteEnable),
    .AvalonWriteData_o          (WrMstWriteData),
    .AvalonReadData_i           (WrMstReadData),
    .AvalonLock_o               (WrMstLock),
    .AvalonWaitReq_i            (WrMstWaitReq),
    .Done_o                     (Done_o)
);



FullConnect_CoreMaster  #(
    .AvalonByteEnable_WIDTH             (AvalonByteEnable_WIDTH),
    .AvalonData_WIDTH                   (AvalonData_WIDTH      )
)    CoreMst (
    .clk                        (clk),
    .rstn                       (rstn),
    .RdMstAddr_i                (RdMstAddr),
    .RdMstRead_i                (RdMstRead),
    .RdMstWrite_i               (RdMstWrite),
    .RdMstByteEnable_i          (RdMstByteEnable),
    .RdMstWriteData_i           (RdMstWriteData),
    .RdMstReadData_o            (RdMstReadData),
    .RdMstLock_i                (RdMstLock),
    .RdMstWaitReq_o             (RdMstWaitReq),
    .WrMstAddr_i                (WrMstAddr),
    .WrMstRead_i                (WrMstRead),
    .WrMstWrite_i               (WrMstWrite),
    .WrMstByteEnable_i          (WrMstByteEnable),
    .WrMstWriteData_i           (WrMstWriteData),
    .WrMstReadData_o            (WrMstReadData),
    .WrMstLock_i                (WrMstLock),
    .WrMstWaitReq_o             (WrMstWaitReq),
    .AvalonAddr_o               (AvalonAddr_o),
    .AvalonRead_o               (AvalonRead_o),
    .AvalonWrite_o              (AvalonWrite_o),
    .AvalonByteEnable_o         (AvalonByteEnable_o),
    .AvalonWriteData_o          (AvalonWriteData_o),
    .AvalonReadData_i           (AvalonReadData_i),
    .AvalonLock_o               (AvalonLock_o),
    .AvalonWaitReq_i            (AvalonWaitReq_i)
);

endmodule