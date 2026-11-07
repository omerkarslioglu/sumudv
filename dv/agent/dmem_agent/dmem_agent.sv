class dmem_agent extends uvm_agent;

  `uvm_component_utils(dmem_agent)

  dmem_driver    driver;
  dmem_monitor   monitor;
  dmem_sequencer sequencer;

  function new(string name = "dmem_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = dmem_monitor::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = dmem_driver::type_id::create("driver", this);
      sequencer = dmem_sequencer::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
