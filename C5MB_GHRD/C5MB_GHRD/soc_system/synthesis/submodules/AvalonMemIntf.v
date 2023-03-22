module  AvalonMemIntf #(
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
    output  wire                AvalonWaitReq_o,

	output  wire    [8:0]       SramAddr_o,
    output  wire    [63:0]     SramByteEnable_o,
    output  wire    [511:0]    SramWriteData_o,
	 output  wire                Sram_wren, 
    input   wire    [511:0]    SramReadData_i

);

genvar i;


generate
    if(NmcPresent) begin : NmcMem

        wire    [511:0]    AccuOut;

        for(i = 0;i < 16;i = i + 1) begin : AddStg4
            Adder #(
                .WIDTH                  (32)
            )   AdderS4 (
                .D0_i                   (AvalonWriteData_i[i*32+31:i*32]),
                .D1_i                   (SramReadData_i[i*32+31:i*32]),
                .Q_o                    (AccuOut[i*32+31:i*32])
            );
        end

        wire    AccuWrite;
        wire    NormWrite;

        assign  AccuWrite   =   AvalonWrite_i   &   AvalonAddr_i[63];
        assign  NormWrite   =   AvalonWrite_i   &   ~AvalonAddr_i[63];

        wire    AccuWriteReg;

        ConvDFF #(
            .WIDTH          (1),
            .RstVal         (1'b0),
            .PstVal         (1'b0)
        )   AddrCnt (
            .clk            (clk),
            .rstn           (rstn),
            .Set_i          (AccuWriteReg),
            .Enable_i       (1'b1),
            .D_i            (AccuWrite),
            .Q_o            (AccuWriteReg)
        );

        assign  SramAddr_o          =   AvalonAddr_i[8:0];
        assign  SramByteEnable_o    =   AvalonByteEnable_i  &   {64{NormWrite  |   AccuWriteReg}};
        assign  SramWriteData_o     =   AccuWrite   ?   AccuOut :   AvalonWriteData_i;

        assign  AvalonReadData_o    =   SramReadData_i;
		  assign  Sram_wren           =   AccuWrite;
        assign  AvalonWaitReq_o     =   AccuWrite   &   ~AccuWriteReg;

    end else begin : NoNmc

        assign  SramAddr_o          =   AvalonAddr_i[8:0];
        assign  SramByteEnable_o    =   AvalonByteEnable_i & {64{AvalonWrite_i}};
        assign  SramWriteData_o     =   AvalonWriteData_i;
		  assign  Sram_wren           =   AvalonWrite_i;
        assign  AvalonReadData_o    =   SramReadData_i;
        assign  AvalonWaitReq_o     =   1'b0;

    end

endgenerate

endmodule



