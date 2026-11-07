class base_seq extends uvm_sequence #(imem_item);

  `uvm_object_utils(base_seq)

  int unsigned n_trans = 8;

  function new(string name = "base_seq");
    super.new(name);
  endfunction

  // IMEM driver is a slave mem model; sequences primarily preload / coordinate.
  // Placeholder body keeps the sequencer path live for educational scaffolding.
  task body();
    imem_item item;
    repeat (n_trans) begin
      item = imem_item::type_id::create("item");
      start_item(item);
      if (!item.randomize())
        `uvm_error(get_type_name(), "randomize failed")
      finish_item(item);
    end
  endtask

endclass
