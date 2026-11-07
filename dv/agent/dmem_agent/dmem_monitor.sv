class dmem_monitor extends uvm_monitor;

  `uvm_component_utils(dmem_monitor)

  virtual dmem_if.mon_mp vif;
  uvm_analysis_port #(dmem_item) ap;

  function new(string name = "dmem_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dmem_if.mon_mp)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    dmem_item item;
    forever begin
      @(vif.mon_cb);
      if (vif.rst_ni && vif.mon_cb.data_req_o && vif.mon_cb.data_gnt_i) begin
        item = dmem_item::type_id::create("item");
        item.req    = 1'b1;
        item.gnt    = vif.mon_cb.data_gnt_i;
        item.we     = vif.mon_cb.data_we_o;
        item.be     = vif.mon_cb.data_be_o;
        item.addr   = vif.mon_cb.data_addr_o;
        item.wdata  = vif.mon_cb.data_wdata_o;
        item.rvalid = vif.mon_cb.data_rvalid_i;
        item.rdata  = vif.mon_cb.data_rdata_i;
        ap.write(item);
      end
    end
  endtask

endclass
