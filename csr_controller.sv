module csr_controller (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        trap_i,

  input  logic [ 2:0] opcode_i,

  input  logic [11:0] addr_i,
  input  logic [31:0] pc_i,
  input  logic [31:0] mcause_i,
  input  logic [31:0] rs1_data_i,
  input  logic [31:0] imm_data_i,
  input  logic        write_enable_i,

  output logic [31:0] read_data_o,
  output logic [31:0] mie_o,
  output logic [31:0] mepc_o,
  output logic [31:0] mtvec_o
);

  import csr_pkg::*;

  logic [31:0] mie_reg;
  logic [31:0] mtvec_reg;
  logic [31:0] mscratch_reg;
  logic [31:0] mepc_reg;
  logic [31:0] mcause_reg;

  logic [31:0] write_data;

  always_comb begin
    case (opcode_i)
      CSR_RW:  write_data = rs1_data_i;
      CSR_RS:  write_data = rs1_data_i | read_data_o;
      CSR_RC:  write_data = ~rs1_data_i & read_data_o;
      CSR_RWI: write_data = imm_data_i;
      CSR_RSI: write_data = imm_data_i | read_data_o;
      CSR_RCI: write_data = ~imm_data_i & read_data_o;
      default: write_data = 32'b0;
    endcase
  end

  logic en_mie, en_mtvec, en_mscratch, en_mepc, en_mcause;

  assign en_mie      = write_enable_i && (addr_i == MIE_ADDR);
  assign en_mtvec    = write_enable_i && (addr_i == MTVEC_ADDR);
  assign en_mscratch = write_enable_i && (addr_i == MSCRATCH_ADDR);
  assign en_mepc     = (write_enable_i && (addr_i == MEPC_ADDR)) || trap_i;
  assign en_mcause   = (write_enable_i && (addr_i == MCAUSE_ADDR)) || trap_i;

  logic [31:0] mepc_wdata;
  logic [31:0] mcause_wdata;

  assign mepc_wdata   = trap_i ? pc_i     : write_data;
  assign mcause_wdata = trap_i ? mcause_i : write_data;

  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      mie_reg      <= 32'b0;
      mtvec_reg    <= 32'b0;
      mscratch_reg <= 32'b0;
      mepc_reg     <= 32'b0;
      mcause_reg   <= 32'b0;
    end 
    else begin
      if (en_mie)      mie_reg      <= write_data;
      if (en_mtvec)    mtvec_reg    <= write_data;
      if (en_mscratch) mscratch_reg <= write_data;
      if (en_mepc)     mepc_reg     <= mepc_wdata;
      if (en_mcause)   mcause_reg   <= mcause_wdata;
    end
  end

  always_comb begin
    case (addr_i)
      MIE_ADDR:      read_data_o = mie_reg;
      MTVEC_ADDR:    read_data_o = mtvec_reg;
      MSCRATCH_ADDR: read_data_o = mscratch_reg;
      MEPC_ADDR:     read_data_o = mepc_reg;
      MCAUSE_ADDR:   read_data_o = mcause_reg;
      default:       read_data_o = 32'b0;
    endcase
  end

  assign mie_o   = mie_reg;
  assign mepc_o  = mepc_reg;
  assign mtvec_o = mtvec_reg;

endmodule