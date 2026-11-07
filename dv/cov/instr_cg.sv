class instr_cg extends uvm_subscriber #(imem_item);

  `uvm_component_utils(instr_cg)

  bit [6:0] opcode;
  bit [2:0] funct3;
  bit [6:0] funct7;

  covergroup cg_instr;
    option.per_instance = 1;

    cp_opcode: coverpoint opcode {
      bins lui    = {7'b0110111};
      bins auipc  = {7'b0010111};
      bins jal    = {7'b1101111};
      bins jalr   = {7'b1100111};
      bins branch = {7'b1100011};
      bins load   = {7'b0000011};
      bins store  = {7'b0100011};
      bins opimm  = {7'b0010011};
      bins op     = {7'b0110011};
      bins system = {7'b1110011};
    }

    cp_funct3: coverpoint funct3;

    cx_op_f3: cross cp_opcode, cp_funct3;
  endgroup

  function new(string name = "instr_cg", uvm_component parent = null);
    super.new(name, parent);
    cg_instr = new();
  endfunction

  function void write(imem_item t);
    opcode = t.rdata[6:0];
    funct3 = t.rdata[14:12];
    funct7 = t.rdata[31:25];
    cg_instr.sample();
  endfunction

endclass
