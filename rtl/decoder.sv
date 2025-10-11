module decoder #(
  parameter type instr_t = logic,
  parameter type operation_t = logic
)(
  input              [InsXLen-1:0] instr_i,
  output instr_t                   instr_o              
);

  always_comb begin
    instr_o.op = define_op(instr_i`opcode);
  end

  function automatic operation_t define_op (logic [4:0] opcode);
    case (opcode)
      OPC_LUI: return
      OPC_AUIPC: return
      OPC_JAL: return
      OPC_JALR: return
      OPC_BRANCH: return
      OPC_LOAD: return
      OPC_STORE: return
      OPC_OP_IMM: return
      OPC_OP: return
      OPC_MISC_MEM: return
      OPC_SYSTEM: return
    endcase
  endfunction

endmodule