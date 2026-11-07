class sumudv_env extends uvm_env;

  `uvm_component_utils(sumudv_env)

  imem_agent  imem_agt;
  dmem_agent  dmem_agt;
  scoreboard  sb;
  instr_cg    cov;

  function new(string name = "sumudv_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imem_agt = imem_agent::type_id::create("imem_agt", this);
    dmem_agt = dmem_agent::type_id::create("dmem_agt", this);
    sb       = scoreboard::type_id::create("sb", this);
    cov      = instr_cg::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    imem_agt.monitor.ap.connect(sb.imem_imp);
    dmem_agt.monitor.ap.connect(sb.dmem_imp);
    imem_agt.monitor.ap.connect(cov.analysis_export);
  endfunction

endclass
