module interrupt_controller (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        exception_i,
  input  logic        irq_req_i,
  input  logic        mie_i,
  input  logic        mret_i,

  output logic        irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

  logic exc_h;
  logic irq_h;

  logic reset_irq;
  logic ex_or_q;
  
  assign ex_or_q = exception_i | exc_h;
  assign irq_cause_o = 32'h8000_0010;

  assign irq_o = (irq_req_i & mie_i) & ~(ex_or_q | irq_h);

  assign reset_irq = mret_i & ~ex_or_q;
  assign irq_ret_o = reset_irq;

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
      irq_h <= (irq_o | irq_h) & ~reset_irq;
    end
  end

endmodule