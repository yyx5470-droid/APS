module data_mem
import memory_pkg::DATA_MEM_SIZE_BYTES;
import memory_pkg::DATA_MEM_SIZE_WORDS;
(
  input  logic        clk_i,
  input  logic        mem_req_i,
  input  logic        write_enable_i,
  input  logic [ 3:0] byte_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,
  output logic        ready_o
);

  logic [31:0] ram [DATA_MEM_SIZE_WORDS];
  logic [31:0] read_data_reg;

  localparam ADDR_BITS = $clog2(DATA_MEM_SIZE_BYTES);
  localparam WORD_ADDR_BITS = ADDR_BITS - 2;

  wire [WORD_ADDR_BITS-1:0] word_addr;
  assign word_addr = addr_i[ADDR_BITS-1:2];

  always_ff @(posedge clk_i) begin
    if (mem_req_i) begin
      if (write_enable_i) begin
        if (byte_enable_i[0]) ram[word_addr][7:0]   <= write_data_i[7:0];
        if (byte_enable_i[1]) ram[word_addr][15:8]  <= write_data_i[15:8];
        if (byte_enable_i[2]) ram[word_addr][23:16] <= write_data_i[23:16];
        if (byte_enable_i[3]) ram[word_addr][31:24] <= write_data_i[31:24];
        read_data_reg <= read_data_reg;
      end
      else begin
        read_data_reg <= ram[word_addr];
      end
    end
    else begin
      read_data_reg <= read_data_reg;
    end
  end

  assign read_data_o = read_data_reg;
  assign ready_o = 1'b1;

endmodule
