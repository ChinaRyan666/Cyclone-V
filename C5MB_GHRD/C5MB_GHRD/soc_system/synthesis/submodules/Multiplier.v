module  Multiplier  #(
    parameter                       OPWIDTH =   8,
    parameter                       RSWIDTH =   32
)   (
    input    wire  signed  [OPWIDTH-1:0]   D0_i,
    input    wire  signed   [OPWIDTH-1:0]   D1_i,
    output  wire   signed  [RSWIDTH-1:0]   Q_o  
);


wire  [OPWIDTH*2-1:0]         Q_o_TEMP1;  
wire  [RSWIDTH-OPWIDTH*2-1:0] Q_o_TEMP2; 


assign Q_o_TEMP2= (Q_o_TEMP1[OPWIDTH*2-1])?(~0):0;

assign  Q_o_TEMP1=D0_i*D1_i;
assign  Q_o={Q_o_TEMP2,Q_o_TEMP1};
// wire    S0,S1;
//
// assign  S0      =   D0_i[OPWIDTH-1];
// assign  S1      =   D1_i[OPWIDTH-1];
//
// wire    [OPWIDTH-2:0]   Abs0,Abs1;
//
// assign  Abs0    =   D0_i[OPWIDTH-2:0];
// assign  Abs1    =   D1_i[OPWIDTH-2:0];
//
// wire    [RSWIDTH-2:0]   AbsResult;
//
// assign  AbsResult   =   Abs0 * Abs1;
//
// wire    SResult;
//
// assign  SResult =   (S0  ^   S1) & (|AbsResult);
//
// assign  Q_o =   {SResult,AbsResult};

endmodule

