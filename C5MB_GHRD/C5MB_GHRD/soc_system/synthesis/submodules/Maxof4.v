module  Maxof4 #(
    parameter                       WIDTH   =   16
)   (
    input   wire                    clk,
    input   wire                    rstn,
    input   wire  signed  [WIDTH-1:0]     D0_i,
    input   wire  signed  [WIDTH-1:0]     D1_i,
    input   wire  signed  [WIDTH-1:0]     D2_i,
    input   wire  signed  [WIDTH-1:0]     D3_i,	
    output  reg   signed  [WIDTH-1:0]     Q_o
);

//wire                S0,S1,S2,S3,S4,S5;
//wire    [WIDTH-2:0] Abs0,Abs1,Abs2,Abs3,Abs01,Abs23;
reg  signed   [WIDTH-1:0] D01,D23;  

//assign  S0      =   D0_i[WIDTH-1];
//assign  S1      =   D1_i[WIDTH-1];
//assign  S2      =   D2_i[WIDTH-1];
//assign  S3      =   D3_i[WIDTH-1];
//assign  S4      =   D01[WIDTH-1];
//assign  S5      =   D23[WIDTH-1];
//
//
//
//assign  Abs0    =   D0_i[WIDTH-2:0];
//assign  Abs1    =   D1_i[WIDTH-2:0];
//assign  Abs2    =   D2_i[WIDTH-2:0];
//assign  Abs3    =   D3_i[WIDTH-2:0];
//assign  Abs01    =  D01[WIDTH-2:0];
//assign  Abs23    =  D23[WIDTH-2:0];






always@(posedge clk or negedge rstn) 
    begin
        if (~rstn)
          D01<=0;
		  else if (D0_i>D1_i)
		    D01<=D0_i;
		  else
		    D01<=D1_i;
	 end	  	 
//        else if(S0==0)begin 
//          if(S1==1)
//            D01<=D0_i;
//			    else if (Abs0>Abs1)
//			      D01<=D0_i;
//			    else
//            D01<=D1_i;
//        end
//        else if(S1==0)
//          D01<=D1_i;
//        else if(Abs0 > Abs1)
//		      D01<=D1_i;
//		    else 
//          D01<=D0_i;
//    end  		  
                    		 
always@(posedge clk or negedge rstn) 
    begin
        if (~rstn)
          D23<=0;
		  else if(D2_i>D3_i)
		    D23<=D2_i;
		  else
		    D23<=D3_i;
	 end 	   	 
//        else if(S2==0)begin 
//          if(S3==1)
//            D23<=D2_i;
//			    else if (Abs2>Abs3)
//			      D23<=D2_i;
//			    else
//            D23<=D3_i;
//        end
//        else if(S3==0)
//          D23<=D3_i;
//        else if(Abs2 > Abs3)
//		      D23<=D3_i;
//		    else 
//          D23<=D2_i;
//    end  

always@(posedge clk or negedge rstn) 
    begin
        if (~rstn)
          Q_o<=0;
		  else if(D01>D23)
	    	 Q_o<=D01;
		  else
		    Q_o<=D23;
		  end	 
//        else if(S4==0)begin 
//          if(S5==1)
//            Q_o<=D01;
//			    else if (Abs01>Abs23)
//			      Q_o<=D01;
//			    else
//            Q_o<=D23;
//        end
//        else if(S5==0)
//          Q_o<=D23;
//        else if(Abs01 > Abs23)
//		      Q_o<=D23;
//		    else 
//          Q_o<=D01;
    //end  	
               			 
			   

endmodule