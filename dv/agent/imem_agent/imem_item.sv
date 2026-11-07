class imem_item extends uvm_sequence_item;

  rand bit [31:0] addr;
  rand bit [31:0] rdata;
       bit        req;
       bit        gnt;
       bit        rvalid;

  `uvm_object_utils_begin(imem_item)
    `uvm_field_int(addr,   UVM_ALL_ON)
    `uvm_field_int(rdata,  UVM_ALL_ON)
    `uvm_field_int(req,    UVM_ALL_ON)
    `uvm_field_int(gnt,    UVM_ALL_ON)
    `uvm_field_int(rvalid, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "imem_item");
    super.new(name);
  endfunction

endclass
