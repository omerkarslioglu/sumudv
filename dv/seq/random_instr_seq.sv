class random_instr_seq extends base_seq;

  `uvm_object_utils(random_instr_seq)

  function new(string name = "random_instr_seq");
    super.new(name);
    n_trans = 64;
  endfunction

  task body();
    // TODO: constrained-random legal RV32IM encodings into IMEM image
    `uvm_info(get_type_name(), "random_instr_seq stub — constrained-random stream", UVM_MEDIUM)
    super.body();
  endtask

endclass
