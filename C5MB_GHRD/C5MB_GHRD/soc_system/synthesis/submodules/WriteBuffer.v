module  WriteBuffer (

    //  General Signals
    input   wire                clk,
    input   wire                rstn,

    //  From Piplined MAC
    input   wire                First_i, //当次读写的第一个值
    input   wire                Valid_i,//
    output  wire                Halt_o,//计算完毕，告诉mac以及前面步骤当前时刻不计算
    input   wire                Last_i,//当次读写的最后一个值
    input   wire    [31:0]      Conv8_i,
    input   wire    [31:0]      Conv7_i,
    input   wire    [31:0]      Conv6_i,
    input   wire    [63:0]      Conv5_i,
    input   wire    [127:0]     Conv4_i,
    input   wire    [127:0]     Conv3_i,
    input   wire    [511:0]     Conv2_i,
    input   wire    [2047:0]    Conv1_i,

    //  Config Imformation
    input   wire    [2:0]       ConvSize_i,//当前卷积窗大小

    //  To WriteMaster
    output  wire    [511:0]    WriteBuffer_o,
    output  wire                WriteReq_o,
    input   wire                WriteAck_i,
    output  wire                First_o,
    output  wire                Last_o

);

genvar i;

//  ConvSize Decode
wire    [7:0]   ConvEnable;

generate
    for(i = 0;i < 8;i = i + 1) begin : ConvDecode
        assign  ConvEnable[i]   =   ConvSize_i  ==  i;
    end
endgenerate

wire    [5:0]   AlignCounter;
wire    [5:0]   AlignCounterNxt;
wire    [5:0]   AlignCounterDst;
wire            AlignCounterEn;

wire            Cnt64;
wire            Cnt32;
wire            Cnt16;
wire            Cnt4;
wire            Cnt1;

assign  Cnt64   =   ConvEnable[7] | ConvEnable[6] | ConvEnable[5];
assign  Cnt32   =   ConvEnable[4];
assign  Cnt16   =   ConvEnable[3] | ConvEnable[2];
assign  Cnt4    =   ConvEnable[1];
assign  Cnt1    =   ConvEnable[0];
//指示来自哪一级mac输出
assign  AlignCounterDst =   ({6{Cnt64}} &   6'hf)   |        //64
                            ({6{Cnt32}} &   6'h7)   |        //32
                            ({6{Cnt16}} &   6'h3) ;//   |        //16
                            //({6{Cnt4}}  &   6'h3)    ;        //4
//根据卷积窗指示选择计数值

wire            CountDone;

assign  CountDone   =   AlignCounter == AlignCounterDst;//传输计数等于预定值，传输结束

assign  AlignCounterNxt =   First_i     ?   6'h1    :   (
                            CountDone   ?   6'h0    :   AlignCounter + 6'h1);
//传输计数如果first指示置为1，没结束等于计数器值，计数完毕等于0
assign  AlignCounterEn  =   ~Halt_o &   Valid_i; //有效且不暂停
wire   [511:0] Conv1_i_Del;
reg   [2047:0] Conv1_i_Temp;

always@(posedge clk or negedge rstn )
begin 
      Conv1_i_Temp      <=Conv1_i;
	   Conv1_i_Temp[1535:1024]<= Conv1_i_Temp[2047:1536];	
       Conv1_i_Temp[1023:512] <= Conv1_i_Temp[1535:1024];	 
       Conv1_i_Temp[511:0]    <= Conv1_i_Temp[1023:512];
end 

reg Last_i_D1,Last_i_D2,Last_i_D3,Last_i_Del;


assign 	Conv1_i_Del=Conv1_i[511:0];

ConvDFF #(
    .WIDTH              (6),
    .RstVal             (1'b0),
    .PstVal             (1'b0)
)   AlignCnt (
    .clk                (clk),
    .rstn               (rstn),
    .Set_i              (1'b0),
    .Enable_i           (AlignCounterEn),
    .D_i                (AlignCounterNxt),
    .Q_o                (AlignCounter)
);
//计数器累加，在允许累加的情况下

wire    [63:0]  Sel64;
wire    [31:0]  Sel32;
wire    [15:0]  Sel16;
wire    [3:0]   Sel4;
wire            Sel1;

wire    [63:0] CounterDec64;
wire    [31:0] CounterDec32;
wire    [15:0] CounterDec16;
wire    [3:0]  CounterDec4;

generate
    for(i = 0;i < 16;i = i + 1) begin : cntdec64
        assign  CounterDec64[i]   =   AlignCounter  ==  i;
    end
endgenerate

generate
    for(i = 0;i < 8;i = i + 1) begin : cntdec32
        assign  CounterDec32[i]   =   AlignCounter  ==  i;
    end
endgenerate

generate
    for(i = 0;i < 4;i = i + 1) begin : cntdec16
        assign  CounterDec16[i]   =   AlignCounter  ==  i;
    end
endgenerate

// generate
    // for(i = 0;i < 4;i = i + 1) begin : cntdec4
        // assign  CounterDec4[i]   =   AlignCounter  ==  i;
    // end
// endgenerate

assign  Sel64   =   {64{~Halt_o & Cnt64 & Valid_i}}  &   (First_i    ?   64'h1 :   CounterDec64);
assign  Sel32   =   {32{~Halt_o & Cnt32 & Valid_i}}  &   (First_i    ?   32'h1 :   CounterDec32);
assign  Sel16   =   {16{~Halt_o & Cnt16 & Valid_i}}  &   (First_i    ?   16'h1 :   CounterDec16);
// assign  Sel4    =   {4{~Halt_o  & Cnt4  & Valid_i}}  &   (First_i    ?   4'h1  :   CounterDec4);
assign  Sel4    =   ~Halt_o     & Cnt4  & Valid_i;
assign  Sel1    =   ~Halt_o     & Cnt1  & Valid_i;


//  WRITEBUFFER  
wire    [511:0]    ByteLine; 
wire    [63:0]      SelLine;

generate 
    for(i = 0;i < 16;i = i + 1) begin : outputline

        assign  ByteLine[i*32+31:i*32]        =    ({32{ConvEnable[7]}}    &   Conv8_i)                            |    
                                                   ({32{ConvEnable[6]}}    &   Conv7_i)                            |    
                                                   ({32{ConvEnable[5]}}    &   Conv6_i)                            |    
                                                   ({32{ConvEnable[4]}}    &   Conv5_i[(i%2)*32+31 :(i%2)*32])     |    
                                                   ({32{ConvEnable[3]}}    &   Conv4_i[(i%4)*32+31 :(i%4)*32])     |    
                                                   ({32{ConvEnable[2]}}    &   Conv3_i[(i%4)*32+31 :(i%4)*32])     |    
                                                   ({32{ConvEnable[1]}}    &   Conv2_i[i*32+31:i*32]  )              |    
                                                   ({32{ConvEnable[0]}}    &   Conv1_i_Del[i*32+31:i*32]);       

        assign  SelLine[i]  =   Sel64[i]    |
                                Sel32[i/2]  |
                                Sel16[i/4]  |
                                Sel4        |//Sel4[i/16]  |
                                Sel1        ;
          //功能类似byteeable                      
        ConvDFF #(
            .WIDTH              (32),
            .RstVal             (1'b0),
            .PstVal             (1'b0)
        )   WriteBufferLine0 (
            .clk                (clk),
            .rstn               (rstn),
            .Set_i              (1'b0),
            .Enable_i           (SelLine[i]),
            .D_i                (ByteLine[i*32+31:i*32]),
            .Q_o                (WriteBuffer_o[i*32+31:i*32])
        );

    end
endgenerate


//  WRITEBUFFER TAG
wire                    BufferWrite;

assign  BufferWrite     =   ((CountDone | Last_i)   | ConvEnable[0])   &   Valid_i &   ~Halt_o;
//计数完成写出一个数
ConvDFF #(
    .WIDTH      (1),
    .RstVal     (1'b0),
    .PstVal     (1'b0)
)   WriteBufferTag (
    .clk        (clk),
    .rstn       (rstn),
    .Set_i      (WriteAck_i & WriteReq_o),
    .Enable_i   (BufferWrite),
    .D_i        (1'b1),
    .Q_o        (WriteReq_o)
);

assign  Halt_o  =   WriteReq_o   &   Valid_i;

//  First Reg
wire    First;

ConvDFF #(
    .WIDTH      (1),
    .RstVal     (1'b0),
    .PstVal     (1'b0)
)   FirstReg (
    .clk        (clk),
    .rstn       (rstn),
    .Set_i      (WriteReq_o),
    .Enable_i   (First_i),
    .D_i        (~Halt_o),
    .Q_o        (First)
);

assign  First_o   =   First & WriteReq_o;

//  Last Reg
wire    Last;

ConvDFF #(
    .WIDTH      (1),
    .RstVal     (1'b0),
    .PstVal     (1'b0)
)   LastReg (
    .clk        (clk),
    .rstn       (rstn),
    .Set_i      (Last_o),
    .Enable_i   (~Halt_o),
    .D_i        (Last_i),
    .Q_o        (Last)
);

assign  Last_o  =   Last & WriteReq_o;

endmodule