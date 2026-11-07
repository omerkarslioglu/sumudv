`uvm_analysis_imp_decl(_imem)
`uvm_analysis_imp_decl(_dmem)

class scoreboard extends uvm_scoreboard;

  `uvm_component_utils(scoreboard)

  uvm_analysis_imp_imem #(imem_item, scoreboard) imem_imp;
  uvm_analysis_imp_dmem #(dmem_item, scoreboard) dmem_imp;

  ref_model refm;

  int unsigned n_imem;
  int unsigned n_dmem;
  int unsigned n_mismatch;

  function new(string name = "scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imem_imp = new("imem_imp", this);
    dmem_imp = new("dmem_imp", this);
    refm     = ref_model::type_id::create("refm", this);
  endfunction

  function void write_imem(imem_item item);
    n_imem++;
    refm.write(item);
    // TODO: compare DUT-visible state vs ref_model
  endfunction

  function void write_dmem(dmem_item item);
    n_dmem++;
    // TODO: match observed DMEM against expected_ap from ref_model
    `uvm_info(get_type_name(),
              $sformatf("stub dmem %s @0x%08h", item.we ? "STORE" : "LOAD", item.addr),
              UVM_HIGH)
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("imem=%0d dmem=%0d mismatches=%0d", n_imem, n_dmem, n_mismatch),
              UVM_LOW)
  endfunction

endclass
