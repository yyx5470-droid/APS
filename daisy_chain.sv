module daisy_chain (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic [15:0] masked_irq_i,
  input  logic        ready_i,
  input  logic        irq_ret_i,

  output logic [15:0] irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

  logic [16:0] ready_chain;
  logic [15:0] cause;
  logic [15:0] cause_reg;

  assign ready_chain[0] = ready_i;

  assign cause = masked_irq_i & ready_chain[15:0];

  genvar i;
  generate
    for (i = 0; i < 16; i++) begin : daisy_logic
      assign ready_chain[i+1] = ready_chain[i] & ~cause[i];
    end
  endgenerate

  assign irq_o = |cause;

  assign irq_cause_o = {12'h800, cause, 4'h0};

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      cause_reg <= 16'd0;
    end else if (irq_o) begin
      cause_reg <= cause;
    end
  end

  assign irq_ret_o = irq_ret_i ? cause_reg : 16'd0;

endmodule