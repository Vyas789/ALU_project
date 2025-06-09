`timescale 1ns/1ps
module alu_rtl_design(OPA,OPB,CIN,CLK,RST,CMD,CE,MODE,IN_VALID,RES,OFLOW,COUT,G,E,L,ERR);
    parameter N1 = 8,
              N2 = 4,   
              RES_WIDTH = 16,
              result = 9;
    parameter shift_width = $clog2(N1);
              
  input [N1-1:0] OPA,OPB;
  input CLK,RST,CE,MODE,CIN;
  input [1:0] IN_VALID;
  input [N2-1:0] CMD;
  output reg [RES_WIDTH-1:0] RES = 'b0;
  output reg COUT = 1'b0;
  output reg OFLOW = 1'b0;
  output reg G = 1'b0;
  output reg E = 1'b0;
  output reg L = 1'b0;
  output reg ERR = 1'b0;
  
  localparam[N2-1:0]          ADD = 4'b0000,
                              SUB = 4'b0001,
                          ADD_CIN = 4'b0010,
                          SUB_CIN = 4'b0011,
                            INC_A = 4'b0100,
                            DEC_A = 4'b0101,
                            INC_B = 4'b0110,
                            DEC_B = 4'b0111,
                              CMP = 4'b1000,
                             MUL_I = 4'b1001,
                             MUL_S = 4'b1010, 
                         ADD_SIGN = 4'b1011,
                         SUB_SIGN = 4'b1100;
    localparam[N2-1:0]        AND = 4'b0000,
                             NAND = 4'b0001,
                               OR = 4'b0010,
                              NOR = 4'b0011,
                              XOR =4'b0100,
                             XNOR = 4'b0101,
                            NOT_A = 4'b0110,
                            NOT_B = 4'b0111,
                           SHR1_A = 4'b1000,
                           SHL1_A = 4'b1001,
                           SHR1_B = 4'b1010,
                           SHL1_B = 4'b1011,
                          ROL_A_B = 4'b1100,
                          ROR_A_B = 4'b1101;  
               
  
  reg [N1-1:0] OPA_T,OPB_T;
  reg CIN_T;
  reg signed [N1-1:0] OPA_1,OPB_1;
  
  integer i; 
  reg [shift_width-1:0] shift_amount;
  
  reg [result-1:0] res_t;
  reg cout_t,oflow_t,e_t,g_t,l_t,err_t;
  
  reg [RES_WIDTH-1: 0] mul_res;
  reg [RES_WIDTH-1:0] temp_res;
  
    always@(posedge CLK,posedge RST) begin
        if (RST) begin
            res_t<={result{1'b0}};
            cout_t<=1'b0;
            oflow_t<=1'b0;
            g_t<=1'b0;
            e_t<=1'b0;
            l_t<=1'b0;
            err_t<=1'b0;
            OPA_T<=0;
            OPB_T<=0;
            CIN_T<=0;
            mul_res<=0;
            end
       else if (CE) begin
            OPA_T<= OPA;
            OPB_T<=OPB;
            CIN_T<=CIN;
            end
    end      
    
    always@(*) begin
       res_t={result{1'b0}};
       cout_t=1'b0;
       oflow_t=1'b0;
       g_t=1'b0;
       e_t=1'b0;
       l_t=1'b0;
       mul_res=0;
       err_t=1'b0;
      if (CE) begin
         if (MODE) begin  
            if (IN_VALID == 2'b00) begin 
                res_t={result{1'b0}};
                cout_t=1'b0;
                oflow_t=1'b0;
                g_t=1'b0;
                e_t=1'b0;
                l_t=1'b0;
                err_t=1'b0;
                mul_res=0;
            end
            else if (IN_VALID == 2'b01) begin 
                case(CMD) 
                    INC_A: begin
                         res_t=OPA_T+1;  
                         cout_t=res_t[result-1]?1:0; 
                     end
                    DEC_A: begin
                        res_t=OPA_T-1;  
                        oflow_t=(OPA_T<=0)?1:0;
                    end
                    default: begin 
                             res_t={result{1'b0}};
                             cout_t=1'b0;
                             oflow_t=1'b0;
                             g_t=1'b0;
                             e_t=1'b0;
                             l_t=1'b0;
                             err_t=1'b0;
                             mul_res=0;
                    end
                endcase
            end
            else if (IN_VALID == 2'b10) begin 
                case(CMD)
                    INC_B: begin
                        res_t=OPB_T+1;    
                        cout_t=res_t[result-1]?1:0; 
                    end
                    DEC_B:begin
                        res_t=OPB_T-1;    
                        oflow_t=(OPB_T<=0)?1:0;
                    end
                    default: begin 
                            res_t={result{1'b0}};
                            cout_t=1'b0;
                            oflow_t=1'b0;
                            g_t=1'b0;
                            e_t=1'b0;
                            l_t=1'b0;
                            err_t=1'b0;
                            mul_res=0;
                    end
                endcase 
            end
            else if (IN_VALID == 2'b11) begin 
                case(CMD)
                    ADD: begin      
                        res_t=OPA_T+OPB_T;
                        cout_t=res_t[result-1]?1:0; 
                    end
                    SUB: begin     
                        oflow_t=(OPA_T<OPB_T)?1:0;
                        res_t=OPA_T-OPB_T;
                    end
                    ADD_CIN: begin     
                        res_t=OPA_T+OPB_T+CIN_T;
                        cout_t=res_t[result-1]?1:0;
                    end
                    SUB_CIN: begin     
                        oflow_t = ((OPA_T < OPB_T)||(OPA_T == OPB_T && CIN_T))? 1'b1 : 1'b0;
                        res_t=OPA_T-OPB_T-CIN_T;
                    end
                    CMP: begin
                        res_t={result{1'b0}};
                        if(OPA_T==OPB_T) begin
                            e_t=1'b1;
                            g_t=1'b0;
                            l_t=1'b0;
                        end
                        else if(OPA_T>OPB_T) begin
                            e_t=1'b0;
                            g_t=1'b1;
                            l_t=1'b0;
                        end
                        else begin
                            e_t=1'b0;
                            g_t=1'b0;
                            l_t=1'b1;
                        end
                    end
                    MUL_I: begin
                               mul_res  = (OPA_T + 1) * (OPB_T + 1);
                         end
                    MUL_S: begin
                               mul_res = (OPA_T << 1) * OPB_T;
                         end
                    ADD_SIGN: begin
                        OPA_1 = $signed(OPA_T);
                        OPB_1 = $signed(OPB_T);
                        res_t = OPA_1 + OPB_1;
                        oflow_t = (OPA_1[N1-1] == OPB_1[N1-1]) && (res_t[N1-1] != OPA_1[N1-1]);
                                  

                  if ($signed(OPA_T) == $signed(OPB_T)) begin
                    e_t = 1'b1;
                    g_t = 1'b0;
                    l_t = 1'b0;
                  end
                  else if ($signed(OPA_T) > $signed(OPB_T)) begin
                    e_t = 1'b0;
                    g_t = 1'b1;
                    l_t = 1'b0;
                  end
                  else begin
                    e_t = 1'b0;
                    g_t = 1'b0;
                    l_t = 1'b1;
                  end
          end
                    SUB_SIGN: begin
                        OPA_1 = $signed(OPA_T);
                        OPB_1 = $signed(OPB_T);
                        res_t = OPA_1 - OPB_1;
                        oflow_t = (OPA_1[N1-1] != OPB_1[N1-1])&& (res_t[N1-1] != OPA_1[N1-1]);
                                
                   if ($signed(OPA_T) == $signed(OPB_T)) begin
                     e_t = 1'b1;
                     g_t = 1'b0;
                     l_t = 1'b0;
                   end
                   else if ($signed(OPA_T) > $signed(OPB_T)) begin
                     e_t = 1'b0;
                     g_t = 1'b1;
                     l_t = 1'b0;
                   end
                   else begin
                     e_t = 1'b0;
                     g_t = 1'b0;
                     l_t = 1'b1;
                  end
          end
          default: begin
                    res_t={result{1'b0}};
                    cout_t=1'b0;
                    oflow_t=1'b0;
                    g_t=1'b0;
                    e_t=1'b0;
                    l_t=1'b0;
                    err_t=1'b0;
                    mul_res=0;
                    end
        endcase
      end
  end
            else begin 
                    if(IN_VALID == 2'b00) begin
                        res_t={result{1'b0}};
                        cout_t=1'b0;
                        oflow_t=1'b0;
                        g_t=1'b0;
                        e_t=1'b0;
                        l_t=1'b0;
                        err_t=1'b0;
                        mul_res=0;
                    end
                    else if (IN_VALID == 2'b01) begin
                        case(CMD)
                            NOT_A: res_t={1'b0,~OPA_T};       
                            SHR1_A: res_t={1'b0,OPA_T>>1};    
                            SHL1_A: res_t={1'b0,OPA_T<<1};    
                            default: begin
                                res_t={result{1'b0}};
                                oflow_t=1'b0;
                                err_t=1'b0;
                                cout_t=1'b0;
                                g_t=1'b0;
                                l_t=1'b0;
                                e_t=1'b0;
                                mul_res=0;
                            end
                        endcase
                    end
                    else if (IN_VALID == 2'B10) begin
                        case(CMD)
                            NOT_B: res_t={1'b0,~OPB_T};   
                            SHR1_B: res_t={1'b0,OPB_T>>1};
                            SHL1_B: res_t={1'b0,OPB_T<<1};
                            default: begin
                                res_t={result{1'b0}};
                                oflow_t=1'b0;
                                err_t=1'b0;
                                cout_t=1'b0;
                                g_t=1'b0;
                                l_t=1'b0;
                                e_t=1'b0;
                                mul_res=0;
                            end
                        endcase
                     end
                     else if (IN_VALID == 2'B11) begin
                        case(CMD)
                            AND: res_t={1'b0,OPA_T&OPB_T};     
                            NAND: res_t={1'b0,~(OPA_T&OPB_T)}; 
                            OR: res_t={1'b0,OPA_T|OPB_T};     
                            NOR: res_t={1'b0,~(OPA_T|OPB_T)};  
                            XOR: res_t={1'b0,OPA_T^OPB_T};     
                            XNOR: res_t={1'b0,~(OPA_T^OPB_T)}; 
                            ROL_A_B: begin
                                if (|OPB_T[N1-1:shift_width]) begin
                                     err_t = 1;
                                     shift_amount = OPB_T[shift_width-1:0];                                  
                                     res_t = {1'b0,(OPA_T << shift_amount) | (OPA_T >> (N1 - shift_amount))};
                                     end
                                else begin
                                    shift_amount = OPB_T[shift_width-1:0];
                                    res_t = {1'b0,(OPA_T << shift_amount) | (OPA_T >> (N1 - shift_amount))};
                                end
                            end
                            ROR_A_B: begin
                                    if (OPB_T[N1-1:shift_width]) begin
                                        err_t = 1;
                                        shift_amount = OPB_T[shift_width-1:0];
                                        res_t = {1'b0,(OPA_T >> shift_amount) | (OPA_T << (N1 - shift_amount))};
                                        end
                                    else begin
                                        shift_amount = OPB_T[shift_width-1:0];
                                        res_t = {1'b0,(OPA_T >> shift_amount) | (OPA_T << (N1 - shift_amount))};
                                    end
                                end
                            default: begin
                                    res_t={result{1'b0}};
                                    oflow_t=1'b0;
                                    err_t=1'b0;
                                    cout_t=1'b0;
                                    g_t=1'b0;
                                    l_t=1'b0;
                                    e_t=1'b0;
                                    mul_res=0;
                                 end
                         endcase
                     end 
                 end
             end
         end 
         
always@(posedge CLK or posedge RST)begin
    if(RST)begin
            RES <= 'b0;
            COUT <= 0;
            OFLOW <= 0;
            E <= 0;
            G <= 0;
            L <= 0;
            ERR <= 0;
    end
  
    else if (CMD ==  MUL_I || CMD ==  MUL_S)begin
            temp_res <= mul_res;
            RES <= temp_res;
    end
    else begin
           RES <= res_t ;
           COUT <= cout_t;
           OFLOW <= oflow_t;
           G <= g_t ;
           E <= e_t ;
           L <=l_t ;
           ERR <= err_t ;
        end    
 end 
endmodule
