`timescale 1ns / 1ps

module fulladder32(
  input  logic [31:0] a_i,
  input  logic [31:0] b_i,
  input  logic        carry_i,

  output logic [31:0] sum_o,
  output logic        carry_o
);
    
wire [8:0] carry;

assign carry[0] = carry_i;

fulladder4 adder[7:0] (
  .a_i     (a_i),
  .b_i     (b_i),
  .carry_i (carry[7:0]),
  .sum_o   (sum_o),
  .carry_o (carry[8:1])
);

assign carry_o = carry[8];
    
endmodule
