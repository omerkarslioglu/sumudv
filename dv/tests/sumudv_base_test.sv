class sumudv_base_test extends uvm_test;

  `uvm_component_utils(sumudv_base_test)

  sumudv_env env;
  int unsigned timeout_ns = 10_000;

  function new(string name = "sumudv_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sumudv_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info(get_type_name(), "sumudv_base_test running", UVM_LOW)
    #(timeout_ns);
    phase.drop_objection(this);
  endtask

endclass
