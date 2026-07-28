module fulladder(
  input  logic a_i,
  input  logic b_i,
  input  logic carry_i,
  
  output logic sum_o,
  output logic carry_o
);

wire sum_1, carry_1, carry_2;
 
half_adder A(
  .a_i (a_i),
  .b_i (b_i),
  
  .sum_o (sum_1),
  .carry_o (carry_1)
);
  
half_adder B(
  .a_i (carry_i),
  .b_i (sum_1),
  
  .sum_o (sum_o),
  .carry_o (carry_2)
);
  
assign carry_o = carry_1 | carry_2;
  
endmodule