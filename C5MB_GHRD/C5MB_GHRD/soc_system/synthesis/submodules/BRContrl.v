module    BRContrl(

    input    wire                   clk,
    input    wire                   rstn,

    input    wire    [8:0]          Height_i ,

    input    wire                   Req_i     ,

    input    wire                    Read_Done_i     ,
    input    wire                    BR_Done_i       ,
    input    wire                    Write_Done_i    ,

    output   wire                   pos_req_o     ,
    output   wire                   Rd_Start_o  ,
    output   wire                   BR_Start_o  ,
    output   wire                   Wr_Start_o  ,
                
    output   wire                   Ack_o

);

  

localparam IDLE=4'b0000, START=4'b0001, READ=4'b0010,    RB=4'b0011,   WRITE=4'b0100;

reg Req_chk1,Req_chk2;
always @(posedge clk or negedge rstn)   
begin
		if(~rstn) 
        begin
			Req_chk1 <= 1'b0;
			Req_chk2 <= 1'b1;
            
			end
		else 
        begin
			Req_chk1 <= Req_i;	
			Req_chk2 <= Req_chk1;	
            
		end
end

assign   pos_req_o =  Req_chk1 & ~Req_chk2;

        
reg [3:0]   state;
reg [15:0]  cnt;
reg Ack;
reg Rd_Start;
reg BR_Start;
reg Wr_Start;

always@(posedge clk or negedge rstn) 
begin
    if(~rstn)
    begin
        cnt         <= 16'd0;
        Rd_Start    <=  1'b0; 
        BR_Start    <=  1'b0;
        Wr_Start    <=  1'b0;
        Ack         <=  1'b0;
        state       <=  4'b0;
    end
    else   
    begin
    case(state)
        IDLE:   begin
                    if(pos_req_o)    
                        state   <= START;
                    else  
                    begin  
                        state   <= IDLE;
                        cnt         <= 16'd0    ;
                        Rd_Start    <=  1'b0    ;
                        BR_Start    <=  1'b0    ;
                        Wr_Start    <=  1'b0    ;
                        Ack         <=  1'b0    ;
                    end
                end
        START:  begin
                    if (cnt==Height_i)
                    begin
                        state   <= IDLE;
                        Ack     <=  1'b1;
                    end
                    else
                    begin
                        state   <= READ; 
                        Rd_Start    <=  1'b1;
                    end    
                end  
        READ:  begin
                    Rd_Start    <=  1'b0; 
                    if(Read_Done_i)
                    begin  
                        state   <= RB;
                        BR_Start    <= 1'b1;
                    end
                    else   
                        state       <= READ;
                           
                end
        RB:    begin
                    BR_Start    <= 1'b0;
                    if(BR_Done_i)
                    begin  
                        state   <= WRITE;
                        Wr_Start    <= 1'b1;
                    end
                    else   
                        state       <= RB;  

                end

        WRITE:  begin
                    Wr_Start    <= 1'b0;
                    if(Write_Done_i) 
                    begin 
                        cnt     <= cnt+16'd1;
                        state   <= START;
                    end
                    else   
                        state   <= WRITE;
                end  
        default:       state   <= IDLE;

    endcase
    end      
end
  
assign      Rd_Start_o  =     Rd_Start  ;
assign      BR_Start_o  =     BR_Start  ;
assign      Wr_Start_o  =     Wr_Start  ;
assign      Ack_o       =     Ack       ;
                            
                            


endmodule