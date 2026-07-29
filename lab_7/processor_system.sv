module processor_system(
  input  logic clk_i,
  input  logic rst_i
);

  logic [31:0] instr_addr;
  logic [31:0] instr;
  
  logic        stall_reg;
  logic [31:0] mem_addr;
  logic [31:0] mem_wd;
  logic [31:0] mem_rd;
  logic        mem_req;
  logic        mem_we;
  
  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      stall_reg <= 1'b0;
    else
      stall_reg <= (~stall_reg) | mem_req;
  end

  processor_core core (
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .stall_i      (stall_reg),
    .instr_i      (instr),
    .mem_rd_i     (mem_rd),
    .instr_addr_o (instr_addr),
    .mem_addr_o   (mem_addr),
    .mem_size_o   (),
    .mem_req_o    (mem_req),
    .mem_we_o     (mem_we),
    .mem_wd_o     (mem_wd)
  );

  instr_mem imem (
    .read_addr_i (instr_addr),
    .read_data_o (instr)
  );
  
  data_mem datm (
    .clk_i          (clk_i),
    .mem_req_i      (mem_req),
    .write_enable_i (mem_we),
    .byte_enable_i  (4'b1111),
    .addr_i         (mem_addr),
    .write_data_i   (mem_wd),
    .read_data_o    (mem_rd),
    .ready_o        ()
  );

endmodule
