class dmem_item extends uvm_sequence_item;

  rand bit [31:0] addr;
  rand bit [31:0] wdata;
  rand bit [31:0] rdata;
  rand bit [3:0]  be;
  rand bit        we;
       bit        req;
       bit        gnt;
       bit        rvalid;

  `uvm_object_utils_begin(dmem_item)
    `uvm_field_int(addr,   UVM_ALL_ON)
    `uvm_field_int(wdata,  UVM_ALL_ON)
    `uvm_field_int(rdata,  UVM_ALL_ON)
    `uvm_field_int(be,     UVM_ALL_ON)
    `uvm_field_int(we,     UVM_ALL_ON)
    `uvm_field_int(req,    UVM_ALL_ON)
    `uvm_field_int(gnt,    UVM_ALL_ON)
    `uvm_field_int(rvalid, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "dmem_item");
    super.new(name);
  endfunction

endclass
