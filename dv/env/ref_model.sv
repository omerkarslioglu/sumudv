class ref_model extends uvm_component;

  `uvm_component_utils(ref_model)

  uvm_analysis_imp #(imem_item, ref_model) imem_imp;
  uvm_analysis_port #(dmem_item) expected_ap;

  // TODO: instruction-accurate golden model (then optional Spike DPI-C)
  bit [31:0] regfile [32];
  bit [31:0] pc;

  function new(string name = "ref_model", uvm_component parent = null);
    super.new(name, parent);
    imem_imp    = new("imem_imp", this);
    expected_ap = new("expected_ap", this);
  endfunction

  function void reset();
    pc = 32'h8000_0000;
    foreach (regfile[i]) regfile[i] = '0;
  endfunction

  function void write(imem_item item);
    // TODO: decode item.rdata, update pc/regfile, emit expected DMEM txn
    `uvm_info(get_type_name(),
              $sformatf("stub observe fetch @0x%08h data=0x%08h", item.addr, item.rdata),
              UVM_HIGH)
  endfunction

endclass
