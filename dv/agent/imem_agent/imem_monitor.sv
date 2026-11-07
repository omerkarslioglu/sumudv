class imem_monitor extends uvm_monitor;

  `uvm_component_utils(imem_monitor)

  virtual imem_if.mon_mp vif;
  uvm_analysis_port #(imem_item) ap;

  function new(string name = "imem_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual imem_if.mon_mp)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    imem_item item;
    forever begin
      @(vif.mon_cb);
      if (vif.rst_ni && vif.mon_cb.instr_req_o && vif.mon_cb.instr_gnt_i) begin
        item = imem_item::type_id::create("item");
        item.req    = 1'b1;
        item.gnt    = vif.mon_cb.instr_gnt_i;
        item.addr   = vif.mon_cb.instr_addr_o;
        item.rvalid = vif.mon_cb.instr_rvalid_i;
        item.rdata  = vif.mon_cb.instr_rdata_i;
        ap.write(item);
      end
    end
  endtask

endclass
