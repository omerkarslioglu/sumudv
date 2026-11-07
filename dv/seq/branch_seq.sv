class branch_seq extends base_seq;

  `uvm_object_utils(branch_seq)

  function new(string name = "branch_seq");
    super.new(name);
    n_trans = 32;
  endfunction

  task body();
    // TODO: directed taken/not-taken / alternating branch patterns for BP coverage
    `uvm_info(get_type_name(), "branch_seq stub — preload BP torture program", UVM_MEDIUM)
    super.body();
  endtask

endclass
