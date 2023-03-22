module  AvalonMem #(
    parameter                   WgtPresent  =   1,
    parameter                   NmcPresent  =   1
)   (
    input   wire                clk,
    input   wire                rstn,

    input   wire    [63:0]      AvalonAddr_i,
    input   wire                AvalonRead_i,
    input   wire                AvalonWrite_i,
    input   wire    [63:0]     AvalonByteEnable_i,
    output  wire    [511:0]    AvalonReadData_o,
    input   wire    [511:0]    AvalonWriteData_i,
    input   wire                AvalonLock_i,
    output  wire                AvalonWaitReq_o

);

wire    [8:0]      SramAddr;
wire    [63:0]     SramByteEnable;
wire    [511:0]    SramWriteData;
wire    [511:0]    SramReadData;
wire               Sram_wren;

AvalonMemIntf #(
    .NmcPresent         (NmcPresent)
)   Interface(
    .clk                (clk),
    .rstn               (rstn),
    .AvalonAddr_i       (AvalonAddr_i),
    .AvalonRead_i       (AvalonRead_i),
    .AvalonWrite_i      (AvalonWrite_i),
    .AvalonByteEnable_i (AvalonByteEnable_i),
    .AvalonReadData_o   (AvalonReadData_o),
    .AvalonWriteData_i  (AvalonWriteData_i),
    .AvalonLock_i       (AvalonLock_i),
    .AvalonWaitReq_o    (AvalonWaitReq_o),
    .SramAddr_o         (SramAddr),
    .SramByteEnable_o   (SramByteEnable),
    .SramWriteData_o    (SramWriteData),
	 .Sram_wren          (Sram_wren),
    .SramReadData_i     (SramReadData)
);

SRAM #(
    .WgtPresent         (WgtPresent)
)   BRAM (
    .clk                (clk),
    .rstn               (rstn),
	 .wr_i               (Sram_wren), 
    .Addr_i             (SramAddr),
    .ByteEnable_i       (SramByteEnable),
    .ReadData_o         (SramReadData),
    .WriteData_i        (SramWriteData)
);

endmodule