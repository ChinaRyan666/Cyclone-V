module  BRWriteMaster #(
    parameter       BUSWIDTH            =      512 ,
    parameter       BYTEENABLEWIDTH      =      64  
   
)   (
    input   wire                                clk,
    input   wire                                rstn,


    input  wire    [63:0]                       WriteBackMemAddr,  
    //  From Top FSM                
    input   wire                                Start_i,
    input   wire                                pos_req_i,
    

    //  Read Only Master Side
    output  wire    [63:0]                      AvalonAddr_o,
    output  wire                                AvalonRead_o,
    output  wire                                AvalonWrite_o,
    output  wire    [BYTEENABLEWIDTH-1:0]       AvalonByteEnable_o,
    output  wire    [BUSWIDTH-1:0]             AvalonWriteData_o,
    input   wire    [BUSWIDTH-1:0]             AvalonReadData_i,
    output  wire                                AvalonLock_o,
    input   wire                                AvalonWaitReq_i,    


    //  in Data 
    
    input  wire    [BUSWIDTH-1:0]              Data_i,
    output wire                                 Write_Done_o


);

//  Weight Read State Reg
wire            WBState;

//  WeightAddrCounter
wire    [7:0]   WgtAddr;
wire    [7:0]   WgtAddrNxt;
wire            WgtDone;   
wire    [7:0]   StartdAddr;

assign  WgtAddrNxt  =   WgtAddr + 8'h1;
assign  WgtDone     =   (  (WgtAddr + 8'h1 -  StartdAddr )    ==  8'h1     )    ?   1'b1    :  1'b0 ;

//完成一次操作，
//  start_i     _________----_______________________________
//  WBState     _________————————————————————_______________
//  WgtDone     _____________________________----___________

ConvDFF #(
    .WIDTH          (8),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   SaveAddr (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (Start_i),
    .D_i            (WgtAddr),
    .Q_o            (StartdAddr)
);  

ConvDFF #(
    .WIDTH          (8),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   AddrCnt (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (pos_req_i),
    .Enable_i       (WBState & ~AvalonWaitReq_i),
    .D_i            (WgtAddrNxt),
    .Q_o            (WgtAddr)
);  


ConvDFF #(
    .WIDTH          (1),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   StateReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (WBState & WgtDone & ~AvalonWaitReq_i),
    .Enable_i       (Start_i),
    .D_i            (1'b1),
    .Q_o            (WBState)
);

wire            WBStateReg;
wire    [7:0]   WgtAddrReg;
wire            WgtDoneReg;
wire            WaitReg;

ConvDFF #(
    .WIDTH          (11),
    .RstVal         (1'b0),
    .PstVal         (1'b0)
)   CtrlReg (
    .clk            (clk),
    .rstn           (rstn),
    .Set_i          (1'b0),
    .Enable_i       (1'b1),
    .D_i            ({WgtAddr,WBState,WgtDone,AvalonWaitReq_i}),
    .Q_o            ({WgtAddrReg,WBStateReg,WgtDoneReg,WaitReg})
);




//  Avalon Side 
assign  AvalonAddr_o        =   ({64{WBState}} & (WgtAddr + WriteBackMemAddr))	;
                               
assign  AvalonRead_o        =   1'b0;
assign  AvalonWrite_o       =   WBState;
assign  AvalonByteEnable_o  =   {   BYTEENABLEWIDTH{1'b1}    } ;
assign  AvalonLock_o        =   WBState;

assign  AvalonWriteData_o   =   Data_i;

assign  Write_Done_o        =   WBStateReg & WgtDoneReg;        //写据完成，一个脉冲，作为下一步骤的触发信号



endmodule