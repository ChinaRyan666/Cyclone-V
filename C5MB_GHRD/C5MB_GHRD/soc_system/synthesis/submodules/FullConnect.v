module  FullConnect #(
    parameter                       WeightMemAddr   =   64'h0,
    parameter                       ShareMemAddr    =   64'h0,
    parameter                       PrivateMemAddr0 =   64'h0,
    parameter                       PrivateMemAddr1 =   64'h0,
    parameter                       PrivateMemAddr2 =   64'h0,
    parameter                       PrivateMemAddr3 =   64'h0,
    
    parameter                       DataBp_WIDTH        =   4,
    parameter                       WeightBp_WIDTH      =   4,
    parameter                       ResultBp_WIDTH      =   4,
    parameter                       Height_WIDTH        =   9,
    parameter                       AvalonByteEnable_WIDTH        =   64,
    parameter                       AvalonData_WIDTH        =   512
    
)   (
    input   wire                    clk,
    input   wire                    rstn,
    input   wire [2:0]              addr_sel,

    //  Config Information
    input   wire                                   Accu_i,
    input   wire    [DataBp_WIDTH-1:0]           DataBp_i,
    input   wire    [WeightBp_WIDTH-1:0]           WeightBp_i,
    input   wire    [ResultBp_WIDTH-1:0]           ResultBp_i,
    input   wire    [Height_WIDTH  -1:0]           Height_i,
    input   wire                    CoreEnable_i,

    //  HandShake With BusInterface
    input   wire                    Req_i,                      
    output  wire                    Ack_o,                     

    //  Avalon-MM Master
    output  wire    [63:0]      AvalonAddr_o,
    output  wire                AvalonRead_o,
    output  wire                AvalonWrite_o,
    output  wire    [AvalonByteEnable_WIDTH-1:0]    AvalonByteEnable_o,
    output  wire    [AvalonData_WIDTH-1:0]          AvalonWriteData_o,
    input   wire    [AvalonData_WIDTH-1:0]          AvalonReadData_i,    
    output  wire                AvalonLock_o,
    input   wire                AvalonWaitReq_i
   
);
reg[63:0] DataMemAddr;
wire[63:0] WriteBackMemAddr;
always @(*)
begin
    case (addr_sel)
       3'b000   : DataMemAddr <= ShareMemAddr;
       3'b001   : DataMemAddr <= PrivateMemAddr0;
       3'b010   : DataMemAddr <= PrivateMemAddr1;
       3'b011   : DataMemAddr <= PrivateMemAddr2;
       3'b100   : DataMemAddr <= PrivateMemAddr3;
       default : DataMemAddr <= ShareMemAddr;
    endcase
end         
assign WriteBackMemAddr = DataMemAddr;         
         
//  TOP FSM
wire    CoreState;
wire    CoreDone;

FullConnectDFF #(
    .WIDTH              (1),
    .RstVal             (1'b0),
    .PstVal             (1'b0)
) CS (           
    .clk                (clk),    
    .rstn               (rstn),                         
    .Set_i              (CoreState & CoreDone),         
    .Enable_i           (Req_i & CoreEnable_i),         
    .D_i                (1'b1),   
    .Q_o                (CoreState)
);


wire    CoreStateReg;

FullConnectDFF #(
    .WIDTH              (1),
    .RstVal             (1'b0),
    .PstVal             (1'b0)
) CSR (           
    .clk                (clk),    
    .rstn               (rstn),    
    .Set_i              (1'b0),   
    .Enable_i           (1'b1),   
    .D_i                (CoreState),   
    .Q_o                (CoreStateReg)
);

assign  Ack_o   =   CoreStateReg & ~CoreState;  

//  Config Information Reg

wire                Accu;
wire    [DataBp_WIDTH-1:0]         DataBp;
wire    [WeightBp_WIDTH-1:0]       WeightBp;
wire    [ResultBp_WIDTH-1:0]       ResultBp;
wire    [Height_WIDTH  -1:0]       Height;  

FullConnectDFF #(
    .WIDTH                      (1 + DataBp_WIDTH + WeightBp_WIDTH + ResultBp_WIDTH + Height_WIDTH),                           
    .RstVal                     (1'b1),                      
    .PstVal                     (1'b0)                       
) CFG (                                                      
    .clk                        (clk),    
    .rstn                       (rstn),    
    .Set_i                      (1'b0),   
    .Enable_i                   (Req_i),   
    .D_i                        ({Accu_i,DataBp_i,WeightBp_i,ResultBp_i,Height_i}),   
    .Q_o                        ({Accu,DataBp,WeightBp,ResultBp,Height})  
);

wire                Start;

FullConnectDFF #(
    .WIDTH                      (1),
    .RstVal                     (1'b0),
    .PstVal                     (1'b0)
) RG (           
    .clk                        (clk),    
    .rstn                       (rstn),    
    .Set_i                      (1'b0),   
    .Enable_i                   (1'b1),   
    .D_i                        (Req_i),   
    .Q_o                        (Start)     
);

//  Share Read Master
wire                ShareValid;
wire    [7:0]       ShareEnable;
wire    [127:0]     ShareLine;
wire                ShareFirst;
wire                ShareLast;
wire    [7:0]       WBEnable;
wire    [3:0]       WBCoreSel;
wire    [127:0]     WBLine;

wire    [3:0]       Halt;

wire                WBReady;


//  FullConnectCore 
FullConnectCore    #(
    .WeightMemAddr                (WeightMemAddr   ),
    
    .AvalonByteEnable_WIDTH             (AvalonByteEnable_WIDTH),
    .AvalonData_WIDTH                   (AvalonData_WIDTH      )
)   inst_FullConnectCore (
    .clk                        (clk),
    .rstn                       (rstn),
    .DataMemAddr                  (DataMemAddr     ),
    .WriteBackMemAddr             (WriteBackMemAddr),
    .Accu_i                     (Accu),
    .DataBp_i                   (DataBp),
    .WeightBp_i                 (WeightBp),
    .ResultBp_i                 (ResultBp),
    .Height_i                   (Height),
    .Start_i                    (Start),
    .Done_o                     (CoreDone),
    .AvalonAddr_o               (AvalonAddr_o),
    .AvalonRead_o               (AvalonRead_o),
    .AvalonWrite_o              (AvalonWrite_o),
    .AvalonByteEnable_o         (AvalonByteEnable_o),
    .AvalonWriteData_o          (AvalonWriteData_o),
    .AvalonReadData_i           (AvalonReadData_i),
    .AvalonLock_o               (AvalonLock_o),
    .AvalonWaitReq_i            (AvalonWaitReq_i),
    .Halt_o                     ()
);


endmodule