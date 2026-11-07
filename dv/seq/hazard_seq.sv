class hazard_seq extends base_seq;

  `uvm_object_utils(hazard_seq)

  function new(string name = "hazard_seq");
    super.new(name);
    n_trans = 16;
  endfunction

  task body();
    // TODO: emit load-use / RAW / control-hazard instruction streams into IMEM
    `uvm_info(get_type_name(), "hazard_seq stub — preload directed hazard program", UVM_MEDIUM)
    super.body();
  endtask

endclass
