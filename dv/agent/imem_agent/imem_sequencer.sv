class imem_sequencer extends uvm_sequencer #(imem_item);

  `uvm_component_utils(imem_sequencer)

  function new(string name = "imem_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass
