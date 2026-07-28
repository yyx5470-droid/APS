module CYBERcobra (
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [15:0]  sw_i,
  output logic [31:0]  out_o
);
  
  logic [31:0] pc_reg;
  logic [31:0] pc_next;
  
  logic [31:0] instr;
  logic [31:0] rd1;
  logic [31:0] rd2;
  logic [31:0] alu_result;
  logic        alu_flag;
  
  logic [4:0]  ra1;
  logic [4:0]  ra2;
  logic [4:0]  wa;
  logic [4:0]  alu_op;
  logic [1:0]  ws;
  logic [22:0] rf_const;
  logic [31:0] rf_const_max;
  logic [31:0] sw_i_max;
  logic        b;
  logic [31:0] pc_add;
  logic [7:0]  offset;
  logic [31:0] offset_max;
  logic        j;
  
  assign ra1      = instr[22:18];
  assign ra2      = instr[17:13];
  assign wa       = instr[4:0];
  assign alu_op   = instr[27:23];
  assign ws       = instr[29:28];
  assign rf_const = instr[27:5];
  assign b        = instr[30];
  assign offset   = instr[12:5];
  assign j        = instr[31];
  
  assign rf_const_max = {{9{rf_const[22]}}, rf_const};
  assign sw_i_max     = {{16{sw_i[15]}}, sw_i};
  assign offset_max   = {{24{offset[7]}}, offset};
  
  logic [31:0] wd;
  
  always_comb begin
    case(ws)
      2'b00: wd = rf_const_max;
      2'b01: wd = alu_result;
      2'b10: wd = sw_i_max;
      2'b11: wd = 32'd0;
    endcase
  end
  
  logic        pc_sel;
  logic [31:0] pc_imm;
  
  assign pc_sel  = j | (b & alu_flag);
  assign pc_imm  = {offset_max[29:0], 2'b0};
  assign pc_add  = pc_sel ? pc_imm : 32'd4;
  assign pc_next = pc_reg + pc_add;
  
  always_ff @(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
      pc_reg <= 32'd0;
    end
    else begin
      pc_reg <= pc_next;
    end
  end
  
  instr_mem imem (
    .read_addr_i (pc_reg),
    .read_data_o (instr)
  );
  
  register_file rf (
    .clk_i          (clk_i),
    .write_enable_i (~(j | b)),
    .write_addr_i   (wa),
    .read_addr1_i   (ra1),
    .read_addr2_i   (ra2),
    .write_data_i   (wd),
    .read_data1_o   (rd1),
    .read_data2_o   (rd2)
  );
  
  alu alu_unit (
    .a_i      (rd1),
    .b_i      (rd2),
    .alu_op_i (alu_op),
    .flag_o   (alu_flag),
    .result_o (alu_result)
  );
  
  assign out_o = rd1;

endmodule