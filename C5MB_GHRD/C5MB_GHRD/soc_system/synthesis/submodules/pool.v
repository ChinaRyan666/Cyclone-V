module  pool #(
    parameter                       ShareMemAddr    =   64'h0,
    parameter                       PrivateMemAddr0 =   64'h0,
    parameter                       PrivateMemAddr1 =   64'h0,
    parameter                       PrivateMemAddr2 =   64'h0,
    parameter                       PrivateMemAddr3 =   64'h0,	
    parameter                       RAM_WIDTH=512
)   (
    input   wire                    clk,
    input   wire                    rstn,
	//mem slect
    input   wire    [2:0]           select,
    //  Config Information
    input   wire    [3:0]           DataBp_i,
    input   wire    [3:0]           WeightBp_i,
    input   wire    [3:0]           ResultBp_i,
    input   wire    [8:0]           Height_i,
	input   wire                    Poolmod,	//0.max 1.ave

    //  HandShake With BusInterface
    input   wire                    Req_i,
    output  reg                     Ack_o,

    //  Bus
    output  reg    [63:0]           Addr_o,
    output  reg                     Read_o,
    output  reg                     Write_o,
    output  wire   [63:0]          ByteEnable_o,
    output  reg    [RAM_WIDTH-1:0]  WriteData_o,
    input   wire   [RAM_WIDTH-1:0]  ReadData_i,
    output  reg                     Lock_o,
    input   wire                    WaitReq_i

);

parameter DATA_WIDTH=RAM_WIDTH>>2;
 
parameter IDLE    =3'b000;  
parameter POOL_DEL=3'b001;
parameter MAX_POOL=3'b010;
parameter AVE_POOL=3'b011;
parameter WR_BUF  =3'b100;


reg[2:0]   state,last_state;
reg[2:0]   cnt_read;
reg[1:0]   cnt_write;
reg[8:0]   cnt_heigt;
wire[DATA_WIDTH-1:0] WriteData_o_tmp0,WriteData_o_tmp1,WriteData_o_tmp2,WriteData_o_tmp3;

reg[RAM_WIDTH-1:0]WriteData_max,WriteData_ave;

reg [63:0]write_addr_initial,read_addr_initial;

genvar  i;



assign  ByteEnable_o  =   {64{1'b1}};

always@(posedge clk or negedge rstn) 
    begin
        if (~rstn)
		  begin
		   state<=IDLE;
		   last_state<=IDLE;
		   Ack_o<=1'b0;
		   Lock_o<=1'b0;
		   Read_o<=1'b0;
		   cnt_heigt<=12'b0;
		   cnt_read<=3'b0;
		   cnt_write<=2'b0;
		   
		   Write_o<=1'b0;
		   WriteData_max<=0;
		   WriteData_ave<=0;
		   WriteData_o<=0;
		   write_addr_initial<=64'b0;
		   read_addr_initial<=64'b0;
		   Addr_o<=64'b0;
		  end 
		else 
		case(state)
	 IDLE: if(Req_i)
	      begin  
		   state<=POOL_DEL;
		   Ack_o<=1'b0;
		   last_state<=POOL_DEL;
		   Lock_o<=1'b1; 
		   cnt_heigt<=Height_i;
		   cnt_write<=2'b0;
		   Write_o<=1'b0;
		   case(select)
	  3'b000:	   
		  begin 
		   write_addr_initial<=ShareMemAddr;
		   read_addr_initial <=ShareMemAddr;
		  end 
	  3'b001:	   
		  begin 
		   write_addr_initial<=PrivateMemAddr0;
		   read_addr_initial <=PrivateMemAddr0;
		  end 
	  3'b010:	   
		  begin 
		   write_addr_initial<=PrivateMemAddr1;
		   read_addr_initial <=PrivateMemAddr1;
		  end 
	  3'b011:	   
		  begin 
		   write_addr_initial<=PrivateMemAddr2;
		   read_addr_initial <=PrivateMemAddr2;
		  end 	
	  3'b100:	   
		  begin 
		   write_addr_initial<=PrivateMemAddr3;
		   read_addr_initial <=PrivateMemAddr3;
		  end 
      default:
           ;
         endcase		   
		  end 
           else 
 	      begin  
		   state<=IDLE;
		   Lock_o<=1'b0; 
		   Ack_o<=1'b0;
		   Write_o<=1'b0;
		  end
     POOL_DEL: 
         if(Poolmod) 
          state<= AVE_POOL;
         else 
       	  state<=MAX_POOL;
     MAX_POOL:
	     begin
		 last_state<=MAX_POOL;
		 Write_o<=1'b0;
         case(cnt_read)
       3'b000: 
	     if(WaitReq_i==1'b1)
		     begin
		     Read_o<=1'b0;
		     cnt_read<=cnt_read;
		     end 
		 else  
		     begin		 
             Read_o<=1'b1;
		     cnt_read<=cnt_read+1;
			 Addr_o<=read_addr_initial;
			 read_addr_initial<=read_addr_initial+1;
		     end
       3'b001:
	     begin 
		     cnt_read<=cnt_read+1;
             Read_o<=1'b0;
			 cnt_heigt<=cnt_heigt-1;

		 end
       3'b010:
	     cnt_read<=cnt_read+1;
	   3'b011:
	     cnt_read<=cnt_read+1;
	   3'b100:	 
	    begin
		cnt_read<=3'b0;
	    state<=WR_BUF;	
        case(cnt_write)	
        2'b00:		
        WriteData_max[DATA_WIDTH*1-1:DATA_WIDTH*0]<=WriteData_o_tmp1;
        2'b01:		                           
        WriteData_max[DATA_WIDTH*2-1:DATA_WIDTH*1]<=WriteData_o_tmp1;
        2'b10:		                           
        WriteData_max[DATA_WIDTH*3-1:DATA_WIDTH*2]<=WriteData_o_tmp1;
        2'b11:		                           
        WriteData_max[DATA_WIDTH*4-1:DATA_WIDTH*3]<=WriteData_o_tmp1;
       default:
        ;	 
        endcase		
		// WriteData_max[DATA_WIDTH*1-1:0]<=WriteData_o_tmp1;
		// WriteData_max[DATA_WIDTH*2-1:DATA_WIDTH]<=WriteData_max[DATA_WIDTH-1:0];
		// WriteData_max[DATA_WIDTH*3-1:DATA_WIDTH*2]<=WriteData_max[DATA_WIDTH*2-1:DATA_WIDTH];
		// WriteData_max[DATA_WIDTH*4-1:DATA_WIDTH*3]<=WriteData_max[DATA_WIDTH*3-1:DATA_WIDTH*2];
		end
	   default:
        state<=IDLE;
        endcase
	   end 	
     AVE_POOL:
	     begin
		 last_state<=AVE_POOL;
		 Write_o<=1'b0;
         case(cnt_read)
       3'b000: 
	     if(WaitReq_i==1'b1)
		   begin
		   Read_o<=1'b0;
		   cnt_read<=cnt_read;
		   end
		 else  
           begin
		   Read_o<=1'b1;
		   cnt_read<=cnt_read+1;
		   Addr_o<=read_addr_initial;
		   read_addr_initial<=read_addr_initial+1;
		   end 
       3'b001:
	     begin 
         Read_o<=1'b0;
		 cnt_read<=cnt_read+1;
		 cnt_heigt<=cnt_heigt-1;
		 end 
       3'b010:
	     cnt_read<=cnt_read+1;
	   3'b011:
	     cnt_read<=cnt_read+1;
	   3'b100:	 
	    begin
		cnt_read<=3'b0;
	    state<=WR_BUF;
        case(cnt_write)	
        2'b00:		
        WriteData_ave[DATA_WIDTH*1-1:DATA_WIDTH*0]<=WriteData_o_tmp3;
        2'b01:		                           
        WriteData_ave[DATA_WIDTH*2-1:DATA_WIDTH*1]<=WriteData_o_tmp3;
        2'b10:		                           
        WriteData_ave[DATA_WIDTH*3-1:DATA_WIDTH*2]<=WriteData_o_tmp3;
        2'b11:		                           
        WriteData_ave[DATA_WIDTH*4-1:DATA_WIDTH*3]<=WriteData_o_tmp3;
       default:
        ;	
       endcase			
		// WriteData_ave[DATA_WIDTH*1-1:0]<=WriteData_o_tmp3;
		// WriteData_ave[DATA_WIDTH*2-1:DATA_WIDTH]<=WriteData_ave[DATA_WIDTH-1:0];
		// WriteData_ave[DATA_WIDTH*3-1:DATA_WIDTH*2]<=WriteData_ave[DATA_WIDTH*2-1:DATA_WIDTH];
		// WriteData_ave[DATA_WIDTH*4-1:DATA_WIDTH*3]<=WriteData_ave[DATA_WIDTH*3-1:DATA_WIDTH*2];
		cnt_read<=3'b0;
		end
	   default:
        state<=IDLE;
        endcase
        end		 
	     
	 WR_BUF:
	 if(WaitReq_i==1'b0) 
      begin	 
		cnt_write<=cnt_write+1;	
	    if (cnt_write==3)
		 begin
		   Write_o<=1'b1; 
		   Addr_o<=write_addr_initial;
		   write_addr_initial<=write_addr_initial+1;
		 end   
		else if (cnt_heigt==0)  
		 begin
		   Write_o<=1'b1;
		   Addr_o<=write_addr_initial;
		   write_addr_initial<=write_addr_initial+1;
		 end   
        else		   
         begin          
		  Write_o<=1'b0;
		   Addr_o<=Addr_o;
		   write_addr_initial<=write_addr_initial;
         end
		 
		 
        if (cnt_heigt==0)
		 begin
           state<=IDLE;	
		   Ack_o<=1'b1;
		 end  
		else if (last_state==MAX_POOL)
           state<=MAX_POOL;
        else if (last_state==AVE_POOL)
           state<=AVE_POOL;	
        else
           state<=IDLE;
      
	   
	       if (Poolmod==1'b0) 
		      WriteData_o<=WriteData_max;
		   else
		      WriteData_o<=WriteData_ave;
         end       		   
	 else 
        state <=WR_BUF; 	    
     default
         state<=IDLE;	
     endcase	
  end 	 
           		


generate 
    for(i = 0;i < (RAM_WIDTH>>5);i = i + 4) begin : maxdeal	
begin	
    Maxof4   #(
        .WIDTH(32)
   )   u_Maxof2_0(
       .clk (clk),
       .rstn(rstn),
       .D0_i(ReadData_i[32*(i+1)-1:32*i]),
       .D1_i(ReadData_i[32*(i+2)-1:32*(i+1)]),
       .D2_i(ReadData_i[32*(i+3)-1:32*(i+2)]),
       .D3_i(ReadData_i[32*(i+4)-1:32*(i+3)]),	
       .Q_o (WriteData_o_tmp0[32*((i>>2)+1)-1:32*(i>>2)])
   ); 

   
    // Align #(
        // .OPWIDTH(8)
   // )   u_Align_m0(
        // .D_i   (WriteData_o_tmp0[8*((i>>2)+1)-1:8*(i>>2)]),
        // .OpBp_i({1'b0,DataBp_i}),
        // .RsBp_i(ResultBp_i),
        // .Q_o   (WriteData_o_tmp1[8*((i>>2)+1)-1:8*(i>>2)])
   // );
    assign WriteData_o_tmp1=WriteData_o_tmp0;    
 end 
 end 
endgenerate 
 
/////deal average pool

generate 
    for(i = 0;i < (RAM_WIDTH>>5);i = i + 4) begin : avedeal	
  begin	   
     Adder_4in   #(
      .WIDTH(32)
  )   u_Adder_4in_av0(
      .clk (clk),
      .rstn(rstn),
      .D0_i(ReadData_i[32*(i+1)-1:32*i]),
      .D1_i(ReadData_i[32*(i+2)-1:32*(i+1)]),
      .D2_i(ReadData_i[32*(i+3)-1:32*(i+2)]),
      .D3_i(ReadData_i[32*(i+4)-1:32*(i+3)]),		
      .Q_o (WriteData_o_tmp2[32*((i>>2)+1)-1:32*(i>>2)])
  );
   
   
    // Align #(
        // .OPWIDTH(8)
   // )   u_Align_m1(
        // .D_i   (WriteData_o_tmp2[8*((i>>2)+1)-1:8*(i>>2)]),
        // .OpBp_i({1'b0,DataBp_i}),
        // .RsBp_i(ResultBp_i),
        // .Q_o   (WriteData_o_tmp3[8*((i>>2)+1)-1:8*(i>>2)])
   // );
    assign WriteData_o_tmp3=WriteData_o_tmp2;  
   end     
 end
endgenerate 


endmodule