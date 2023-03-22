module AvalonBusUpSizer (
    input   wire                    clk,
    input   wire                    rstn,

    input   wire    [14:0]          SlaveAddr_i,
    input   wire                    SlaveRead_i,
    input   wire                    SlaveWrite_i,
    input   wire    [15:0]          SlaveByteEnable_i,
    input   wire    [127:0]         SlaveWriteData_i,
    output  wire    [127:0]         SlaveReadData_o,
    output  wire                    SlaveWaitReq_o,

    output  wire    [63:0]          MasterAddr_o,
    output  wire                    MasterRead_o,
    output  wire                    MasterWrite_o,
    output  wire    [63:0]         MasterByteEnable_o,
    output  wire    [511:0]        MasterWriteData_o,
    input   wire    [511:0]        MasterReadData_i,
    input   wire                    MasterWaitReq_i
);

assign  MasterAddr_o    =   {51'b0,SlaveAddr_i[14:2]};

assign  MasterRead_o    =   SlaveRead_i;

assign  MasterWrite_o   =   SlaveWrite_i;

genvar i;

generate
    for(i = 0;i < 4;i = i + 1) begin: ByteEn

        assign  MasterByteEnable_o[i*16+15:i*16]    =   {16{SlaveAddr_i[1:0]    ==  i}} &   SlaveByteEnable_i;

    end
endgenerate

assign  MasterWriteData_o   =   {4{SlaveWriteData_i}};

reg     [1:0]   SlaveAddrReg;

always@(posedge clk or negedge rstn) begin
    if(~rstn) 
        SlaveAddrReg    <=  2'b0;
    else if(~MasterWaitReq_i) begin
        SlaveAddrReg    <=  SlaveAddr_i[1:0];
    end
end

assign  SlaveReadData_o     =   ({128{SlaveAddrReg  ==  2'b00}}    &   MasterReadData_i[127:0])     |
                                ({128{SlaveAddrReg  ==  2'b01}}    &   MasterReadData_i[255:128])   |
                                ({128{SlaveAddrReg  ==  2'b10}}    &   MasterReadData_i[383:256])   |
                                ({128{SlaveAddrReg  ==  2'b11}}    &   MasterReadData_i[511:384]) ;
                                //({128{SlaveAddrReg  ==  3'b100}}    &   MasterReadData_i[639:512])   |
                                //({128{SlaveAddrReg  ==  3'b101}}    &   MasterReadData_i[767:640])   |
                                //({128{SlaveAddrReg  ==  3'b110}}    &   MasterReadData_i[895:768])   |
                                //({128{SlaveAddrReg  ==  3'b111}}    &   MasterReadData_i[1023:896])  ;

assign  SlaveWaitReq_o      =   MasterWaitReq_i;

endmodule
