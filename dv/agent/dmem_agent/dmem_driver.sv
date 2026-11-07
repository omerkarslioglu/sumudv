class dmem_driver extends uvm_driver #(dmem_item);

  `uvm_component_utils(dmem_driver)

  virtual dmem_if.drv_mp vif;

  // 0-latency BRAM-style data memory
  bit [31:0] mem [bit [31:0]];

  function new(string name = "dmem_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dmem_if.drv_mp)::get(this, "", "vif", vif))
      `uvm_fatal(get_type_name(), "virtual interface not set")
  endfunction

  function void write_word(bit [31:0] addr, bit [31:0] data, bit [3:0] be);
    bit [31:0] cur;
    cur = mem.exists(addr) ? mem[addr] : 32'h0;
    if (be[0]) cur[7:0]   = data[7:0];
    if (be[1]) cur[15:8]  = data[15:8];
    if (be[2]) cur[23:16] = data[23:16];
    if (be[3]) cur[31:24] = data[31:24];
    mem[addr] = cur;
  endfunction

  task run_phase(uvm_phase phase);
    vif.drv_cb.data_gnt_i    <= 1'b0;
    vif.drv_cb.data_rvalid_i <= 1'b0;
    vif.drv_cb.data_rdata_i  <= '0;

    forever begin
      @(vif.drv_cb);
      if (!vif.rst_ni) begin
        vif.drv_cb.data_gnt_i    <= 1'b0;
        vif.drv_cb.data_rvalid_i <= 1'b0;
        vif.drv_cb.data_rdata_i  <= '0;
      end else if (vif.drv_cb.data_req_o) begin
        vif.drv_cb.data_gnt_i    <= 1'b1;
        vif.drv_cb.data_rvalid_i <= 1'b1;
        if (vif.drv_cb.data_we_o) begin
          write_word(vif.drv_cb.data_addr_o, vif.drv_cb.data_wdata_o, vif.drv_cb.data_be_o);
          vif.drv_cb.data_rdata_i <= '0;
        end else begin
          if (mem.exists(vif.drv_cb.data_addr_o))
            vif.drv_cb.data_rdata_i <= mem[vif.drv_cb.data_addr_o];
          else
            vif.drv_cb.data_rdata_i <= '0;
        end
      end else begin
        vif.drv_cb.data_gnt_i    <= 1'b0;
        vif.drv_cb.data_rvalid_i <= 1'b0;
      end
    end
  endtask

endclass
