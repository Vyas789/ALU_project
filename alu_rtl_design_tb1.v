`timescale 1ns / 1ps
`define PASS 1'b1
`define FAIL 1'b0
`include "alu_rtl_design.v"
`define no_of_testcases 8 
`define MUL_I
`define MUL_S

module alu_rtl_design_tb();
    parameter N1 = 8,
              N2 = 4,
              N3 = 16;
    parameter packet_width = (19+N2+2*N1+N3);
    parameter response_width = (packet_width+N3+6);
    parameter scb_width = (1+8+N3+6+N3+6+1+1);
    reg [packet_width-1:0] curr_test_case = {packet_width{1'b0}};
	reg [packet_width-1:0] stimulus_mem [0:`no_of_testcases-1];
	reg [response_width:0] response_packet;
	   
	
	integer i,j;
	reg CLK,RST,CE; 
	event fetch_stimulus; 
	reg [N1-1:0]OPA,OPB; 
	reg [N2-1:0]CMD;
    reg MODE,CIN;
    reg [1:0] IN_VALID;
	reg [7:0] Feature_ID;
	reg e,g,l;  
	reg [N1:0] Expected_RES;
	reg [N1-2:0] Reserved_RES; 
	reg err,cout,ov;
   
    
    
	wire  [N3-1:0] RES;
	wire ERR,OFLOW,COUT;
	wire E,G,L;
    reg [N3+6:0] expected_data;
    reg [N3+6:0]exact_data;

    
	task read_stimulus();	
	   	begin 
	    	#10 $readmemb ("stimulus.txt",stimulus_mem);
        end
        endtask 
     alu_rtl_design dut (.OPA(OPA),.OPB(OPB),.CIN(CIN),.CLK(CLK),.RST(RST),.CMD(CMD),.CE(CE),.MODE(MODE),.IN_VALID(IN_VALID),.RES(RES),.OFLOW(OFLOW),.COUT(COUT),.G(G),.E(E),.L(L),.ERR(ERR));
   
   
    integer stim_mem_ptr = 0,scb_ptr = 0,fid =0 , pointer =0 ;
	always@(fetch_stimulus)
		begin
			curr_test_case=stimulus_mem[stim_mem_ptr];
			$display ("\n stimulus_mem data = %0b",stimulus_mem[stim_mem_ptr]);
			$display ("packet data = %0b \n",curr_test_case);			
			stim_mem_ptr=stim_mem_ptr+1;
		end
    
    initial 
		begin CLK=0;
			forever #60 CLK=~CLK;
		end
		
    
	task driver ();
		begin
          ->fetch_stimulus;
		  @(posedge CLK);
		     begin
             Feature_ID=curr_test_case[(packet_width-1)-:8];
             IN_VALID=curr_test_case[(packet_width-9)-:2];
		     OPA=curr_test_case[(packet_width-11)-:N1];
	         OPB=curr_test_case[(packet_width-11-N1)-:N1];
		     CMD=curr_test_case[(packet_width-11-2*N1)-:N2];
             CIN=curr_test_case[packet_width-11-N2-2*N1];
             CE=curr_test_case[packet_width-12-N2-2*N1];
		     MODE=curr_test_case[packet_width-13-N2-2*N1];
		     Reserved_RES=curr_test_case[(packet_width-14-N2-2*N1)-:N1-1];
             Expected_RES=curr_test_case[(packet_width-14-N2-2*N1-N1+1)-:N1+1];
             cout=curr_test_case[(packet_width-14-N2-2*N1-N3)];	
             g=curr_test_case[(packet_width-15-N2-2*N1-N3)];
             l=curr_test_case[(packet_width-16-N2-2*N1-N3)];
             e=curr_test_case[(packet_width-17-N2-2*N1-N3)];
             ov=curr_test_case[(packet_width-18-N2-2*N1-N3)];	
             err=curr_test_case[(packet_width-19-N2-2*N1-N3)];	
              if (CMD==4'b1001 || CMD==4'b1010)
	               expected_data = {Reserved_RES,Expected_RES,cout,e,l,g,ov,err};
	          else 
	               expected_data = {Expected_RES,cout,e,l,g,ov,err};
	         end
		 $display("At time (%0t), Feature_ID = %8b, IN_VALID=%2b, OPA = %8b, OPB = %8b, CMD = %4b, CIN = %1b, CE = %1b, MODE = %1b, Reserved_RES = %b, expected_result = %9b, cout = %1b, e=%1b, g=%1b, l=%1b, ov = %1b, err = %1b",$time,Feature_ID,IN_VALID,OPA,OPB,CMD,CIN,CE,MODE,Reserved_RES, Expected_RES,cout,e,g,l,ov,err);
		end
	endtask
	

	task dut_reset ();
		begin 
		CE=1;
        #10 RST=1;
		#20 RST=0;
		end
	endtask
	
	
	task global_init ();
		begin
		curr_test_case={packet_width{1'b0}};
		response_packet={response_width+1{1'b0}};
		stim_mem_ptr=0;
		end
	endtask	
	


        task monitor ();
        begin
        repeat(2)@(posedge CLK);#5;
		response_packet[packet_width-1:0]=curr_test_case;
		response_packet[packet_width]=ERR;
		response_packet[packet_width+1]=OFLOW;
		response_packet[packet_width+2]=G;
		response_packet[packet_width+3]=L;
		response_packet[packet_width+4]=E;
		response_packet[packet_width+5]=COUT;
        response_packet[(packet_width+6)+:N3]=RES;
                $display("Monitor: At time (%0t), RES = %9b COUT = %1b E = %1b G=%1b l=%1b OFLOW = %1b, ERR = %1b, IN_VALID=%2b",$time,RES,COUT,E,G,L,OFLOW,ERR,IN_VALID);  	
                exact_data ={RES,COUT,E,L,G,OFLOW,ERR};
		end
	endtask
//	`ifdef (CMD == MUL_I)
//	   assign expected_data = {Reserved_RES,Expected_RES,cout,e,l,g,ov,err};
//	`elsif (CMD == MUL_S)
//	   assign expected_data = {Reserved_RES,Expected_RES,cout,e,l,g,ov,err};
//	 `else 
//	   assign expected_data = {Expected_RES,cout,e,l,g,ov,err};
//	  `endif
	
   reg [scb_width-1:0] scb_stimulus_mem [0:`no_of_testcases-1];
   task score_board();
   reg [N1:0] expected_res;
   reg [N1-2:0] reserved_res;
   reg [7:0] feature_id;
   reg [N3+6:0] response_data;
                begin
                #5;
        	feature_id = curr_test_case[(packet_width-1)-:8];
    		reserved_res = curr_test_case[(packet_width-14-N2-2*N1)-:(N1-1)];
    		expected_res = curr_test_case[(packet_width-14-N2-2*N1-N1+1)-:N1+1];
         	response_data = response_packet[(response_width-1)-:(N3+6)];
                $display("expected result = %15b ,response data = %15b",expected_data,exact_data);               
    		 if(expected_data === exact_data) begin
    		     scb_stimulus_mem[scb_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`PASS};
    		     $display("TEST %0d PASSED",scb_ptr);
    		     end
  		    else begin
    		     scb_stimulus_mem[scb_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`FAIL};
    		     $display("TEST %0d FAILED",scb_ptr);
    		     end
            scb_ptr = scb_ptr + 1;
        end
    endtask
    
    
    task gen_report;
    integer file_id,pointer;
    reg [scb_width-1:0] status;
		begin
  		   file_id = $fopen("results.txt", "w");
                   for(pointer=0; pointer<=`no_of_testcases-1;pointer=pointer+1 )
                   begin 
  		                status = scb_stimulus_mem[pointer];
  		                if(status[0])
    		                 $fdisplay(file_id, "Feature ID %8b : PASS", status[(scb_width-2)-:8]);
  		                else
    		                 $fdisplay(file_id, "Feature ID %8b : FAIL", status[(scb_width-2)-:8]);
       		       end 
       		       $fclose(file_id); 		   
		      end   
    endtask
    
    initial 
	       begin 
	        #10;
		global_init();
	    dut_reset();
        read_stimulus();
   		for(j=0;j<=`no_of_testcases-1;j=j+1)
		begin
                fork
                      driver();
                      monitor();
                 join   
			     score_board();  
               end
               gen_report();
	       #300 $finish();
	       end
endmodule
