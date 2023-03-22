module  ConvCore #(
    parameter                   PrivateMemAddr  =   64'h0
)   (
    input   wire                clk,
    input   wire                rstn,

    //  Config Information
    input   wire    [2:0]       ConvSize_i,
    input   wire    [3:0]       DataBp_i,
    input   wire    [3:0]       WeightBp_i,
    input   wire    [3:0]       ResultBp_i,
    input   wire                AccuEn_i,

    //  PrivateMem Read Control
    input   wire    [8:0]       Height_i,
    input   wire                Start_i,

    //  Operation Complete Signal
    output  wire                Done_o,

    //  IFBuffer Shared Data
    input   wire                ShareValid_i,
    // input   wire    [1023:0]    ShareLine_i,
    input   wire    [511:0]     ShareLine_i,	
    input   wire                ShareFirst_i,
    input   wire                ShareLast_i,

    //  Avalon-MM Master
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

    //  Weight From Top
    // input   wire    [1023:0]    Weight_i,
    input   wire    [511:0]    Weight_i,	

    output  wire                Halt_o  

);


wire                IBValid;
// wire    [1023:0]    IBData;
wire    [511:0]     IBData;
wire                IBFirst;
wire                IBLast;

IFBuffer IFBuf(
    .clk                        (clk),
    .rstn                       (rstn),
    .ShareValid_i               (ShareValid_i),
    .ShareLine_i                (ShareLine_i),
    .ShareFirst_i               (ShareFirst_i),
    .ShareLast_i                (ShareLast_i),
    .Valid_o                    (IBValid),
    .Data_o                     (IBData),
    .First_o                    (IBFirst),
    .Last_o                     (IBLast),
    .Halt_i                     (Halt_o)
);

wire                MacValid;
wire                MacFirst;
wire                MacLast;      
// wire    [15:0]      Conv8;
// wire    [15:0]      Conv7;
// wire    [15:0]      Conv6;
// wire    [31:0]      Conv5;
// wire    [63:0]      Conv4;
// wire    [63:0]      Conv3;
// wire    [255:0]     Conv2;
// wire    [1023:0]    Conv1;
wire     [31:0]      Conv8;
wire     [31:0]      Conv7;
wire     [31:0]      Conv6;
wire     [63:0]      Conv5;
wire     [127:0]     Conv4;
wire     [127:0]     Conv3;
wire     [511:0]     Conv2;
wire     [2047:0]    Conv1;

MulAc   MAC(
    .clk                        (clk),
    .rstn                       (rstn),
    .First_i                    (IBFirst),
    .Last_i                     (IBLast),
    .Valid_i                    (IBValid),
    .Data_i                     (IBData),
    .Weight_i                   (Weight_i),
    .Conv8_o                    (Conv8),
    .Conv7_o                    (Conv7),
    .Conv6_o                    (Conv6),
    .Conv5_o                    (Conv5),
    .Conv4_o                    (Conv4),
    .Conv3_o                    (Conv3),
    .Conv2_o                    (Conv2),
    .Conv1_o                    (Conv1),
    .First_o                    (MacFirst),
    .Last_o                     (MacLast),
    .Valid_o                    (MacValid),
    .DataBp_i                   (DataBp_i),
    .WeightBp_i                 (WeightBp_i),
    .ResultBp_i                 (ResultBp_i),
    .Halt_i                     (Halt_o),
    .ConvSize_i                 (ConvSize_i)
);

// wire    [1023:0]    WriteBuffer;
wire    [511:0]    WriteBuffer;
wire                WriteReq;
wire                WriteAck;
wire                WBFirst;
wire                WBLast;

WriteBuffer WB(
    .clk                        (clk),
    .rstn                       (rstn),
    .First_i                    (MacFirst),
    .Last_i                     (MacLast),
    .Valid_i                    (MacValid),
    .Conv8_i                    (Conv8),
    .Conv7_i                    (Conv7),
    .Conv6_i                    (Conv6),
    .Conv5_i                    (Conv5),
    .Conv4_i                    (Conv4),
    .Conv3_i                    (Conv3),
    .Conv2_i                    (Conv2),
    .Conv1_i                    (Conv1),
    .ConvSize_i                 (ConvSize_i),
    .WriteBuffer_o              (WriteBuffer),
    .WriteReq_o                 (WriteReq),
    .WriteAck_i                 (WriteAck),
    .First_o                    (WBFirst),
    .Last_o                     (WBLast),
    .Halt_o                     (Halt_o)
);


CoreWriteMaster #(
    .InitialAddr                (PrivateMemAddr)
)   CoreWrMst (
    .clk                        (clk),
    .rstn                       (rstn),
    .WriteBuffer_i              (WriteBuffer),
    .WriteReq_i                 (WriteReq),
    .WriteAck_o                 (WriteAck),
    .First_i                    (WBFirst),
    .Last_i                     (WBLast),
    .AvalonAddr_o               (AvalonAddr_o),
    .AvalonRead_o               (AvalonRead_o),
    .AvalonWrite_o              (AvalonWrite_o),
    .AvalonByteEnable_o         (AvalonByteEnable_o),
    .AvalonWriteData_o          (AvalonWriteData_o),
    .AvalonReadData_i           (AvalonReadData_i),
    .AvalonLock_o               (AvalonLock_o),
    .AvalonWaitReq_i            (AvalonWaitReq_i),
    .Done_o                     (Done_o),
    .AccuEn_i                   (AccuEn_i)
);

endmodule