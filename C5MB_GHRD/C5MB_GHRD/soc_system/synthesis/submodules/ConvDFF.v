module  ConvDFF #(
    parameter   WIDTH   =   1,
    parameter   RstVal  =   1'b0,
    parameter   PstVal  =   1'b0
)   (
    input   wire                    clk,
    input   wire                    rstn,
    input   wire                    Set_i,
    input   wire                    Enable_i,
    input   wire    [WIDTH-1:0]     D_i,
    output  wire    [WIDTH-1:0]     Q_o
);

reg     [WIDTH-1:0] Register;

always@(posedge clk or negedge rstn) begin
    if(~rstn) 
        Register    <=  {WIDTH{RstVal}};
    else if(Set_i)
        Register    <=  {WIDTH{PstVal}};
    else if(Enable_i)
        Register    <=  D_i;
end

assign  Q_o =   Register;

endmodule