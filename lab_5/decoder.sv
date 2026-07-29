module decoder (
  input  logic [31:0] fetched_instr_i,
  
  output logic [1:0]  a_sel_o,
  output logic [2:0]  b_sel_o,
  output logic [4:0]  alu_op_o,
  output logic [2:0]  csr_op_o,
  output logic        csr_we_o,
  output logic        gpr_we_o,
  output logic [1:0]  wb_sel_o,
  output logic [2:0]  mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic        branch_o,
  output logic        jal_o,
  output logic        jalr_o,
  output logic        illegal_instr_o,
  output logic        mret_o
);

  import alu_opcodes_pkg::*;
  import decoder_pkg::*;
  import csr_pkg::*;

  logic [1:0] opcode_2;
  logic [4:0] opcode_5;
  logic [2:0] funct3;
  logic [6:0] funct7;

  assign opcode_2 = fetched_instr_i[1:0];
  assign opcode_5 = fetched_instr_i[6:2];
  assign funct3   = fetched_instr_i[14:12];
  assign funct7   = fetched_instr_i[31:25];

  always_comb begin
    a_sel_o         = OP_A_RS1;
    b_sel_o         = OP_B_RS2;
    alu_op_o        = ALU_ADD;
    gpr_we_o        = 1'b0;
    wb_sel_o        = WB_EX_RESULT;
    mem_size_o      = 3'b0;
    mem_req_o       = 1'b0;
    mem_we_o        = 1'b0;
    branch_o        = 1'b0;
    jal_o           = 1'b0;
    jalr_o          = 1'b0;
    illegal_instr_o = 1'b0;
    csr_op_o        = 3'b000;
    csr_we_o        = 1'b0;
    mret_o          = 1'b0;

    if (opcode_2 != 2'b11) begin
      illegal_instr_o = 1'b1;
    end 
    else begin
      case (opcode_5)

        OP_OPCODE: begin
          a_sel_o  = OP_A_RS1;
          b_sel_o  = OP_B_RS2;
          wb_sel_o = WB_EX_RESULT;
          gpr_we_o = 1'b1;

          case (funct3)
            3'b000: begin
              case (funct7)
                7'b000_0000: alu_op_o = ALU_ADD;
                7'b010_0000: alu_op_o = ALU_SUB;
                default:     begin
                  illegal_instr_o = 1'b1;
                  gpr_we_o        = 1'b0;
                end
              endcase
            end

            3'b001: begin
              if (funct7 == 7'b000_0000) alu_op_o = ALU_SLL;
              else begin
                illegal_instr_o = 1'b1;
                gpr_we_o        = 1'b0;
              end
            end

            3'b010: begin
              if (funct7 == 7'b000_0000) alu_op_o = ALU_SLTS;
              else begin
                illegal_instr_o = 1'b1;
                gpr_we_o        = 1'b0;
              end
            end

            3'b011: begin
              if (funct7 == 7'b000_0000) alu_op_o = ALU_SLTU;
              else begin
                illegal_instr_o = 1'b1;
                gpr_we_o        = 1'b0;
              end
            end

            3'b100: begin
              if (funct7 == 7'b000_0000) alu_op_o = ALU_XOR;
              else begin
                illegal_instr_o = 1'b1;
                gpr_we_o        = 1'b0;
              end
            end

            3'b101: begin
              case (funct7)
                7'b000_0000: alu_op_o = ALU_SRL;
                7'b010_0000: alu_op_o = ALU_SRA;
                default:     begin
                  illegal_instr_o = 1'b1;
                  gpr_we_o        = 1'b0;
                end
              endcase
            end

            3'b110: begin
              if (funct7 == 7'b000_0000) alu_op_o = ALU_OR;
              else begin
                illegal_instr_o = 1'b1;
                gpr_we_o        = 1'b0;
              end
            end

            3'b111: begin
              if (funct7 == 7'b000_0000) alu_op_o = ALU_AND;
              else begin
                illegal_instr_o = 1'b1;
                gpr_we_o        = 1'b0;
              end
            end

            default: begin
              illegal_instr_o = 1'b1;
              gpr_we_o        = 1'b0;
            end
          endcase
        end

        OP_IMM_OPCODE: begin
          a_sel_o  = OP_A_RS1;
          b_sel_o  = OP_B_IMM_I;
          wb_sel_o = WB_EX_RESULT;
          gpr_we_o = 1'b1;

          case (funct3)
            3'b000: alu_op_o = ALU_ADD; 
            3'b010: alu_op_o = ALU_SLTS;
            3'b011: alu_op_o = ALU_SLTU;
            3'b100: alu_op_o = ALU_XOR;
            3'b110: alu_op_o = ALU_OR;
            3'b111: alu_op_o = ALU_AND;

            3'b001: begin
              if (funct7 == 7'b000_0000) alu_op_o = ALU_SLL;
              else begin
                illegal_instr_o = 1'b1;
                gpr_we_o        = 1'b0;
              end
            end

            3'b101: begin
              case (funct7)
                7'b000_0000: alu_op_o = ALU_SRL;
                7'b010_0000: alu_op_o = ALU_SRA;
                default: begin
                  illegal_instr_o = 1'b1;
                  gpr_we_o        = 1'b0;
                end
              endcase
            end

            default: begin
              illegal_instr_o = 1'b1;
              gpr_we_o        = 1'b0;
            end
          endcase
        end

        LUI_OPCODE: begin
          a_sel_o  = OP_A_ZERO;
          b_sel_o  = OP_B_IMM_U;
          alu_op_o = ALU_ADD;
          gpr_we_o = 1'b1;
          wb_sel_o = WB_EX_RESULT;
        end
        
        AUIPC_OPCODE: begin
          a_sel_o  = OP_A_CURR_PC;
          b_sel_o  = OP_B_IMM_U;
          alu_op_o = ALU_ADD;
          gpr_we_o = 1'b1;
          wb_sel_o = WB_EX_RESULT;
        end
        
        LOAD_OPCODE: begin
          a_sel_o    = OP_A_RS1;        
          b_sel_o    = OP_B_IMM_I;      
          alu_op_o   = ALU_ADD;         
          gpr_we_o   = 1'b1;            
          wb_sel_o   = WB_LSU_DATA;     
          mem_size_o = funct3;          
          mem_req_o  = 1'b1;
          mem_we_o   = 1'b0;
        end
        
        STORE_OPCODE: begin
          a_sel_o    = OP_A_RS1;        
          b_sel_o    = OP_B_IMM_S;
          alu_op_o   = ALU_ADD;         
          gpr_we_o   = 1'b0;            
          wb_sel_o   = WB_EX_RESULT;    
          mem_size_o = funct3;
          mem_req_o  = 1'b1;
          mem_we_o   = 1'b1;
        end
        
        BRANCH_OPCODE: begin
          branch_o = 1'b1;
          a_sel_o = OP_A_RS1;
          b_sel_o = OP_B_RS2;
          
          case(funct3)
            3'b000: alu_op_o = ALU_EQ;
            3'b001: alu_op_o = ALU_NE;
            3'b100: alu_op_o = ALU_LTS;
            3'b101: alu_op_o = ALU_GES;
            3'b110: alu_op_o = ALU_LTU;
            3'b111: alu_op_o = ALU_GEU;
            default: begin
              illegal_instr_o = 1'b1;
              branch_o = 1'b0;
            end
            
          endcase  
        end
        
        JAL_OPCODE: begin
          gpr_we_o = 1'b1;
          wb_sel_o = WB_EX_RESULT;
          jal_o    = 1'b1;
          a_sel_o  = OP_A_CURR_PC;
          b_sel_o  = OP_B_INCR;
          alu_op_o = ALU_ADD;
        end
        
        JALR_OPCODE: begin
          gpr_we_o = 1'b1;
          wb_sel_o = WB_EX_RESULT;
          jalr_o   = 1'b1;
          a_sel_o  = OP_A_RS1;
          b_sel_o  = OP_B_IMM_I;
          alu_op_o = ALU_ADD;
          
          if (funct3 != 3'b000) begin
            illegal_instr_o = 1'b1;
          end
        end
        
        MISC_MEM_OPCODE: begin
          if (funct3 == 3'b000 && funct7 == 7'b0000000) begin
          end
          else begin
            illegal_instr_o = 1'b1;
          end
        end
        
        SYSTEM_OPCODE: begin
          if (funct3 == 3'b000) begin
            if (fetched_instr_i == 32'b00000000000000000000000001110011) begin
              illegal_instr_o = 1'b1;
            end
            else if (fetched_instr_i == 32'b00000000000100000000000001110011) begin
              illegal_instr_o = 1'b1;
            end
            else if (fetched_instr_i == 32'b00110000001000000000000001110011) begin
              mret_o = 1'b1;
            end
            else begin
              illegal_instr_o = 1'b1;
            end
          end
          else begin
            gpr_we_o = 1'b1;
            wb_sel_o = WB_CSR_DATA;
            a_sel_o  = OP_A_RS1;
            b_sel_o  = OP_B_RS2;
            csr_we_o = 1'b1;
        
            case (funct3)
              CSR_RW:  csr_op_o = CSR_RW;
              CSR_RS:  csr_op_o = CSR_RS;
              CSR_RC:  csr_op_o = CSR_RC;
              CSR_RWI: begin
                csr_op_o = CSR_RWI;
                b_sel_o  = OP_B_IMM_I;
              end
              CSR_RSI: begin
                csr_op_o = CSR_RSI;
                b_sel_o  = OP_B_IMM_I;
              end
              CSR_RCI: begin
                csr_op_o = CSR_RCI;
                b_sel_o  = OP_B_IMM_I;
              end
              default: begin
                illegal_instr_o = 1'b1;
                gpr_we_o = 1'b0;
                csr_we_o = 1'b0;
              end
            endcase
          end
        end
              
        default: begin
          illegal_instr_o = 1'b1;
          gpr_we_o        = 1'b0;
        end

      endcase
    end

    if (illegal_instr_o) begin
      gpr_we_o  = 1'b0;
      mem_req_o = 1'b0;
      mem_we_o  = 1'b0;
      csr_we_o  = 1'b0;
      branch_o  = 1'b0;
      jal_o     = 1'b0;
      jalr_o    = 1'b0;
      mret_o    = 1'b0;
    end
  end

endmodule
