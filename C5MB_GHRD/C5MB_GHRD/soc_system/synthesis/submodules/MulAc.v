module  MulAc (
    input   wire                    clk,
    input   wire                    rstn,

    input   wire                    First_i,
    input   wire                    Last_i,
    input   wire                    Valid_i,

    // input   wire    [1023:0]        Data_i,
    // input   wire    [1023:0]        Weight_i,
    input   wire    [511:0]        Data_i,
    input   wire    [511:0]        Weight_i,	

    input   wire    [2:0]           ConvSize_i,

    // output  wire    [15:0]          Conv8_o,
    // output  wire    [15:0]          Conv7_o,
    // output  wire    [15:0]          Conv6_o,
    // output  wire    [31:0]          Conv5_o,
    // output  wire    [63:0]          Conv4_o,
    // output  wire    [63:0]          Conv3_o,
    // output  wire    [255:0]         Conv2_o,
    // output  wire    [1023:0]        Conv1_o,
	
    output  wire    [31:0]          Conv8_o,
    output  wire    [31:0]          Conv7_o,
    output  wire    [31:0]          Conv6_o,
    output  wire    [63:0]         Conv5_o,
    output  wire    [127:0]         Conv4_o,
    output  wire    [127:0]         Conv3_o,
    output  wire    [511:0]        Conv2_o,
    output  wire    [2047:0]        Conv1_o,	
	
    output  wire                    First_o,
    output  wire                    Valid_o,
    output  wire                    Last_o,

    input   wire    [3:0]           DataBp_i,
    input   wire    [3:0]           WeightBp_i,
    input   wire    [3:0]           ResultBp_i,

    input   wire                    Halt_i     
);

genvar i;

//  Multipy 64*36  64*24 64*32
wire    [2047:0]    MultOut;

generate 
    for(i = 0;i < 64;i = i + 1) begin : Multipy
        Multiplier  #(
            .OPWIDTH                (8),
            .RSWIDTH                (32)
        )   Mult (
            .D0_i                   (Data_i[i*8+7:i*8]),
            .D1_i                   (Weight_i[i*8+7:i*8]),
            .Q_o                    (MultOut[i*32+31:i*32])
        );
    end
endgenerate

//  pipline0 64*36  64*24  64*32
wire    [2047:0]    P0Val;
wire                P0Valid,P0First,P0Last;

ConvDFF #(
    .WIDTH                          (2051),
    .PstVal                         (1'b0),
    .RstVal                         (1'b0)
)   P0 (
    .clk                            (clk),
    .rstn                           (rstn),
    .Set_i                          (1'b0),
    .Enable_i                       (~Halt_i),
    .D_i                            ({MultOut,Valid_i,First_i,Last_i}),
    .Q_o                            ({P0Val,P0Valid,P0First,P0Last})
);

//  Adder Stage0 32*36 32*24 32*32
wire    [1023:0]    AddOut0;

generate
    for(i = 0;i < 32;i = i + 1) begin : AddStg0
        Adder #(
            .WIDTH                  (32)
        )   AdderS0 (
            .D0_i                   (P0Val[i*64+63:i*64+32]),
            .D1_i                   (P0Val[i*64+31:i*64]),
            .Q_o                    (AddOut0[i*32+31:i*32])
        );
    end
endgenerate

//  Adder Stage1 16*36 16*24 16*32
wire    [511:0]     AddOut1;

generate
    for(i = 0;i < 16;i = i + 1) begin : AddStg1
        Adder #(
            .WIDTH                  (32)
        )   AdderS1 (
            .D0_i                   (AddOut0[i*64+63:i*64+32]),
            .D1_i                   (AddOut0[i*64+31:i*64]),
            .Q_o                    (AddOut1[i*32+31:i*32])
        );
    end
endgenerate

//  pipline1
wire    [511:0]     P1Val;
wire                P1Valid,P1First,P1Last;

ConvDFF #(
    .WIDTH                          (515),
    .PstVal                         (1'b0),
    .RstVal                         (1'b0)
)   P1 (
    .clk                            (clk),
    .rstn                           (rstn),
    .Set_i                          (1'b0),
    .Enable_i                       (~Halt_i),
    .D_i                            ({AddOut1,P0Valid,P0First,P0Last}),
    .Q_o                            ({P1Val,P1Valid,P1First,P1Last})
);

//  Adder Stage2 8*36 8*24 8*32
wire    [255:0]     AddOut2;

generate
    for(i = 0;i < 8;i = i + 1) begin : AddStg2
        Adder #(
            .WIDTH                  (32)
        )   AdderS2 (
            .D0_i                   (P1Val[i*64+63:i*64+32]),
            .D1_i                   (P1Val[i*64+31:i*64]),
            .Q_o                    (AddOut2[i*32+31:i*32])
        );
    end
endgenerate

//  Adder Stage3 4*36  4*24 4*32
wire    [127:0]     AddOut3;

generate
    for(i = 0;i < 4;i = i + 1) begin : AddStg3
        Adder #(
            .WIDTH                  (32)
        )   AdderS3 (
            .D0_i                   (AddOut2[i*64+63:i*64+32]),
            .D1_i                   (AddOut2[i*64+31:i*64]),
            .Q_o                    (AddOut3[i*32+31:i*32])
        );
    end
endgenerate

//  pipline2
wire    [127:0]     P2Val;
wire                P2Valid,P2First,P2Last;

ConvDFF #(
    .WIDTH                          (131),
    .PstVal                         (1'b0),
    .RstVal                         (1'b0)
)   P2 (
    .clk                            (clk),
    .rstn                           (rstn),
    .Set_i                          (1'b0),
    .Enable_i                       (~Halt_i),
    .D_i                            ({AddOut3,P1Valid,P1First,P1Last}),
    .Q_o                            ({P2Val,P2Valid,P2First,P2Last})
);

//  Adder Stage4 36*2  24*2 2*32
wire    [63:0]     AddOut4;

generate
    for(i = 0;i < 2;i = i + 1) begin : AddStg4
        Adder #(
            .WIDTH                  (32)
        )   AdderS4 (
            .D0_i                   (P2Val[i*64+63:i*64+32]),
            .D1_i                   (P2Val[i*64+31:i*64]),
            .Q_o                    (AddOut4[i*32+31:i*32])
        );
    end
endgenerate

//  Adder Stage5 36*1 24*1 32*1
wire    [31:0]      AddOut5;

Adder #(
    .WIDTH                  (32)
)   AdderS5 (
    .D0_i                   (AddOut4[63:32]),
    .D1_i                   (AddOut4[31:0]),
    .Q_o                    (AddOut5[31:0])
);

//  pipline3
wire    [31:0]      P3Val;
wire                P3Valid,P3First,P3Last;

ConvDFF #(
    .WIDTH                          (35),
    .PstVal                         (1'b0),
    .RstVal                         (1'b0)
)   P3 (
    .clk                            (clk),
    .rstn                           (rstn),
    .Set_i                          (1'b0),
    .Enable_i                       (~Halt_i),
    .D_i                            ({AddOut5,P2Valid,P2First,P2Last}),
    .Q_o                            ({P3Val,P3Valid,P3First,P3Last})
);

//  FLOW CONTROL
assign  {Valid_o,First_o,Last_o}    =   (ConvSize_i > 3'h4) ?   {P3Valid,P3First,P3Last}    :   (
                                        (ConvSize_i > 3'h1) ?   {P2Valid,P2First,P2Last}    :   (
                                        (ConvSize_i > 3'h0) ?   {P1Valid,P1First,P1Last}    :   {P0Valid,P0First,P0Last}));

wire    [4:0]   TempBp;
assign  TempBp  =   DataBp_i + WeightBp_i;

//  Align
// Align #(
    // .OPWIDTH                        (32)
// )   Conv8 (
    // .D_i                            (P3Val),
    // .OpBp_i                         (TempBp),
    // .RsBp_i                         (ResultBp_i),
    // .Q_o                            (Conv8_o)
// );
assign  Conv8_o =   P3Val;
assign  Conv7_o =   Conv8_o;
assign  Conv6_o =   Conv8_o;
assign  Conv5_o =   AddOut4;
assign  Conv4_o =   P2Val;
assign  Conv3_o =   Conv4_o;
assign  Conv2_o =   P1Val;
assign  Conv1_o =   P0Val;


// generate 
    // for(i = 0;i < 2;i = i + 1) begin : Conv5Align
        // Align #(
            // .OPWIDTH                        (32)
        // )   Conv5 (
            // .D_i                            (AddOut4[i*32+31:i*32]),
            // .OpBp_i                         (TempBp),
            // .RsBp_i                         (ResultBp_i),
            // .Q_o                            (Conv5_o[i*8+7:i*8])
        // );
    // end
// endgenerate

// generate 
    // for(i = 0;i < 4;i = i + 1) begin : Conv4Align
        // Align #(
            // .OPWIDTH                        (24)
        // )   Conv4 (
            // .D_i                            (P2Val[i*24+23:i*24]),
            // .OpBp_i                         (TempBp),
            // .RsBp_i                         (ResultBp_i),
            // .Q_o                            (Conv4_o[i*8+7:i*8])
        // );
    // end
// endgenerate



// generate 
    // for(i = 0;i < 16;i = i + 1) begin : Conv2Align
        // Align #(
            // .OPWIDTH                        (24)
        // )   Conv2 (
            // .D_i                            (P1Val[i*24+23:i*24]),
            // .OpBp_i                         (TempBp),
            // .RsBp_i                         (ResultBp_i),
            // .Q_o                            (Conv2_o[i*8+7:i*8])
        // );
    // end
// endgenerate

// generate 
    // for(i = 0;i < 64;i = i + 1) begin : Conv1Align
        // Align #(
            // .OPWIDTH                        (24)
        // )   Conv1 (
            // .D_i                            (P0Val[i*24+23:i*24]),
            // .OpBp_i                         (TempBp),
            // .RsBp_i                         (ResultBp_i),
            // .Q_o                            (Conv1_o[i*8+7:i*8])
        // );
    // end
// endgenerate


endmodule