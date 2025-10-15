module decoder #(
  parameter type instr_t = logic,
  parameter type operation_t = logic
)(
  input              [InsXLen-1:0] instr_i,
  output instr_t                   instr_o,
  output logic                     error_o             
);

  always_comb begin
    instr_o.op = define_op(instr_i);
    instr_o.immediate_used = (instr`opcode[4:2] == 001) ? 1 : 0;
    error_o 
  end

  function automatic operation_t define_op (logic [InsXLen-1:0] instr);
    logic [2:0] funct3 = instr`funct3;
    logic [3:0] funct7 = instr`funct7;

    case (opcode)
      OPC_LUI: return
      OPC_AUIPC: return
      OPC_JAL: return
      OPC_JALR: return
      OPC_BRANCH: return
      OPC_LOAD: return
      OPC_STORE: return
      OPC_OP_IMM: begin
        case (funct3)
          3'b000: return ADD;
          3'b010: return SLT;
          3'b011: return SLTU;
          3'b100: return XOR;
          3'b110: return OR;
          3'b111: return AND;
        endcase
      end
      OPC_OP: 
      OPC_MISC_MEM: return
      OPC_SYSTEM: return
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

endmodule