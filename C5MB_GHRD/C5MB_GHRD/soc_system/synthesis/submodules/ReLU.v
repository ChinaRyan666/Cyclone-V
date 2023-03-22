module ReLU #(
    parameter    WIDTH   =   8

)   (
    input  wire  signed   [WIDTH-1:0]           Data_i,
    input  wire                           ReLUMod_i,
    input  wire     [3:0]                 Data_Bp_i,
    input  wire     [3:0]                 Result_Bp_i,
    output  wire   signed [WIDTH-1:0]           Q_o

);


wire                S0;      
assign  S0      =   Data_i[WIDTH-1];         //Data_i的符号位    


//wire    [WIDTH-2:0]     Abs0;   
//assign  Abs0    =   Data_i[WIDTH-2:0] >> Data_Bp_i;       //Data_i的整数部分

wire    [WIDTH-1:0]     RelU_normal;
assign  RelU_normal   =   (S0 == 1'b0)     ?   Data_i[WIDTH-1:0] :  32'd0;


wire   [WIDTH-1:0]  RelU_o;

assign    RelU_o   =    ( ReLUMod_i == 1'b0 )    ?    RelU_normal   :    (
                        ( S0 == 1'b1        )    ?    32'd0         :  Data_i[WIDTH-1:0]   )  ; 

//assign    RelU_o   =    ( ReLUMod_i == 1'b0 )    ?    RelU_normal   :    (
//                        ( S0 == 1'b1        )    ?    32'd0         :    (
//                        ( Abs0 >=3'h6       )    ?    32'd6         :   Data_i[WIDTH-1:0]  
//                                                                                             ) )  ; 

// 输入小数点位置       0 和 6 小数点位置等于0                                                                             
//wire    [3:0]OpBp_i;   

//assign     OpBp_i      =  (    (RelU_o==32'd0 ) || (RelU_o==32'd6 )    )    ?   4'b0 : Data_Bp_i   ;

//小数点对齐
// Align #(
   // .OPWIDTH						(8)
// )  Align_ReLU (
    // .D_i                    (RelU_o),
    // .OpBp_i                 ({1'b0,OpBp_i}),
    // .RsBp_i                 (Result_Bp_i),
    // .Q_o                    (Q_o)   
// );
assign Q_o=RelU_o;

endmodule
 