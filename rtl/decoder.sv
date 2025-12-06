module decoder 
  import core_pkg::*;
#(
  parameter type decoder_instr_t = logic,
  parameter type decoder_operation_t = logic
)(
  input              [InsXLen-1:0] instr_i,
  input              [AddrLen-1:0] pc_i,
  output decoder_instr_t           instr_o,
  output logic                     error_o
);
    
    `include "riscv.svh"

    always_comb begin
        instr_o = decode_instr(instr_i, pc_i);
        error_o = (instr_o.op == INVALID);
    end

    function automatic decoder_instr_t decode_instr(logic [InsXLen-1:0] instr, logic [AddrLen-1:0] pc);
        // registers, funct7 and funct3 are in the same place in every instruction type
        decode_instr.rd  = register_t'(instr`rd);
        decode_instr.rs1 = register_t'(instr`rs1);
        decode_instr.rs2 = register_t'(instr`rs2);
        decode_instr.funct12 = funct12_t'(instr`funct12);

        decode_instr.op = decode_opcode(instr);

        // we check whether a register is used for forwarding purposes -- no need to forward the zero register
        decode_instr.rs1_used = decode_instr.rs1 != zero
                             && instr`opcode != OPC_LUI
                             && instr`opcode != OPC_AUIPC
                             && instr`opcode != OPC_JAL
                             && instr`opcode != OPC_MISC_MEM;

        decode_instr.rs2_used = decode_instr.rs2 != zero
                             && (instr`opcode == OPC_BRANCH
                              || instr`opcode == OPC_STORE
                              || instr`opcode == OPC_OP);

        {decode_instr.immediate_used, decode_instr.immediate} = decode_immediate(instr);

        decode_instr.memory_write = instr`opcode == OPC_STORE;
        decode_instr.memory_read  = instr`opcode == OPC_LOAD;
        decode_instr.memory_read_unsigned = instr[14];  // if memory_read is true, this indicates an unsigned read.
        decode_instr.memory_width = mem_width_t'(instr[13:12]);

        // write back for all except s-type instructions and not to register 0
        decode_instr.enable_wb = decode_instr.rd != '0
                              && instr`opcode != OPC_BRANCH
                              && instr`opcode != OPC_STORE;

        decode_instr.pc = pc;
    endfunction

    function automatic decoder_operation_t decode_opcode(logic [31:0] instr);
        logic [11:0] funct12 = instr`funct12;
        logic [2:0]  funct3  = instr`funct3;
        logic [4:0]  rs1 = instr`rs1;
        logic legal_csr_op = validate_csr_op(rs1 != zero, csr_t'(funct12));

        // ensure the two LSBs are 1
        if (instr[1:0] != 2'b11)
            return INVALID;

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
                endcase
            OPC_LOAD:  return LOAD;
            OPC_STORE: return STORE;
            OPC_OP, OPC_OP_IMM:
                unique case (funct3)
                    // there is no SUBI instruction so also check opcode
                    F3_ADDSUB: return instr[5] && funct12[10] ? SUB : ADD;
                    F3_SLT:  return SLT;
                    F3_SLTU: return SLTU;
                    F3_XOR:  return XOR;
                    F3_OR:   return OR;
                    F3_AND:  return AND;
                    // for immediate shifts we check the 6th bit in the shift amount is 0
                    // for non-immediate shifts this value must be 0 anyway (it is the end of the funct7 code)
                    F3_SLL:  return funct12[5] ? INVALID : SL;
                    F3_SR:   return funct12[5] ? INVALID : (funct12[10] ? SRA : SRL);
                    default: return INVALID;
                endcase
            OPC_MISC_MEM: return funct3[0] ? FENCE_I : FENCE;
            OPC_SYSTEM:
                unique case (funct3[1:0])
                    // when rs1 is zero we are not writing to the CSR. This is used when checking for
                    // an illegal write to a read-only CSR.
                    F2_CSRRW: return legal_csr_op ? CSRRW : INVALID;
                    F2_CSRRS: return legal_csr_op ? CSRRS : INVALID;
                    F2_CSRRC: return legal_csr_op ? CSRRC : INVALID;
                    F2_PRIV:
                        unique case (funct12)
                            F12_ECALL:  return ECALL;
                            F12_EBREAK: return EBREAK;
`ifdef MACHINE_MODE
                            F12_MRET:   return MRET;
                            F12_WFI:    return WFI;
`endif
                            default:    return INVALID;
                        endcase
                endcase
            default: return INVALID;
        endcase
    endfunction

    function automatic logic [32:0] decode_immediate(logic [31:0] instr);
        // returns an extra top bit to indicate whether the immediate is used
        // all except u-type instructions have sign-extended immediates.
        logic [19:0] sign_ext_20 = {20{instr[31]}};
        logic [11:0] sign_ext_12 = {12{instr[31]}};
        unique case (instr`opcode)
            OPC_JALR, OPC_LOAD, OPC_OP_IMM: // i-type
                return {1'b1, sign_ext_20, instr[31:20]};
            OPC_STORE: // s-type
                return {1'b1, sign_ext_20, instr[31:25], instr[11:7]};
            OPC_BRANCH: // sb-type
                return {1'b1, sign_ext_20, instr[7], instr[30:25], instr[11:8], 1'b0};
            OPC_JAL: // uj-type
                return {1'b1, sign_ext_12, instr[19:12], instr[20], instr[30:21], 1'b0};
            OPC_LUI, OPC_AUIPC: // u-type
                return {1'b1, instr[31:12], 12'b0};
            OPC_SYSTEM: // no ordinary immediate but possibly a csr zimm (5-bit immediate)
                return {instr[14], 32'bx};
            default: // no immediate
                return {1'b0, 32'bx};
        endcase
    endfunction

    function automatic logic validate_csr_op(logic write, csr_t csr);
        // first check we aren't writing to a read-only CSR
        if (write && csr[11:10] == 2'b11)
            return '0;
        unique case (csr)
`ifdef MACHINE_MODE
            // all the CSRs we support in machine mode...
            MVENDORID, MARCHID, MIMPID, MHARTID, MEDELEG, MIDELEG,
            MISA, MTVEC, MSTATUS, MIP, MIE, MSCRATCH, MEPC, MCAUSE, MBADADDR, DSCRATCH,
            MCYCLE, MTIME, MINSTRET, MCYCLEH, MTIMEH, MINSTRETH, MTIMECMP, MTIMECMPH,
`endif
            // in user-mode only timer CSRs can be read
            CYCLE, TIME, CYCLEH, TIMEH:
                     return '1;
            default: return '0;
        endcase

    endfunction

endmodule
