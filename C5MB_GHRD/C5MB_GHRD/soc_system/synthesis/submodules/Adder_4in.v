module  Adder_4in #(
    parameter                       WIDTH   =   8
)   (
    input   wire                    clk,
    input   wire                    rstn,
    input   wire  signed  [WIDTH-1:0]     D0_i,
    input   wire  signed  [WIDTH-1:0]     D1_i,
    input   wire  signed  [WIDTH-1:0]     D2_i,
    input   wire  signed  [WIDTH-1:0]     D3_i,	
    output  reg   signed  [WIDTH-1:0]     Q_o
);

// wire                S0,S1,S2,S3,S4,S5;
// wire   [WIDTH-1:0]     Q_01;
// wire   [WIDTH-1:0]     Q_23;

// wire    [WIDTH-2:0] Abs0,Abs1,Abs2,Abs3,Abs4,Abs5,Abs01,Abs23;
// wire                Big01,NeS01,Big23,NeS23,Big0_3,NeS0_3;

// reg    [WIDTH-2:0] AbsResult01;
// reg    [WIDTH-2:0] AbsResult23;
// reg    [WIDTH-2:0] AbsResult0_3;
// reg    SResult01;
// reg    SResult23;
// reg    SResult0_3;


// assign  Abs0    =   D0_i[WIDTH-2:0];
// assign  Abs1    =   D1_i[WIDTH-2:0];
// assign  Abs2    =   D2_i[WIDTH-2:0];
// assign  Abs3    =   D3_i[WIDTH-2:0];
// assign  Abs4    =   Q_01[WIDTH-2:0];
// assign  Abs5    =   Q_23[WIDTH-2:0];


// assign  Big01    =   Abs0 > Abs1;
// assign  Big23    =   Abs2 > Abs3;
// assign  Big0_3    =  Abs01 > Abs23;

// assign  S0      =   D0_i[WIDTH-1];
// assign  S1      =   D1_i[WIDTH-1];
// assign  S2      =   D2_i[WIDTH-1];
// assign  S3      =   D3_i[WIDTH-1];
// assign  S4      =   Q_01[WIDTH-1];
// assign  S5      =   Q_23[WIDTH-1];
reg     [WIDTH-1:0]     Q_o_temp;

always@(posedge clk or negedge rstn) 
    begin
        if (~rstn)
		 begin
          Q_o_temp<=0;
		  Q_o<=0;
		 end 
		 else
         begin	
          Q_o_temp<=D0_i+D1_i+D2_i+D3_i;
		  Q_o<=Q_o_temp;	
         end		  
    end 
// always@(posedge clk or negedge rstn) 
    // begin
        // if (~rstn)
		 // begin
          // AbsResult01<=0;
		  // SResult01<=0;
		 // end
		// else if (S0==S1)
		 // begin 
		  // AbsResult01<=Abs0+Abs1;
		  // SResult01<=S0;
		 // end 
		// else if(Big01)
		 // begin
          // AbsResult01<=Abs0 - Abs1;
		  // SResult01<=S0;
		 // end 
        // else
		 // begin
		  // AbsResult01<=Abs1 - Abs0;
		  // SResult01<=S1;
		 // end 
    // end 
	
// assign  Q_01 =   {SResult01,AbsResult01}; 

// always@(posedge clk or negedge rstn) 
    // begin
        // if (~rstn)
		 // begin
          // AbsResult23<=0;
		  // SResult23<=0;
		 // end 
		// else if (S2==S3)
		 // begin
		  // AbsResult23<=Abs2+Abs3;
		  // SResult23<=S2;
		 // end
		// else if(Big23)
		 // begin
          // AbsResult23<=Abs2 - Abs3;
		  // SResult23<=S2;
		 // end 
        // else
		 // begin
		  // AbsResult23<=Abs3 - Abs2;
		  // SResult23<=S3;
		 // end
    // end 
	
// assign  Q_23 =   {SResult23,AbsResult23}; 

// always@(posedge clk or negedge rstn) 
    // begin
        // if (~rstn)
		 // begin
          // AbsResult0_3<=0;
		  // SResult0_3<=0;
		 // end 
		// else if (S4==S5)
		 // begin
		  // AbsResult0_3<=Abs4+Abs5;
		  // SResult0_3<=S4;
		 // end  
		// else if(Big0_3)
		 // begin
          // AbsResult0_3<=Abs4 - Abs5;
		  // SResult0_3<=S4;
		 // end 
        // else
		 // begin
		  // AbsResult0_3<=Abs5 - Abs4;
		  // SResult0_3<=S5;
		 // end 
    // end 
	
// assign  Q_o =   {SResult0_3,AbsResult0_3>>2}; 
 		
endmodule
