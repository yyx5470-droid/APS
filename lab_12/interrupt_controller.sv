module interrupt_controller (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic [15:0] irq_req_i,
  input  logic [15:0] mie_i,
  input  logic        mret_i,

  output logic [15:0] irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

  logic exc_h;
  logic irq_h;
  logic ex_or_q;
  logic irq_ret_internal;

  assign ex_or_q = exception_i | exc_h;

  assign irq_ret_internal = mret_i & ~ex_or_q;

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      exc_h <= 1'b0;
    end else begin
      exc_h <= ex_or_q & ~mret_i;
    end
  end

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      irq_h <= 1'b0;
    end else begin
      irq_h <= (irq_o | irq_h) & ~irq_ret_internal;
    end
  end

  daisy_chain dc_inst (
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .masked_irq_i (irq_req_i & mie_i),
    .ready_i      (~(ex_or_q | irq_h)),
    .irq_ret_i    (irq_ret_internal),
    
    .irq_ret_o    (irq_ret_o),
    .irq_cause_o  (irq_cause_o),
    .irq_o        (irq_o)
  );

endmodule