module  SRAM #(
    parameter                   WgtPresent  =   1
)   (
    input   wire                clk,
    input   wire                rstn,
    input   wire    [8:0]       Addr_i,
	 input   wire                wr_i,
    input   wire    [63:0]     ByteEnable_i,
    output  wire    [511:0]    ReadData_o,
    input   wire    [511:0]    WriteData_i
);

genvar i;

reg     [511:0] Mem [511:0];

//generate
//    if(!WgtPresent)
//        initial begin
//            $readmemh("InitialMem.hex",Mem);
//        end
//    else
//        initial begin
//            $readmemh("weight.txt",Mem);
//        end
//endgenerate

reg     [8:0]  ReadAddr;

always@(posedge clk or negedge rstn) begin
    if(~rstn)
        ReadAddr    <=  9'h0;
    else
        ReadAddr    <=  Addr_i;
end

generate 
    for(i = 0;i < 64;i = i + 1) begin : block

        always@(posedge clk) begin
            if(ByteEnable_i[i])
                Mem[Addr_i][i*8+7:i*8]    <=  WriteData_i[i*8+7:i*8];
        end

    end
endgenerate


assign  ReadData_o    =   Mem[ReadAddr];

//ram u0(
//	.clock(clk),
//	.byteena(ByteEnable_i),
//	.data(WriteData_i),
//	.address(Addr_i),
//	.wren(wr_i),
//	.q(ReadData_o)
//	);

endmodule



