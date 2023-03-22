module  RBMaster    #(
    parameter       BUSWIDTH            =      512 ,
    parameter       BYTEENABLEWIDTH      =      64  
)	(
    input   wire                              clk,
    input   wire                              rstn,

    // Read Only Master Side
    input   wire    [63:0]                    RdMstAddr_i,
    input   wire                              RdMstRead_i,
    input   wire                              RdMstWrite_i,
    input   wire    [BYTEENABLEWIDTH-1:0]     RdMstByteEnable_i,
    input   wire    [BUSWIDTH-1:0]           RdMstWriteData_i,
    output  wire    [BUSWIDTH-1:0]           RdMstReadData_o,
    input   wire                              RdMstLock_i,
    output  wire                              RdMstWaitReq_o,  

    // Write Only Master Side
    input   wire    [63:0]                   WrMstAddr_i,
    input   wire                             WrMstRead_i,
    input   wire                             WrMstWrite_i,
    input   wire    [BYTEENABLEWIDTH-1:0]    WrMstByteEnable_i,
    input   wire    [BUSWIDTH-1:0]          WrMstWriteData_i,
    output  wire    [BUSWIDTH-1:0]          WrMstReadData_o,
    input   wire                             WrMstLock_i,
    output  wire                             WrMstWaitReq_o,    

    //  Core Master
    output  wire    [63:0]                    AvalonAddr_o,
    output  wire                              AvalonRead_o,
    output  wire                              AvalonWrite_o,
    output  wire    [BYTEENABLEWIDTH-1:0]     AvalonByteEnable_o,
    output  wire    [BUSWIDTH-1:0]           AvalonWriteData_o,
    input   wire    [BUSWIDTH-1:0]           AvalonReadData_i,
    output  wire                              AvalonLock_o,
    input   wire                              AvalonWaitReq_i         

);



assign  AvalonAddr_o        =   WrMstWrite_i    ?   WrMstAddr_i :   RdMstAddr_i;
assign  AvalonRead_o        =   ~WrMstWrite_i   &   RdMstRead_i;
assign  AvalonWrite_o       =   WrMstWrite_i;
assign  AvalonByteEnable_o  =   WrMstWrite_i    ?   WrMstByteEnable_i   :   RdMstByteEnable_i;
assign  AvalonWriteData_o   =   WrMstWriteData_i;
assign  RdMstReadData_o     =   AvalonReadData_i;
assign  WrMstReadData_o     =   {BUSWIDTH{1'b0}};
assign  AvalonLock_o        =   WrMstWrite_i    ?   WrMstLock_i :   RdMstLock_i;
assign  WrMstWaitReq_o      =   WrMstWrite_i    &   AvalonWaitReq_i;
assign  RdMstWaitReq_o      =   WrMstWrite_i    |   AvalonWaitReq_i;

endmodule