class random_test extends sumudv_base_test;

  `uvm_component_utils(random_test)

  function new(string name = "random_test", uvm_component parent = null);
    super.new(name, parent);
    timeout_ns = 50_000;
  endfunction

  task run_phase(uvm_phase phase);
    random_instr_seq seq;
    phase.raise_objection(this);
    seq = random_instr_seq::type_id::create("seq");
    seq.start(env.imem_agt.sequencer);
    #(timeout_ns);
    phase.drop_objection(this);
  endtask

endclass
