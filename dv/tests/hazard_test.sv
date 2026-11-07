class hazard_test extends sumudv_base_test;

  `uvm_component_utils(hazard_test)

  function new(string name = "hazard_test", uvm_component parent = null);
    super.new(name, parent);
    timeout_ns = 20_000;
  endfunction

  task run_phase(uvm_phase phase);
    hazard_seq seq;
    phase.raise_objection(this);
    seq = hazard_seq::type_id::create("seq");
    seq.start(env.imem_agt.sequencer);
    #(timeout_ns);
    phase.drop_objection(this);
  endtask

endclass
