module IFBuffer(
    input   wire                clk,
    input   wire                rstn,

    //  From Shared BUS
    input   wire                ShareValid_i,
    // input   wire    [1023:0]    ShareLine_i,
    input   wire    [511:0]    ShareLine_i,	
    input   wire                ShareFirst_i,
    input   wire                ShareLast_i,

    //  To MAC
    output  wire                Valid_o,
    // output  wire    [1023:0]    Data_o,
    output  wire    [511:0]    Data_o,	
    output  wire                First_o,
    output  wire                Last_o,

    //  PIPE HALT   
    input   wire                Halt_i
);

// wire    [1023:0]    BufferLine;
wire    [511:0]    BufferLine;
wire                Valid;
wire                First;
wire                Last;

assign  BufferLine  =   ShareLine_i ;
assign  First       =   ShareFirst_i;
assign  Valid       =   ShareValid_i;        
assign  Last        =   ShareLast_i ;

    
ConvDFF #(
    .WIDTH              (512),
    .RstVal             (1'b0),
    .PstVal             (1'b0)
) BufferLineReg (
    .clk                (clk),    
    .rstn               (rstn),    
    .Set_i              (1'b0),   
    .Enable_i           (Valid & ~Halt_i),   
    .D_i                (BufferLine),   
    .Q_o                (Data_o)
);


ConvDFF #(
    .WIDTH              (3),
    .RstVal             (1'b0),
    .PstVal             (1'b0)
) PipFirst (
    .clk                (clk),    
    .rstn               (rstn),    
    .Set_i              (1'b0),   
    .Enable_i           (~Halt_i),   
    .D_i                ({Valid,First,Last}),   
    .Q_o                ({Valid_o,First_o,Last_o})
);


endmodule