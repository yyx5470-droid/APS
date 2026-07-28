module fulladder4(
  input  logic [3:0] a_i,
  input  logic [3:0] b_i,
  input  logic       carry_i,
  
  output logic [3:0] sum_o,
  output logic       carry_o
);

wire carry_1, carry_2, carry_3;
  
fulladder A(
  .a_i (a_i[0]),
  .b_i (b_i[0]),
  .carry_i (carry_i),
  .sum_o (sum_o[0]),
  .carry_o (carry_1)
);
  
fulladder B(
  .a_i (a_i[1]),
  .b_i (b_i[1]),
  .carry_i (carry_1),
  .sum_o (sum_o[1]),
  .carry_o (carry_2)
);
  
fulladder C(
  .a_i (a_i[2]),
  .b_i (b_i[2]),
  .carry_i (carry_2),
  .sum_o (sum_o[2]),
  .carry_o (carry_3)
);
  
fulladder D(
  .a_i (a_i[3]),
  .b_i (b_i[3]),
  .carry_i (carry_3),
  .sum_o (sum_o[3]),
  .carry_o (carry_o)
);
  
endmodule
