module AvalonBusMatrixArbiter (
	//	System Signals
	input	wire				clk,
	input	wire				rstn,

	//	Request Signals
	input	wire				Req0_i,
	input	wire				Req1_i,
	input	wire				Req2_i,
	input	wire				Req3_i,
	input	wire				Req4_i,

	//	Arbitration Signals
	output	wire	[2:0]		PortSel_o,
	output	wire				PortNoSel_o
);

assign	PortNoSel_o	=	~Req0_i	&
						~Req1_i	&
						~Req2_i	&
						~Req3_i	&
						~Req4_i	;

assign	PortSel_o	=	Req0_i	?	3'h0	:	(
						Req1_i	?	3'h1	:	(
						Req2_i	?	3'h2	:	(
						Req3_i	?	3'h3	:	(
						Req4_i	?	3'h4	:	3'h0))));

endmodule
