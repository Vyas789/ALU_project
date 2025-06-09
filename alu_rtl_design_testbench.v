`timescale 1ns/1ps
`define MUL_INC
`define MUL_SHIFT

module alu_rtl_testbench;
  parameter N1 = 8, N2 = 4, N3 = 9;
  parameter RES_WIDTH = (N3);

  reg [N1-1:0] OPA, OPB;
  reg CIN, CLK, RST, CE, MODE;
  reg [1:0] IN_VALID;
  reg [N2-1:0] CMD;
  wire [RES_WIDTH-1:0] RES;
  wire COUT, OFLOW, G, E, L, ERR;

  alu_rtl_design DUT (
    .OPA(OPA), .OPB(OPB), .CIN(CIN), .CLK(CLK), .RST(RST),
    .CMD(CMD), .CE(CE), .MODE(MODE), .IN_VALID(IN_VALID),
    .RES(RES), .OFLOW(OFLOW), .COUT(COUT),
    .G(G), .E(E), .L(L), .ERR(ERR)
  );

  // Clock generation
  always #5 CLK = ~CLK;

  task apply_arith(input [3:0] cmd, input [N1-1:0] a, b, input c);
    begin
      @(posedge CLK);
      MODE = 1; CE = 1; CMD = cmd;
      OPA = a; OPB = b; CIN = c;
      IN_VALID = 2'b11;
      @(posedge CLK);
      $display("CMD=%0d OPA=%0d OPB=%0d CIN=%0d RES=%0d COUT=%b OFLOW=%b", CMD, OPA, OPB, CIN, RES, COUT, OFLOW);
    end
  endtask
  
  task apply_single_op_A(input [3:0] cmd, input [N1-1:0] a);
    begin
        @(posedge CLK);
        MODE = 1; CE = 1; CMD = cmd;
        OPA = a; 
        IN_VALID = 2'b01;
        @(posedge CLK);
        $display("CMD=%0d OPA=%0d OPB=%0d CIN=%0d RES=%0d COUT=%b OFLOW=%b", CMD, OPA, OPB, CIN, RES, COUT, OFLOW);
    end
  endtask
        
  task apply_single_op_B(input [3:0] cmd, input [N1-1:0] b);
    begin
        @(posedge CLK);
        MODE = 1; CE = 1; CMD = cmd;
        OPB = b; 
        IN_VALID = 2'b10;
        @(posedge CLK);
        $display("CMD=%0d OPA=%0d OPB=%0d CIN=%0d RES=%0d COUT=%b OFLOW=%b", CMD, OPA, OPB, CIN, RES, COUT, OFLOW);
    end
  endtask

  task apply_logical(input [3:0] cmd, input [N1-1:0] a, b);
    begin
      @(posedge CLK);
      MODE = 0; CE = 1; CMD = cmd;
      OPA = a; OPB = b;
      IN_VALID = 2'b11;
      @(posedge CLK);
      $display("LOGIC CMD=%0d OPA=%0d OPB=%0d RES=%0d ERR=%b", CMD, OPA, OPB, RES, ERR);
    end
  endtask

  initial begin
    // Initialize
    CLK = 0; RST = 1; CE = 0; MODE = 0;
    CIN = 0; OPA = 0; OPB = 0; CMD = 0; IN_VALID = 0;
    #10 RST = 0;

    // --- Arithmetic operations ---
    apply_arith(4'b0000, 10, 10, 0); // ADD
    apply_arith(4'b0000, 10, 8'bz, 0); // ADD
    apply_arith(4'b0001, 50, 25, 0); // SUB
    apply_arith(4'b0010, 5, 10, 1);  // ADD_CIN
    apply_arith(4'b0011, 20, 10, 1); // SUB_CIN
    #5 CE = 0;
    #20 CE = 1;
    apply_single_op_A(4'b0100, 10);  // INC_A
    apply_single_op_A(4'b0101, 10);  // DEC_A
    apply_single_op_B(4'b0110, 255);  // INC_B
    apply_single_op_B(4'b0111, 0);  // DEC_B
    apply_arith(4'b1000, 20, 20, 0); // CMP Equal
    apply_arith(4'b1000, 30, 20, 0); // CMP Greater
    apply_arith(4'b1000, 10, 20, 0); // CMP Less

    // --- Signed operations ---
    apply_arith(4'b1011, -50, 20, 0); // ADD_SIGN
    apply_arith(4'b1100, -10, 20, 0); // SUB_SIGN

    // --- Multiply operations ---
    apply_arith(4'b1001, 3, 4, 0);    // MUL_INC
    #20 apply_arith(4'b1010, 3, 4, 0);    // MUL_SHIFT

    // --- Logical operations ---
    #20 apply_logical(4'b0000, 8'hAA, 8'hF0); // AND
    apply_logical(4'b0000, 8'hAA, 8'hz); // AND
    apply_logical(4'b0001, 8'hAA, 8'hF0); // NAND
    apply_logical(4'b0010, 8'hAA, 8'hF0); // OR
    apply_logical(4'b0011, 8'hAA, 8'hF0); // NOR
    apply_logical(4'b0100, 8'hAA, 8'hF0); // XOR
    apply_logical(4'b0101, 8'hAA, 8'hF0); // XNOR
    apply_single_op_A(4'b0110, 8'h55);     // NOT_A
    apply_single_op_B(4'b0111, 8'h55);     // NOT_B
    apply_single_op_A(4'b1000, 8'h80);     // SHR1_A
    apply_single_op_A(4'b1001, 8'h01);     // SHL1_A
    apply_single_op_B(4'b1010, 8'h80);     // SHR1_B
    apply_single_op_B(4'b1011, 8'h01);     // SHL1_B
    apply_logical(4'b1100, 8'hF0, 8'h00); // ROL_A_B
    apply_logical(4'b1100, 8'hF0, 8'h01); // ROL_A_B
    apply_logical(4'b1100, 8'hF0, 8'h02); // ROL_A_B
    apply_logical(4'b1100, 8'hF0, 8'h03); // ROL_A_B
    apply_logical(4'b1100, 8'hF0, 8'h04); // ROR_A_B
    apply_logical(4'b1100, 8'hF0, 8'h05); // ROL_A_B
    apply_logical(4'b1100, 8'hF0, 8'h06); // ROL_A_B
    apply_logical(4'b1100, 8'hF0, 8'h07); // ROL_A_B
    apply_logical(4'b1100, 8'hF0, 8'h08); // ROL_A_B
    apply_logical(4'b1100, 8'hF0, 8'h0a); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h00); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h01); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h02); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h03); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h04); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h05); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h06); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h07); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h08); // ROR_A_B
    apply_logical(4'b1101, 8'hF0, 8'h0a); // ROR_A_B
    // --- Error case: Invalid shift amount for rotate ---
    apply_logical(4'b1100, 8'hF0, 8'hFF); // ROL_A_B with invalid shift
    apply_logical(4'b1101, 8'hF0, 8'hFF); // ROR_A_B with invalid shift

    $finish;
  end
endmodule
