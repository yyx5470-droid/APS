module processor_core (
  input  logic        clk_i,
  input  logic        rst_i,

  input  logic        stall_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_rd_i,
  input  logic [15:0] irq_req_i,

  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [ 2:0] mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_wd_o,
  output logic [15:0] irq_ret_o 
);

  import decoder_pkg::*;
  import alu_opcodes_pkg::*; 

  logic [31:0] pc_reg;
  logic [31:0] pc_next;
  logic        illegal_instr;
  
  assign instr_addr_o = pc_reg;

  logic        irq;
  logic        trap;
  logic [31:0] irq_cause;
  logic [31:0] mcause_in;
  logic [31:0] csr_wd;
  logic [31:0] mie;
  logic [31:0] mepc;
  logic [31:0] mtvec;

  assign trap = irq | illegal_instr;
  
  assign mcause_in = illegal_instr ? 32'h0000_0002 : irq_cause;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      pc_reg <= 32'b0;
    end else if (!stall_i | trap) begin 
      pc_reg <= pc_next;
    end
  end

  logic [1:0] a_sel;
  logic [2:0] b_sel;
  logic [4:0] alu_op;
  logic       gpr_we;
  logic [1:0] wb_sel;
  logic [2:0] mem_size;
  logic       mem_req;
  logic       mem_we;
  logic       b;
  logic       jal;
  logic       jalr;
  logic [2:0] csr_op;
  logic       csr_we;
  logic       mret;

  logic [31:0] rd1;
  logic [31:0] rd2;
  logic [31:0] wd3;

  logic [31:0] alu_a;
  logic [31:0] alu_b;
  logic [31:0] alu_result;
  logic        alu_flag; 

  logic [31:0] imm_I;
  assign imm_I = { {20{instr_i[31]}}, instr_i[31:20] };
  
  logic [31:0] imm_U;
  assign imm_U = { instr_i[31:12], 12'b0 };
  
  logic [31:0] imm_S;
  assign imm_S = { {20{instr_i[31]}}, instr_i[31:25], instr_i[11:7] };
  
  logic [31:0] imm_B;
  assign imm_B = { {20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0 };
  
  logic [31:0] imm_J;
  assign imm_J = { {11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

  logic [31:0] imm_Z;
  assign imm_Z = { 27'b0, instr_i[19:15] };

  decoder decoder_inst (
    .fetched_instr_i(instr_i),
    .a_sel_o        (a_sel),
    .b_sel_o        (b_sel),
    .alu_op_o       (alu_op),
    .gpr_we_o       (gpr_we),
    .wb_sel_o       (wb_sel),
    .mem_size_o     (mem_size),
    .mem_req_o      (mem_req),
    .mem_we_o       (mem_we),
    .branch_o       (b),
    .jal_o          (jal),
    .jalr_o         (jalr),
    .csr_op_o       (csr_op),
    .csr_we_o       (csr_we),
    .illegal_instr_o(illegal_instr),
    .mret_o         (mret)
  );

  register_file rf_inst (
    .clk_i         (clk_i),
    .read_addr1_i  (instr_i[19:15]),
    .read_addr2_i  (instr_i[24:20]),
    .write_addr_i  (instr_i[11:7]), 
    .write_data_i  (wd3),
    .write_enable_i(gpr_we & ~(stall_i | trap)),        
    .read_data1_o  (rd1),
    .read_data2_o  (rd2)
  );

  interrupt_controller irq_ctrl_inst (
    .clk_i       (clk_i),
    .rst_i       (rst_i),
    .exception_i (illegal_instr),
    .irq_req_i   (irq_req_i),
    .mie_i       (mie[31:16]),
    .mret_i      (mret),
    .irq_o       (irq),
    .irq_cause_o (irq_cause),
    .irq_ret_o   (irq_ret_o)
  );

  csr_controller csr_ctrl_inst (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .trap_i         (trap),
    .opcode_i       (csr_op),
    .addr_i         (instr_i[31:20]),
    .pc_i           (pc_reg),
    .mcause_i       (mcause_in),
    .rs1_data_i     (rd1),
    .imm_data_i     (imm_Z),
    .write_enable_i (csr_we),
    .read_data_o    (csr_wd),
    .mie_o          (mie),
    .mepc_o         (mepc),
    .mtvec_o        (mtvec)
  );

  always_comb begin
    case (a_sel)
      OP_A_RS1:     alu_a = rd1;
      OP_A_CURR_PC: alu_a = pc_reg;
      OP_A_ZERO:    alu_a = 32'b0;
      default:      alu_a = rd1;
    endcase
  end

  always_comb begin
    case (b_sel)
      OP_B_RS2:   alu_b = rd2;
      OP_B_IMM_I: alu_b = imm_I;
      OP_B_IMM_U: alu_b = imm_U;
      OP_B_IMM_S: alu_b = imm_S;
      OP_B_INCR:  alu_b = 32'd4;
      default:    alu_b = rd2;
    endcase
  end

  alu alu_inst (
    .a_i     (alu_a),
    .b_i     (alu_b),
    .alu_op_i(alu_op),
    .result_o(alu_result),
    .flag_o  (alu_flag)
  );

  always_comb begin
    case (wb_sel)
      WB_EX_RESULT: wd3 = alu_result;
      WB_LSU_DATA:  wd3 = mem_rd_i;
      2'b10:        wd3 = csr_wd;
      default:      wd3 = alu_result;
    endcase
  end
  
  logic [31:0] sum_rd1_imm_i;
  logic [31:0] pc_jalr;
  assign sum_rd1_imm_i = rd1 + imm_I;
  assign pc_jalr = {sum_rd1_imm_i[31:1], 1'b0};
  
  logic [31:0] mux_imm_out;
  always_comb begin
    if(b) mux_imm_out = imm_B;
    else  mux_imm_out = imm_J;
  end
  
  logic b_and_flag;
  assign b_and_flag = b & alu_flag;
  
  logic or_control;
  assign or_control = jal | b_and_flag;
  
  logic [31:0] mux_inc_out;
  always_comb begin
    if (or_control) mux_inc_out = mux_imm_out;
    else            mux_inc_out = 32'd4; 
  end
  
  logic [31:0] pc_plus_imm_or_4;
  assign pc_plus_imm_or_4 = pc_reg + mux_inc_out;
  
  logic [31:0] pc_mux1;
  logic [31:0] pc_mux2;
  
  assign pc_mux1 = jalr ? pc_jalr : pc_plus_imm_or_4;
  assign pc_mux2 = mret ? mepc : pc_mux1;
  assign pc_next = trap ? mtvec : pc_mux2;

  assign mem_req_o  = mem_req & ~trap;
  assign mem_we_o   = mem_we & ~trap;
  assign mem_size_o = mem_size;
  assign mem_addr_o = alu_result;
  assign mem_wd_o   = rd2;   

endmodule