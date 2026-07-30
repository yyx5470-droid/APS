module lsu (
  input  logic        clk_i,
  input  logic        rst_i,

  input  logic        core_req_i,
  input  logic        core_we_i,
  input  logic [ 2:0] core_size_i,
  input  logic [31:0] core_addr_i,
  input  logic [31:0] core_wd_i,
  output logic [31:0] core_rd_o,
  output logic        core_stall_o,

  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [ 3:0] mem_be_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  input  logic [31:0] mem_rd_i,
  input  logic        mem_ready_i
);

  import decoder_pkg::*;

  assign mem_req_o  = core_req_i;
  assign mem_we_o   = core_we_i;
  assign mem_addr_o = core_addr_i;

  logic [1:0] byte_offset;
  logic       half_offset;
  
  assign byte_offset = core_addr_i[1:0];
  assign half_offset = core_addr_i[1];

  always_comb begin
    case (core_size_i)
      LDST_W:  mem_be_o = 4'b1111;
      LDST_H:  mem_be_o = half_offset ? 4'b1100 : 4'b0011;
      LDST_B:  mem_be_o = 4'b0001 << byte_offset;          
      default: mem_be_o = 4'b0000;
    endcase
  end

  always_comb begin
    case (core_size_i)
      LDST_H:  mem_wd_o = {2{core_wd_i[15:0]}};
      LDST_W:  mem_wd_o = core_wd_i;
      LDST_B:  mem_wd_o = {4{core_wd_i[7:0]}};
      default: mem_wd_o = core_wd_i;
    endcase
  end

  logic [31:0] se_b [3:0];
  logic [31:0] se_h [1:0];
  
  assign se_b[0] = {{24{mem_rd_i[7]}},  mem_rd_i[7:0]};
  assign se_b[1] = {{24{mem_rd_i[15]}}, mem_rd_i[15:8]};
  assign se_b[2] = {{24{mem_rd_i[23]}}, mem_rd_i[23:16]};
  assign se_b[3] = {{24{mem_rd_i[31]}}, mem_rd_i[31:24]};
  
  assign se_h[0] = {{16{mem_rd_i[15]}}, mem_rd_i[15:0]};
  assign se_h[1] = {{16{mem_rd_i[31]}}, mem_rd_i[31:16]};

  logic [31:0] ze_b [3:0];
  logic [31:0] ze_h [1:0];
  
  assign ze_b[0] = {24'b0, mem_rd_i[7:0]};
  assign ze_b[1] = {24'b0, mem_rd_i[15:8]};
  assign ze_b[2] = {24'b0, mem_rd_i[23:16]};
  assign ze_b[3] = {24'b0, mem_rd_i[31:24]};
  
  assign ze_h[0] = {16'b0, mem_rd_i[15:0]};
  assign ze_h[1] = {16'b0, mem_rd_i[31:16]};

  logic [31:0] mux_se_b, mux_ze_b, mux_se_h, mux_ze_h;
  
  assign mux_se_b = se_b[byte_offset];
  assign mux_ze_b = ze_b[byte_offset];
  assign mux_se_h = se_h[half_offset];
  assign mux_ze_h = ze_h[half_offset];

  always_comb begin
    case (core_size_i)
      LDST_W:  core_rd_o = mem_rd_i;
      LDST_B:  core_rd_o = mux_se_b;
      LDST_BU: core_rd_o = mux_ze_b;
      LDST_H:  core_rd_o = mux_se_h;
      LDST_HU: core_rd_o = mux_ze_h;
      default: core_rd_o = mem_rd_i;
    endcase
  end

  logic stall_reg;
  logic nand_out;

  assign nand_out     = ~(stall_reg & mem_ready_i);
  assign core_stall_o = core_req_i & nand_out;

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
      stall_reg <= 1'b0;
    else
      stall_reg <= core_stall_o;
  end

endmodule
