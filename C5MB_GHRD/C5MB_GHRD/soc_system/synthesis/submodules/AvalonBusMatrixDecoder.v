module AvalonBusMatrixDecoder #(
	parameter					Port0En	=	1'b1,
	parameter					Port1En	=	1'b1,
	parameter					Port2En	=	1'b1,
	parameter					MstID	=	3'h0
)	(
	//	System Signals
	input	wire				clk,
	input	wire				rstn,

	//	Master Input Signals
	input	wire	[63:0]		Addr_i,
	input	wire				RdEn_i,
	input	wire				WrEn_i,

	//	Slave 0 Input Signals
	input	wire	[511:0]  	RdData0_i,
	input	wire				WaitReq0_i,
	input	wire	[2:0]		PortSel0_i,

	//	Slave 1 Input Signals
	input	wire	[511:0] 	RdData1_i,
	input	wire				WaitReq1_i,
	input	wire	[2:0]		PortSel1_i,

	//	Slave 2 Input Signals
	input	wire	[511:0]	    RdData2_i,
	input	wire				WaitReq2_i,
	input	wire	[2:0]		PortSel2_i,

	//	Request Signals
	output	wire				Req0_o,
	output	wire				Req1_o,
	output	wire				Req2_o,

	//	Master Output Signals
	output	wire	[511:0]	    RdDataDec_o,
	output	wire				WaitReq_o
);

assign	Req0_o	=	(Addr_i[10:9]	==	2'h0)	&	Port0En	&	(RdEn_i	|	WrEn_i);
assign	Req1_o	=	(Addr_i[10:9]	==	2'h1)	&	Port1En	&	(RdEn_i	|	WrEn_i);
assign	Req2_o	=	(Addr_i[10:9]	==	2'h2)	&	Port2En	&	(RdEn_i	|	WrEn_i);

reg	[2:0]	Sel;

always@(posedge clk or negedge rstn)
	if(~rstn)
		Sel	<=	3'b0;
	else if(~WaitReq_o)
		Sel	<=	{Req0_o, Req1_o, Req2_o};

assign	RdDataDec_o	=	({512{Sel[0]}}	&	RdData2_i)	|
						({512{Sel[1]}}	&	RdData1_i)	|
						({512{Sel[2]}}	&	RdData0_i)	;

assign	WaitReq_o	=	(Req0_o	&	((PortSel0_i	!=	MstID)	|	WaitReq0_i))	|
						(Req1_o	&	((PortSel1_i	!=	MstID)	|	WaitReq1_i))	|
						(Req2_o	&	((PortSel2_i	!=	MstID)	|	WaitReq2_i))	;

endmodule
