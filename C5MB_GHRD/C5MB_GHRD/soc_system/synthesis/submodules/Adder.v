module  Adder #(
    parameter                       WIDTH   =   32
)   (
    input    wire signed  [WIDTH-1:0]     D0_i,
    input    wire signed   [WIDTH-1:0]     D1_i,
    output   wire signed    [WIDTH-1:0]     Q_o
);

// wire                S0,S1;

// assign  S0      =   D0_i[WIDTH-1];
// assign  S1      =   D1_i[WIDTH-1];

// wire    [WIDTH-2:0] Abs0,Abs1;

// assign  Abs0    =   D0_i[WIDTH-2:0];
// assign  Abs1    =   D1_i[WIDTH-2:0];

// wire                Big0,NeS;

// assign  NeS     =   S0 ^ S1;
// assign  Big0    =   Abs0 > Abs1;

// wire    [WIDTH-2:0] AbsResult;

// assign  AbsResult   =   ~NeS    ?   Abs0 + Abs1 :   (
                        // Big0    ?   Abs0 - Abs1 :   Abs1 - Abs0);

// wire    SResult;

// assign  SResult =   ~NeS    ?   S0  :   (
                    // Big0    ?   S0  :   S1);

// assign  Q_o =   {SResult,AbsResult};

assign  Q_o =D0_i+D1_i;

endmodule