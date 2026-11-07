`timescale 1ns/100ps

// Pipeline smoke TB: ideal 0-latency I/D memories + directed program checks.
module tb_top
  import core_pkg::*;
();

  logic               clk_i = 1;
  logic               rst_ni;
  logic               instr_req;
  logic [AddrLen-1:0] instr_addr;
  logic               instr_gnt;
  logic               instr_rvalid;
  logic [InsXLen-1:0] instr_rdata;
  logic               data_req;
  logic               data_we;
  logic [3:0]         data_be;
  logic [AddrLen-1:0] data_addr;
  logic [XLen-1:0]    data_wdata;
  logic               data_gnt;
  logic               data_rvalid;
  logic [XLen-1:0]    data_rdata;
  logic               error;

  // Memories (word addressed from BootAddr)
  localparam int unsigned MemWords = 4096;
  logic [31:0] imem [MemWords];
  logic [31:0] dmem [MemWords];

  function automatic int unsigned imem_index(logic [31:0] addr);
    return (addr - BootAddr) >> 2;
  endfunction

  function automatic int unsigned dmem_index(logic [31:0] addr);
    return addr[13:2];
  endfunction

  // 0-latency ideal memory
  always_comb begin
    instr_gnt    = instr_req;
    instr_rvalid = instr_req;
    instr_rdata  = 32'h0000_0013; // NOP default
    if (instr_req) begin
      if (instr_addr >= BootAddr && imem_index(instr_addr) < MemWords)
        instr_rdata = imem[imem_index(instr_addr)];
    end

    data_gnt    = data_req;
    data_rvalid = data_req;
    data_rdata  = '0;
    if (data_req && !data_we) begin
      data_rdata = dmem[dmem_index(data_addr)];
    end
  end

  always_ff @(posedge clk_i) begin
    if (data_req && data_we && data_gnt) begin
      if (data_be[0]) dmem[dmem_index(data_addr)][7:0]   <= data_wdata[7:0];
      if (data_be[1]) dmem[dmem_index(data_addr)][15:8]  <= data_wdata[15:8];
      if (data_be[2]) dmem[dmem_index(data_addr)][23:16] <= data_wdata[23:16];
      if (data_be[3]) dmem[dmem_index(data_addr)][31:24] <= data_wdata[31:24];
    end
  end

  core u_core (
    .clk_i,
    .rst_ni,
    .instr_req_o   (instr_req),
    .instr_addr_o  (instr_addr),
    .instr_gnt_i   (instr_gnt),
    .instr_rvalid_i(instr_rvalid),
    .instr_rdata_i (instr_rdata),
    .data_req_o    (data_req),
    .data_we_o     (data_we),
    .data_be_o     (data_be),
    .data_addr_o   (data_addr),
    .data_wdata_o  (data_wdata),
    .data_gnt_i    (data_gnt),
    .data_rvalid_i (data_rvalid),
    .data_rdata_i  (data_rdata),
    .irq_timer_i   (1'b0),
    .irq_ext_i     (1'b0),
    .error_o       (error)
  );

  initial forever #1 clk_i = ~clk_i;

  // Encode helpers
  function automatic logic [31:0] enc_i(logic [6:0] opcode, logic [2:0] funct3,
                                       logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm);
    return {imm, rs1, funct3, rd, opcode};
  endfunction

  function automatic logic [31:0] enc_r(logic [6:0] funct7, logic [2:0] funct3,
                                       logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
    return {funct7, rs2, rs1, funct3, rd, 7'b0110011};
  endfunction

  function automatic logic [31:0] enc_u(logic [6:0] opcode, logic [4:0] rd, logic [19:0] imm20);
    return {imm20, rd, opcode};
  endfunction

  function automatic logic [31:0] enc_s(logic [2:0] funct3, logic [4:0] rs1, logic [4:0] rs2, logic [11:0] imm);
    return {imm[11:5], rs2, rs1, funct3, imm[4:0], 7'b0100011};
  endfunction

  function automatic logic [31:0] enc_b(logic [2:0] funct3, logic [4:0] rs1, logic [4:0] rs2, logic [12:0] imm);
    // imm is 13-bit branch offset (bit0 = 0)
    return {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], 7'b1100011};
  endfunction

  function automatic logic [31:0] enc_j(logic [4:0] rd, logic [20:0] imm);
    return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
  endfunction

  task automatic load_program();
    int i;
    for (i = 0; i < MemWords; i++) begin
      imem[i] = 32'h0000_0013; // NOP
      dmem[i] = '0;
    end

    // 0: LUI x1, 0xABCDE
    imem[0] = enc_u(7'b0110111, 5'd1, 20'hABCDE);
    // 1: ADDI x2, x0, 5
    imem[1] = enc_i(7'b0010011, 3'b000, 5'd2, 5'd0, 12'd5);
    // 2: ADDI x3, x2, 7   -> x3 = 12 (tests forwarding / pipeline)
    imem[2] = enc_i(7'b0010011, 3'b000, 5'd3, 5'd2, 12'd7);
    // 3: ADD  x4, x2, x3  -> x4 = 17
    imem[3] = enc_r(7'b0000000, 3'b000, 5'd4, 5'd2, 5'd3);
    // 4: SW   x4, 0(x0)   store 17 to dmem[0] — uses x0 base + 0 (addr 0)
    imem[4] = enc_s(3'b010, 5'd0, 5'd4, 12'd0);
    // 5: LW   x5, 0(x0)   -> x5 = 17 (load-use later)
    imem[5] = enc_i(7'b0000011, 3'b010, 5'd5, 5'd0, 12'd0);
    // 6: ADDI x6, x5, 1   -> x6 = 18 (load-use hazard)
    imem[6] = enc_i(7'b0010011, 3'b000, 5'd6, 5'd5, 12'd1);
    // 7: MUL  x7, x2, x3  -> 5*12 = 60
    imem[7] = enc_r(7'b0000001, 3'b000, 5'd7, 5'd2, 5'd3);
    // 8: BEQ  x2, x2, +8  (skip next) offset = 8 bytes = 2 instr
    imem[8] = enc_b(3'b000, 5'd2, 5'd2, 13'd8);
    // 9: ADDI x8, x0, 99  (should be skipped)
    imem[9] = enc_i(7'b0010011, 3'b000, 5'd8, 5'd0, 12'd99);
    // 10: ADDI x8, x0, 1  (landing)
    imem[10] = enc_i(7'b0010011, 3'b000, 5'd8, 5'd0, 12'd1);
    // 11: JAL x9, +8
    imem[11] = enc_j(5'd9, 21'd8);
    // 12: ADDI x10, x0, 77 (skipped)
    imem[12] = enc_i(7'b0010011, 3'b000, 5'd10, 5'd0, 12'd77);
    // 13: ADDI x10, x0, 2 (landing)
    imem[13] = enc_i(7'b0010011, 3'b000, 5'd10, 5'd0, 12'd2);
    // 14: AUIPC x11, 0
    imem[14] = enc_u(7'b0010111, 5'd11, 20'd0);
    // 15: ADDI x12, x0, 100
    imem[15] = enc_i(7'b0010011, 3'b000, 5'd12, 5'd0, 12'd100);
    // 16: ADDI x13, x0, 7
    imem[16] = enc_i(7'b0010011, 3'b000, 5'd13, 5'd0, 12'd7);
    // 17: DIVU x14, x12, x13 -> 14
    imem[17] = enc_r(7'b0000001, 3'b101, 5'd14, 5'd12, 5'd13);
    // 18: REMU x15, x12, x13 -> 2
    imem[18] = enc_r(7'b0000001, 3'b111, 5'd15, 5'd12, 5'd13);
    // 19: DIVU x16, x12, x0  -> 0xFFFFFFFF (div-by-zero)
    imem[19] = enc_r(7'b0000001, 3'b101, 5'd16, 5'd12, 5'd0);
    // 20: ADDI x17, x0, -20
    imem[20] = enc_i(7'b0010011, 3'b000, 5'd17, 5'd0, 12'hFEC);
    // 21: ADDI x18, x0, 3
    imem[21] = enc_i(7'b0010011, 3'b000, 5'd18, 5'd0, 12'd3);
    // 22: DIV x19, x17, x18 -> -6
    imem[22] = enc_r(7'b0000001, 3'b100, 5'd19, 5'd17, 5'd18);
    // 23: halt
    imem[23] = enc_b(3'b000, 5'd0, 5'd0, 13'd0);
  endtask

  task automatic wait_cycles(int n);
    repeat (n) @(posedge clk_i);
  endtask

  initial begin
    rst_ni = 0;
    load_program();

    wait_cycles(2);
    rst_ni = 1;

    // Let pipeline run
    wait_cycles(250);

    // Checks via debug register mirror
    assert (u_core.registers_dbg[1] == 32'hABCDE000)
      else $fatal(1, "LUI x1 failed: %h", u_core.registers_dbg[1]);
    assert (u_core.registers_dbg[2] == 32'd5)
      else $fatal(1, "ADDI x2 failed: %h", u_core.registers_dbg[2]);
    assert (u_core.registers_dbg[3] == 32'd12)
      else $fatal(1, "ADDI x3 failed: %h", u_core.registers_dbg[3]);
    assert (u_core.registers_dbg[4] == 32'd17)
      else $fatal(1, "ADD x4 failed: %h", u_core.registers_dbg[4]);
    assert (dmem[0] == 32'd17)
      else $fatal(1, "SW failed dmem[0]=%h", dmem[0]);
    assert (u_core.registers_dbg[5] == 32'd17)
      else $fatal(1, "LW x5 failed: %h", u_core.registers_dbg[5]);
    assert (u_core.registers_dbg[6] == 32'd18)
      else $fatal(1, "load-use ADDI x6 failed: %h", u_core.registers_dbg[6]);
    assert (u_core.registers_dbg[7] == 32'd60)
      else $fatal(1, "MUL x7 failed: %h", u_core.registers_dbg[7]);
    assert (u_core.registers_dbg[8] == 32'd1)
      else $fatal(1, "BEQ skip failed x8=%h", u_core.registers_dbg[8]);
    assert (u_core.registers_dbg[10] == 32'd2)
      else $fatal(1, "JAL skip failed x10=%h", u_core.registers_dbg[10]);
    assert (u_core.registers_dbg[9] != 0)
      else $fatal(1, "JAL link x9 failed");
    assert (u_core.registers_dbg[14] == 32'd14)
      else $fatal(1, "DIVU x14 failed: %h", u_core.registers_dbg[14]);
    assert (u_core.registers_dbg[15] == 32'd2)
      else $fatal(1, "REMU x15 failed: %h", u_core.registers_dbg[15]);
    assert (u_core.registers_dbg[16] == 32'hFFFF_FFFF)
      else $fatal(1, "DIVU-by-0 x16 failed: %h", u_core.registers_dbg[16]);
    assert (u_core.registers_dbg[19] == 32'hFFFF_FFFA)
      else $fatal(1, "DIV x19 failed: %h", u_core.registers_dbg[19]);

    $display("PASS: pipeline smoke tests OK");
    $finish;
  end

  // Timeout
  initial begin
    #10000;
    $fatal(1, "TIMEOUT");
  end

endmodule
