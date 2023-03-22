module WgtBuffer(
    input   wire                clk,
    input   wire                rstn,


    //  From Share Master
    // input   wire    [1023:0]    ShareMstLine_i,
    input   wire    [511:0]    ShareMstLine_i,	
    input   wire                ShareMstValid_i,

    //  To MAC
    // output  wire    [1023:0]    Weight0_o
    output  wire    [511:0]    Weight0_o	

);


ConvDFF #(
    .WIDTH              (512),
    .RstVal             (1'b0),
    .PstVal             (1'b0)
) Core0Buffer (
    .clk                (clk),    
    .rstn               (rstn),    
    .Set_i              (1'b0),   
    .Enable_i           (ShareMstValid_i),   
    .D_i                (ShareMstLine_i),   
    .Q_o                (Weight0_o)
);


endmodule