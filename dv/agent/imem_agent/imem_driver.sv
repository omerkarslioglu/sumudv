class imem_driver extends uvm_driver #(imem_item);

  `uvm_component_utils(imem_driver)

  virtual imem_if.drv_mp vif;

  // 0-latency BRAM-style instruction memory (word-addressed by byte addr >> 2)
  bit [31:0] mem [bit [31:0]];

  function new(string name = "imem_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual imem_if.drv_mp)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface not set")
  endfunction

  function void load_word(bit [31:0] addr, bit [31:0] data);
    mem[addr] = data;
  endfunction

  task run_phase(uvm_phase phase);
    vif.drv_cb.instr_gnt_i    <= 1'b0;
    vif.drv_cb.instr_rvalid_i <= 1'b0;
    vif.drv_cb.instr_rdata_i  <= '0;

    forever begin
      @(vif.drv_cb);
      if (!vif.rst_ni) begin
        vif.drv_cb.instr_gnt_i    <= 1'b0;
        vif.drv_cb.instr_rvalid_i <= 1'b0;
        vif.drv_cb.instr_rdata_i  <= '0;
      end else if (vif.drv_cb.instr_req_o) begin
        // Combinational-style grant + same-cycle rvalid (BRAM ideal)
        vif.drv_cb.instr_gnt_i    <= 1'b1;
        vif.drv_cb.instr_rvalid_i <= 1'b1;
        if (mem.exists(vif.drv_cb.instr_addr_o))
          vif.drv_cb.instr_rdata_i <= mem[vif.drv_cb.instr_addr_o];
        else
          vif.drv_cb.instr_rdata_i <= 32'h0000_0013; // ADDI x0,x0,0 (NOP)
      end else begin
        vif.drv_cb.instr_gnt_i    <= 1'b0;
        vif.drv_cb.instr_rvalid_i <= 1'b0;
      end
    end
  endtask

endclass
