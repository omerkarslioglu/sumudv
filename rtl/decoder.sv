`timescale 1ns/100ps

module decoder
  import core_pkg::*;
(
  input  logic [InsXLen-1:0] instr_i,
  input  logic [AddrLen-1:0] pc_i,
  input  logic               valid_i,
  output instr_t             instr_o,
  output logic               error_o
);

  `define opext   [1 : 0]
  `define opcode  [6 : 2]
  `define rd      [11: 7]
  `define funct3  [14:12]
  `define rs1     [19:15]
  `define rs2     [24:20]
  `define funct7  [31:25]
  `define funct12 [31:20]

  always_comb begin
    instr_o = decode_instr(instr_i, pc_i, valid_i);
    error_o = valid_i && (instr_o.op == INVALID);
  end

  function automatic instr_t decode_instr(
    logic [InsXLen-1:0] instr,
    logic [AddrLen-1:0] pc,
    logic valid
  );
    instr_t d;
    d = '0;
    d.valid = valid;
    d.raw   = instr;
    d.pc    = pc;
    d.rd    = register_t'(instr`rd);
    d.rs1   = register_t'(instr`rs1);
    d.rs2   = register_t'(instr`rs2);
    d.funct12 = funct12_t'(instr`funct12);
    d.op = decode_opcode(instr);

    d.rs1_used = d.rs1 != zero
              && instr`opcode != OPC_LUI
              && instr`opcode != OPC_AUIPC
              && instr`opcode != OPC_JAL
              && instr`opcode != OPC_MISC_MEM
              && !(instr`opcode == OPC_SYSTEM && instr[14]); // CSR*I uses zimm

    d.rs2_used = d.rs2 != zero
              && (instr`opcode == OPC_BRANCH
               || instr`opcode == OPC_STORE
               || instr`opcode == OPC_OP);

    {d.immediate_used, d.immediate} = decode_immediate(instr);

    d.memory_write = instr`opcode == OPC_STORE;
    d.memory_read  = instr`opcode == OPC_LOAD;
    d.memory_read_unsigned = instr[14];
    d.memory_width = mem_width_t'(instr[13:12]);

    d.enable_wb = d.rd != zero
               && instr`opcode != OPC_BRANCH
               && instr`opcode != OPC_STORE
               && instr`opcode != OPC_MISC_MEM
               && !(d.op inside {ECALL, EBREAK, MRET, WFI, FENCE, FENCE_I});

    d.rd_used = d.enable_wb;
    d.is_branch = instr`opcode == OPC_BRANCH;
    d.is_jump   = (d.op == JAL) || (d.op == JALR);
    d.is_csr    = d.op inside {CSRRW, CSRRS, CSRRC};
    d.is_muldiv = d.op inside {MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU};
    d.is_system = instr`opcode == OPC_SYSTEM;
    return d;
  endfunction

  function automatic operation_t decode_opcode(logic [31:0] instr);
    logic [11:0] funct12 = instr`funct12;
    logic [2:0]  funct3  = instr`funct3;
    logic [4:0]  rs1 = instr`rs1;
    logic legal_csr_op = validate_csr_op(rs1 != zero || funct3[1:0] == F2_CSRRW, csr_t'(funct12));

    if (instr[1:0] != 2'b11) return INVALID;

    unique case (instr`opcode)
      OPC_LUI:   return LUI;
      OPC_AUIPC: return AUIPC;
      OPC_JAL:   return JAL;
      OPC_JALR:  return JALR;
      OPC_BRANCH:
        unique case (funct3)
          F3_BEQ:  return BEQ;
          F3_BNE:  return BNE;
          F3_BLT:  return BLT;
          F3_BLTU: return BLTU;
          F3_BGE:  return BGE;
          F3_BGEU: return BGEU;
          default: return INVALID;
        endcase
      OPC_LOAD:  return LOAD;
      OPC_STORE: return STORE;
      OPC_OP_IMM:
        unique case (funct3)
          F3_ADDSUB: return ADD;
          F3_SLT:  return SLT;
          F3_SLTU: return SLTU;
          F3_XOR:  return XOR;
          F3_OR:   return OR;
          F3_AND:  return AND;
          F3_SLL:  return funct12[5] ? INVALID : SL;
          F3_SR:   return funct12[5] ? INVALID : (funct12[10] ? SRA : SRL);
          default: return INVALID;
        endcase
      OPC_OP:
        if (instr`funct7 == 7'b0000001) begin
          unique case (funct3)
            F3_MUL:    return MUL;
            F3_MULH:   return MULH;
            F3_MULHSU: return MULHSU;
            F3_MULHU:  return MULHU;
            F3_DIV:    return DIV;
            F3_DIVU:   return DIVU;
            F3_REM:    return REM;
            F3_REMU:   return REMU;
            default:   return INVALID;
          endcase
        end else begin
          // R-type: validate funct7 — do NOT use funct12[5] (that bit is rs2[0]!)
          unique case (funct3)
            F3_ADDSUB: return (instr`funct7 == 7'b0000000) ? ADD :
                              (instr`funct7 == 7'b0100000) ? SUB : INVALID;
            F3_SLT:  return (instr`funct7 == 7'b0000000) ? SLT  : INVALID;
            F3_SLTU: return (instr`funct7 == 7'b0000000) ? SLTU : INVALID;
            F3_XOR:  return (instr`funct7 == 7'b0000000) ? XOR  : INVALID;
            F3_OR:   return (instr`funct7 == 7'b0000000) ? OR   : INVALID;
            F3_AND:  return (instr`funct7 == 7'b0000000) ? AND  : INVALID;
            F3_SLL:  return (instr`funct7 == 7'b0000000) ? SL   : INVALID;
            F3_SR:   return (instr`funct7 == 7'b0000000) ? SRL  :
                            (instr`funct7 == 7'b0100000) ? SRA  : INVALID;
            default: return INVALID;
          endcase
        end
      OPC_MISC_MEM: return funct3[0] ? FENCE_I : FENCE;
      OPC_SYSTEM:
        unique case (funct3[1:0])
          F2_CSRRW: return legal_csr_op ? CSRRW : INVALID;
          F2_CSRRS: return legal_csr_op ? CSRRS : INVALID;
          F2_CSRRC: return legal_csr_op ? CSRRC : INVALID;
          F2_PRIV:
            unique case (funct12)
              F12_ECALL:  return ECALL;
              F12_EBREAK: return EBREAK;
              F12_MRET:   return MRET;
              F12_WFI:    return WFI;
              default:    return INVALID;
            endcase
          default: return INVALID;
        endcase
      default: return INVALID;
    endcase
  endfunction

  function automatic logic [32:0] decode_immediate(logic [31:0] instr);
    logic [19:0] sign_ext_20 = {20{instr[31]}};
    logic [11:0] sign_ext_12 = {12{instr[31]}};
    unique case (instr`opcode)
      OPC_JALR, OPC_LOAD, OPC_OP_IMM:
        return {1'b1, sign_ext_20, instr[31:20]};
      OPC_STORE:
        return {1'b1, sign_ext_20, instr[31:25], instr[11:7]};
      OPC_BRANCH:
        return {1'b1, sign_ext_20, instr[7], instr[30:25], instr[11:8], 1'b0};
      OPC_JAL:
        return {1'b1, sign_ext_12, instr[19:12], instr[20], instr[30:21], 1'b0};
      OPC_LUI, OPC_AUIPC:
        return {1'b1, instr[31:12], 12'b0};
      OPC_SYSTEM:
        return {instr[14], 27'b0, instr[19:15]};
      default:
        return {1'b0, 32'b0};
    endcase
  endfunction

  function automatic logic validate_csr_op(logic write, csr_t csr);
    if (write && csr[11:10] == 2'b11) return 1'b0;
    unique case (csr)
      MVENDORID, MARCHID, MIMPID, MHARTID,
      MISA, MTVEC, MSTATUS, MIP, MIE, MSCRATCH, MEPC, MCAUSE, MTVAL,
      MCYCLE, MINSTRET, MCYCLEH, MINSTRETH, MTIMECMP, MTIMECMPH,
      CYCLE, TIME, CYCLEH, TIMEH, INSTRET, INSTRETH:
        return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

endmodule
