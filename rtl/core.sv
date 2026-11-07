`timescale 1ns/100ps

module core
  import core_pkg::*;
(
  input  logic               clk_i,
  input  logic               rst_ni,

  output logic               instr_req_o,
  output logic [AddrLen-1:0] instr_addr_o,
  input  logic               instr_gnt_i,
  input  logic               instr_rvalid_i,
  input  logic [InsXLen-1:0] instr_rdata_i,

  output logic               data_req_o,
  output logic               data_we_o,
  output logic [3:0]         data_be_o,
  output logic [AddrLen-1:0] data_addr_o,
  output logic [XLen-1:0]    data_wdata_o,
  input  logic               data_gnt_i,
  input  logic               data_rvalid_i,
  input  logic [XLen-1:0]    data_rdata_i,

  input  logic               irq_timer_i,
  input  logic               irq_ext_i,

  output logic               error_o
);

  // Debug/hierarchical TB access
  logic [AddrLen-1:0] pc;
  logic [31:0]        registers_dbg [32];

  localparam int unsigned WordBytes = 4;

  // Pipe control
  logic stall_if, stall_id, stall_ex, stall_mem;
  logic flush_if_id, flush_id_ex;
  logic redirect;
  logic [AddrLen-1:0] redirect_pc;

  logic imem_stall, dmem_stall;
  logic bp_taken;
  logic [AddrLen-1:0] bp_target;
  logic [31:0] bp_lookups, bp_correct;
  logic        ex_taken;
  logic [31:0] ex_target;

  // -------------------------------------------------------------------------
  // Pipeline registers (declared early for cross-stage refs)
  // -------------------------------------------------------------------------
  logic        if_id_valid;
  logic [31:0] if_id_instr;
  logic [31:0] if_id_pc;
  logic        if_id_pred_taken;
  logic [31:0] if_id_pred_target;

  logic        id_ex_valid;
  instr_t      id_ex_instr;
  logic [31:0] id_ex_rs1, id_ex_rs2;
  logic        id_ex_pred_taken;
  logic [31:0] id_ex_pred_target;

  logic        ex_mem_valid;
  instr_t      ex_mem_instr;
  logic [31:0] ex_mem_result, ex_mem_rs2, ex_mem_addr, ex_mem_pc4;

  logic        mem_wb_valid;
  instr_t      mem_wb_instr;
  logic [31:0] mem_wb_data;

  // -------------------------------------------------------------------------
  // IF
  // -------------------------------------------------------------------------
  logic [AddrLen-1:0] pc_q;

  assign instr_req_o  = rst_ni;
  assign instr_addr_o = pc_q;
  assign imem_stall   = instr_req_o && !(instr_gnt_i && instr_rvalid_i);

  always_comb begin
    if (redirect) begin
      // handled in FF
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pc_q <= BootAddr;
    end else if (redirect) begin
      pc_q <= redirect_pc;
    end else if (!stall_if) begin
      pc_q <= bp_taken ? bp_target : (pc_q + WordBytes);
    end
  end

  assign pc = pc_q;

  branch_predictor u_bp (
    .clk_i,
    .rst_ni,
    .pc_i                (pc_q),
    .instr_i             (instr_rdata_i),
    .instr_valid_i       (instr_gnt_i && instr_rvalid_i),
    .predict_taken_o     (bp_taken),
    .predict_target_o    (bp_target),
    .resolve_i           (id_ex_valid && (id_ex_instr.is_branch || id_ex_instr.is_jump || id_ex_instr.op == MRET)),
    .resolve_is_branch_i (id_ex_instr.is_branch),
    .resolve_is_jump_i   (id_ex_instr.is_jump),
    .resolve_taken_i     (ex_taken),
    .resolve_pc_i        (id_ex_instr.pc),
    .resolve_target_i    (ex_target),
    .resolve_rd_i        (id_ex_instr.rd),
    .resolve_rs1_i       (id_ex_instr.rs1),
    .bp_lookups_o        (bp_lookups),
    .bp_correct_o        (bp_correct)
  );

  always_ff @(posedge clk_i) begin
    if (!rst_ni || flush_if_id) begin
      if_id_valid       <= 1'b0;
      if_id_instr       <= 32'h0000_0013; // NOP ADDI x0,x0,0
      if_id_pc          <= '0;
      if_id_pred_taken  <= 1'b0;
      if_id_pred_target <= '0;
    end else if (!stall_id) begin
      if_id_valid       <= instr_gnt_i && instr_rvalid_i;
      if_id_instr       <= instr_rdata_i;
      if_id_pc          <= pc_q;
      if_id_pred_taken  <= bp_taken;
      if_id_pred_target <= bp_target;
    end
  end

  // -------------------------------------------------------------------------
  // ID
  // -------------------------------------------------------------------------
  instr_t id_dec;
  logic   id_err;

  decoder u_decoder (
    .instr_i (if_id_instr),
    .pc_i    (if_id_pc),
    .valid_i (if_id_valid),
    .instr_o (id_dec),
    .error_o (id_err)
  );

  logic [31:0] rf_ra, rf_rb;
  logic        rf_we;
  register_t   rf_wa;
  logic [31:0] rf_wd;

  regfile u_rf (
    .clk_i,
    .rst_ni,
    .raddr_a_i (id_dec.rs1),
    .raddr_b_i (id_dec.rs2),
    .rdata_a_o (rf_ra),
    .rdata_b_o (rf_rb),
    .we_i      (rf_we),
    .waddr_i   (rf_wa),
    .wdata_i   (rf_wd)
  );

  // Expose RF for legacy TB hierarchical peek via bind-like mirror
  // (regfile internals not visible — provide WB mirror only)
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      for (int i = 0; i < 32; i++) registers_dbg[i] <= '0;
    end else if (rf_we && rf_wa != zero) begin
      registers_dbg[rf_wa] <= rf_wd;
    end
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni || flush_id_ex) begin
      id_ex_valid       <= 1'b0;
      id_ex_instr       <= '0;
      id_ex_rs1         <= '0;
      id_ex_rs2         <= '0;
      id_ex_pred_taken  <= 1'b0;
      id_ex_pred_target <= '0;
    end else if (!stall_ex) begin
      // On redirect, IF/ID holds a wrong-path insn for this edge — squash it
      // so it cannot enter EX and commit (e.g. a second `addi sp, -N`).
      if (stall_id || flush_if_id) begin
        id_ex_valid <= 1'b0;
        id_ex_instr <= '0;
      end else begin
        id_ex_valid       <= if_id_valid;
        id_ex_instr       <= id_dec;
        id_ex_rs1         <= rf_ra;
        id_ex_rs2         <= rf_rb;
        id_ex_pred_taken  <= if_id_pred_taken;
        id_ex_pred_target <= if_id_pred_target;
      end
    end
  end

  // -------------------------------------------------------------------------
  // EX
  // -------------------------------------------------------------------------
  logic [1:0] fwd_a, fwd_b;
  logic [31:0] op_a, op_b, alu_b, alu_y, mul_y, ex_result, ex_addr;
  logic [31:0] ex_pc4;
  logic [31:0] csr_rdata, csr_mtvec, csr_mepc;
  logic        csr_illegal, irq_pending;

  logic [31:0] fwd_exmem, fwd_memwb;
  assign fwd_exmem = ex_mem_result;
  assign fwd_memwb = mem_wb_data;

  forward_unit u_fwd (
    .rs1_i       (id_ex_instr.rs1),
    .rs2_i       (id_ex_instr.rs2),
    .rs1_used_i  (id_ex_instr.rs1_used),
    .rs2_used_i  (id_ex_instr.rs2_used),
    .ex_mem_wb_i (ex_mem_valid && ex_mem_instr.enable_wb && !ex_mem_instr.memory_read),
    .ex_mem_rd_i (ex_mem_instr.rd),
    .mem_wb_wb_i (mem_wb_valid && mem_wb_instr.enable_wb),
    .mem_wb_rd_i (mem_wb_instr.rd),
    .forward_a_o (fwd_a),
    .forward_b_o (fwd_b)
  );

  always_comb begin
    unique case (fwd_a)
      2'b10:   op_a = fwd_exmem;
      2'b01:   op_a = fwd_memwb;
      default: op_a = id_ex_rs1;
    endcase
    unique case (fwd_b)
      2'b10:   op_b = fwd_exmem;
      2'b01:   op_b = fwd_memwb;
      default: op_b = id_ex_rs2;
    endcase
  end

  assign alu_b = id_ex_instr.immediate_used ? id_ex_instr.immediate : op_b;

  alu u_alu (
    .op_a_i   (op_a),
    .op_b_i   (alu_b),
    .op_i     (id_ex_instr.op),
    .result_o (alu_y)
  );

  logic mul_ready, mul_valid;
  logic muldiv_stall;
  muldiv u_muldiv (
    .clk_i,
    .rst_ni,
    .valid_i  (id_ex_valid && id_ex_instr.is_muldiv),
    .op_i     (id_ex_instr.op),
    .op_a_i   (op_a),
    .op_b_i   (op_b),
    .ready_o  (mul_ready),
    .valid_o  (mul_valid),
    .result_o (mul_y)
  );
  assign muldiv_stall = id_ex_valid && id_ex_instr.is_muldiv && !mul_ready;

  assign ex_pc4  = id_ex_instr.pc + WordBytes;
  assign ex_addr = op_a + id_ex_instr.immediate;

  always_comb begin
    ex_taken  = 1'b0;
    ex_target = ex_pc4;
    if (id_ex_valid) begin
      if (id_ex_instr.is_branch) begin
        unique case (id_ex_instr.op)
          BEQ:  ex_taken = (op_a == op_b);
          BNE:  ex_taken = (op_a != op_b);
          BLT:  ex_taken = ($signed(op_a) <  $signed(op_b));
          BGE:  ex_taken = ($signed(op_a) >= $signed(op_b));
          BLTU: ex_taken = (op_a <  op_b);
          BGEU: ex_taken = (op_a >= op_b);
          default: ex_taken = 1'b0;
        endcase
        ex_target = ex_taken ? (id_ex_instr.pc + id_ex_instr.immediate) : ex_pc4;
      end else if (id_ex_instr.op == JAL) begin
        ex_taken  = 1'b1;
        ex_target = id_ex_instr.pc + id_ex_instr.immediate;
      end else if (id_ex_instr.op == JALR) begin
        ex_taken  = 1'b1;
        ex_target = (op_a + id_ex_instr.immediate) & ~32'd1;
      end else if (id_ex_instr.op == MRET) begin
        ex_taken  = 1'b1;
        ex_target = csr_mepc;
      end
    end
  end

  logic do_trap, do_mret;
  logic [31:0] trap_cause;
  assign do_mret = id_ex_valid && (id_ex_instr.op == MRET);
  assign do_trap = id_ex_valid && (id_ex_instr.op inside {ECALL, EBREAK});
  always_comb begin
    trap_cause = ILLEGAL_INSTR;
    if (id_ex_instr.op == ECALL)  trap_cause = ECALL_M;
    if (id_ex_instr.op == EBREAK) trap_cause = BREAK;
  end

  csr_file u_csr (
    .clk_i,
    .rst_ni,
    .csr_access_i  (id_ex_valid && id_ex_instr.is_csr),
    .csr_op_i      (id_ex_instr.op),
    .csr_addr_i    (id_ex_instr.raw[31:20]),
    .csr_wdata_i   (id_ex_instr.raw[14] ? id_ex_instr.immediate : op_a),
    .csr_rdata_o   (csr_rdata),
    .csr_illegal_o (csr_illegal),
    .trap_i        (do_trap),
    .trap_cause_i  (trap_cause),
    .trap_pc_i     (id_ex_instr.pc),
    .trap_val_i    (id_ex_instr.raw),
    .mret_i        (do_mret),
    .mtvec_o       (csr_mtvec),
    .mepc_o        (csr_mepc),
    .retire_i      (mem_wb_valid),
    .irq_timer_i,
    .irq_ext_i,
    .irq_pending_o (irq_pending)
  );

  always_comb begin
    unique case (1'b1)
      (id_ex_instr.op == LUI):   ex_result = id_ex_instr.immediate;
      (id_ex_instr.op == AUIPC): ex_result = id_ex_instr.pc + id_ex_instr.immediate;
      id_ex_instr.is_jump:       ex_result = ex_pc4;
      id_ex_instr.is_csr:        ex_result = csr_rdata;
      id_ex_instr.is_muldiv:     ex_result = mul_y;
      default:                   ex_result = alu_y;
    endcase
  end

  // Redirect / flush
  always_comb begin
    redirect     = 1'b0;
    redirect_pc  = ex_target;
    flush_if_id  = 1'b0;
    if (do_trap) begin
      redirect    = 1'b1;
      redirect_pc = csr_mtvec;
      flush_if_id = 1'b1;
    end else if (do_mret) begin
      redirect    = 1'b1;
      redirect_pc = csr_mepc;
      flush_if_id = 1'b1;
    end else if (id_ex_valid && (id_ex_instr.is_branch || id_ex_instr.is_jump)) begin
      if (id_ex_pred_taken != ex_taken ||
          (ex_taken && id_ex_pred_target != ex_target)) begin
        redirect    = 1'b1;
        redirect_pc = ex_target;
        flush_if_id = 1'b1;
      end
    end
  end

  // On redirect flush only IF/ID. ID/EX keeps the resolving branch/jump.
  assign flush_id_ex = 1'b0;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      ex_mem_valid  <= 1'b0;
      ex_mem_instr  <= '0;
      ex_mem_result <= '0;
      ex_mem_rs2    <= '0;
      ex_mem_addr   <= '0;
      ex_mem_pc4    <= '0;
    end else if (!stall_mem) begin
      ex_mem_valid  <= id_ex_valid;
      ex_mem_instr  <= id_ex_instr;
      ex_mem_result <= ex_result;
      ex_mem_rs2    <= op_b;
      ex_mem_addr   <= (id_ex_instr.memory_read || id_ex_instr.memory_write) ? ex_addr : ex_result;
      ex_mem_pc4    <= ex_pc4;
    end
  end

  // -------------------------------------------------------------------------
  // MEM
  // -------------------------------------------------------------------------
  logic [31:0] lsu_load, lsu_store;
  logic [3:0]  lsu_be;

  lsu u_lsu (
    .data_i        (data_rdata_i),
    .width_i       (ex_mem_instr.memory_width),
    .unsigned_i    (ex_mem_instr.memory_read_unsigned),
    .byte_addr_i   (ex_mem_addr[1:0]),
    .load_data_o   (lsu_load),
    .store_data_i  (ex_mem_rs2),
    .store_data_o  (lsu_store),
    .byte_enable_o (lsu_be)
  );

  assign data_req_o   = ex_mem_valid && (ex_mem_instr.memory_read || ex_mem_instr.memory_write);
  assign data_we_o    = ex_mem_instr.memory_write;
  assign data_be_o    = lsu_be;
  assign data_addr_o  = ex_mem_addr;
  assign data_wdata_o = lsu_store;
  assign dmem_stall   = data_req_o && !(data_gnt_i && data_rvalid_i);

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      mem_wb_valid <= 1'b0;
      mem_wb_instr <= '0;
      mem_wb_data  <= '0;
    end else if (!stall_mem) begin
      mem_wb_valid <= ex_mem_valid;
      mem_wb_instr <= ex_mem_instr;
      mem_wb_data  <= ex_mem_instr.memory_read ? lsu_load : ex_mem_result;
    end
  end

  // -------------------------------------------------------------------------
  // WB
  // -------------------------------------------------------------------------
  assign rf_we = mem_wb_valid && mem_wb_instr.enable_wb;
  assign rf_wa = mem_wb_instr.rd;
  assign rf_wd = mem_wb_data;

  // -------------------------------------------------------------------------
  // Hazard
  // -------------------------------------------------------------------------
  logic flush_ex_bubble;
  hazard_unit u_hz (
    .id_rs1_used_i  (id_dec.rs1_used && if_id_valid),
    .id_rs2_used_i  (id_dec.rs2_used && if_id_valid),
    .id_rs1_i       (id_dec.rs1),
    .id_rs2_i       (id_dec.rs2),
    .ex_is_load_i   (id_ex_valid && id_ex_instr.memory_read),
    .ex_wb_i        (id_ex_valid && id_ex_instr.enable_wb),
    .ex_rd_i        (id_ex_instr.rd),
    .imem_stall_i   (imem_stall),
    .dmem_stall_i   (dmem_stall),
    .muldiv_stall_i (muldiv_stall),
    .stall_if_o     (stall_if),
    .stall_id_o     (stall_id),
    .stall_ex_o     (stall_ex),
    .stall_mem_o    (stall_mem),
    .flush_id_o     (),
    .flush_ex_o     (flush_ex_bubble)
  );

  // load-use: stall ID and squash EX incoming (already via stall_id clearing id_ex)

  always_ff @(posedge clk_i) begin
    if (!rst_ni) error_o <= 1'b0;
    else error_o <= id_err || csr_illegal;
  end

  logic _unused;
  assign _unused = |bp_lookups | |bp_correct | irq_pending | flush_ex_bubble | |ex_mem_pc4 | mul_valid;

endmodule
