module  Align #(
    parameter                           OPWIDTH =   24
)   (
    input   wire  signed  [OPWIDTH-1:0]       D_i,
    input   wire    [4:0]               OpBp_i,
    input   wire    [3:0]               RsBp_i,
    output  reg  signed  [7:0]              Q_o
);

//wire    S;
//
//wire    [OPWIDTH-2:0]   Abs;
//
//assign  Abs =   D_i[OPWIDTH-2:0];
//
//wire    [OPWIDTH+12:0]   Expand;
//
//assign  Expand  =   {{7{D_i[OPWIDTH-1]}},Abs,7'b0};
//
//wire    [6:0]   SelLSB;
//
//assign  SelLSB  =   OpBp_i + 7'h7 - RsBp_i;
//
//wire    [7:0]   AbsResult;
//
//genvar i;
//generate
//    for(i = 0;i < 7;i = i + 1) begin : bigmux
//        assign  AbsResult[i]    =   Expand[SelLSB+i];
//    end
//endgenerate
//
//assign  S   =   D_i[OPWIDTH-1] & |AbsResult;
//
//assign  Q_o =   {S,AbsResult};

wire SelLSB;
assign   SelLSB=(OpBp_i>RsBp_i)?1:0;
always@(*)
 begin
   if (SelLSB==1) 
	 Q_o<=D_i>>>(OpBp_i-RsBp_i);
	else
    Q_o<=D_i<<<(RsBp_i-OpBp_i);	
 end

endmodule



