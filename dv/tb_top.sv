`timescale 1ns/100ps

module tb_top
  import core_pkg::*;
();

  `define opext  [1 : 0]
  `define opcode [6 : 2]
  `define rd     [11: 7]
  `define funct3 [14:12]
  `define rs1    [19:15]
  `define rs2    [24:20]
  `define funct7 [31:25]
  `define funct12 [31:20]

  typedef struct packed {
    logic [6:0] funct7;
    logic [2:0] funct3;
  } op_funct_t;

  logic clk_i = 1;
  logic rst_ni;
  logic [InsXLen-1:0] instr_i;
  logic [AddrLen-1:0] instr_addr_o;
  logic [   XLen-1:0] data_i;
  logic               wr_data_en_o;
  logic [   XLen-1:0] data_o;
  logic [AddrLen-1:0] data_addr_o;
  mem_width_t         data_width_o;

  // Verification signals
  logic [20:1] jal_imm;
  logic [11:0] s_imm;
  logic [12:1] b_imm;
  logic [2:0] load_funct3 [5];
  logic [2:0] opimm_funct3 [6];
  logic [2:0] store_funct3 [3];
  logic [2:0] branch_funct3 [6];
  op_funct_t op_functs [10];
  logic [AddrLen-1:0] pc_prev;

  core u_core (
    .clk_i (clk_i),
    .rst_ni (rst_ni),
    .instr_i (instr_i),
    .instr_addr_o (instr_addr_o),
    .data_i (data_i),
    .wr_data_en_o (wr_data_en_o),
    .data_o (data_o),
    .data_addr_o (data_addr_o),
    .data_width_o (data_width_o),
    .error_o ()
  );

  initial forever #1 clk_i = ~clk_i;

  always_ff @(posedge clk_i) begin
    pc_prev = u_core.pc;
  end

  initial begin
    rst_ni = 0;
    data_i = 'haaaa_aaaa;

    @(posedge clk_i);
    @(posedge clk_i);

    rst_ni = 1;

    // Initialize registers x1 to x31 to zero
    for (int r = 1; r < 32; r++) begin
      @(posedge clk_i);
      instr_i = '0;
      instr_i`opext   = 2'b11;
      instr_i`opcode  = OPC_OP;
      instr_i`funct7  = 7'b0000000; // ADD
      instr_i`funct3  = 3'b000;     // ADD
      instr_i`rd      = r[4:0];     // x1 .. x31
      instr_i`rs1     = 5'd0;       // x0
      instr_i`rs2     = 5'd0;       // x0
    end

    @(posedge clk_i); // LUI
    instr_i`opext   = 2'b11;
    instr_i`opcode  = OPC_LUI;
    instr_i`rd      = 5'd1; // x1
    instr_i[31:12]  = 20'h000ab;

    @(posedge clk_i); #1;
    assert (u_core.registers[instr_i`rd] == {instr_i[31:12], 12'b0}) else 
      $fatal("LUI failed! rd=%0d exp=%h got=%h", instr_i`rd, {instr_i[31:12], 12'b0}, u_core.registers[instr_i`rd]);

    @(posedge clk_i); // AUIPC
    instr_i = '0;
    instr_i`opext   = 2'b11;
    instr_i`opcode  = OPC_AUIPC;
    instr_i`rd      = $urandom_range(1,31);
    instr_i[31:12]  = $urandom;

    @(posedge clk_i); #1;
    assert (u_core.registers[instr_i`rd] == (pc_prev + {instr_i[31:12], 12'b0})) else 
      $fatal("AUIPC failed! rd=%0d exp=%h got=%h", instr_i`rd, pc_prev + {instr_i[31:12], 12'b0}, u_core.registers[instr_i`rd]);

    @(posedge clk_i); // JAL
    jal_imm = $urandom;
    instr_i = '0;
    instr_i`opext  = 2'b11;
    instr_i`opcode = OPC_JAL;
    instr_i`rd     = $urandom_range(1,31);
    instr_i[31]    = jal_imm[20];
    instr_i[30:21] = jal_imm[10:1];
    instr_i[20]    = jal_imm[11];
    instr_i[19:12] = jal_imm[19:12];

    @(posedge clk_i); #1;
    assert (u_core.registers[instr_i`rd] == (pc_prev + 32'd4)) else // rd = PC + 4
      $fatal("JAL rd failed! rd=x%0d exp=%h got=%h", instr_i`rd, (pc_prev + 32'd4), u_core.registers[instr_i`rd]);
    assert (u_core.pc == (pc_prev + {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0})) else // PC = PC + signext(imm << 1)
      $fatal("JAL PC failed! exp=%h got=%h", (pc_prev + {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0}), u_core.pc);

    @(posedge clk_i); // JALR
    instr_i = '0;
    instr_i`opext   = 2'b11;
    instr_i`opcode  = OPC_JALR;
    instr_i`funct3  = 3'b000;
    instr_i`rd      = $urandom_range(1,31);
    instr_i`rs1     = $urandom_range(0,31);
    instr_i[31:20]  = $urandom; // imm[11:0]

    @(posedge clk_i); #1;
    assert (u_core.registers[instr_i`rd] === (pc_prev + 32'd4)) else // rd = PC + 4
      $fatal("JALR rd failed! rd=x%0d exp=%0h got=%0h", instr_i`rd, (pc_prev + 32'd4), u_core.registers[instr_i`rd]);
    assert(u_core.pc === ((u_core.registers[instr_i`rs1] + {{20{instr_i[31]}}, instr_i[31:20]}) & ~32'd1)) else // PC = (rs1 + imm) & ~1
      $fatal("JALR PC failed! rs1=x%0d imm=%0h exp=%0h got=%h", {{20{instr_i[31]}}, instr_i[31:20]}, instr_i`rs1, ((u_core.registers[instr_i`rs1] + {{20{instr_i[31]}}, instr_i[31:20]}) & ~32'd1), u_core.pc); 

    load_funct3[0] = 3'b000; // LB
    load_funct3[1] = 3'b001; // LH
    load_funct3[2] = 3'b010; // LW
    load_funct3[3] = 3'b100; // LBU
    load_funct3[4] = 3'b101; // LHU
    foreach (load_funct3[i]) begin // LOAD (LB, LH, LW, LBU, LHU)
      @(posedge clk_i);
      instr_i = '0;
      instr_i`opext   = 2'b11;
      instr_i`opcode  = OPC_LOAD;
      instr_i`funct3  = load_funct3[i];
      instr_i`rd      = $urandom_range(1,31);
      instr_i`rs1     = $urandom_range(0,31);
      instr_i[31:20]  = $urandom;

      @(posedge clk_i); #1;
      assert (u_core.registers[instr_i`rd][7:0] === data_i[7:0]) else // rd written
        $fatal("LOAD rd failed! funct3=%b rd=x%0d got=%0h", instr_i`funct3, instr_i`rd, u_core.registers[instr_i`rd]);
    end

    opimm_funct3[0] = 3'b000; // ADDI
    opimm_funct3[1] = 3'b010; // SLTI
    opimm_funct3[2] = 3'b011; // SLTIU
    opimm_funct3[3] = 3'b100; // XORI
    opimm_funct3[4] = 3'b110; // ORI
    opimm_funct3[5] = 3'b111; // ANDI
    foreach (opimm_funct3[i]) begin // ADDI, SLTI, SLTIU, XORI, ORI, ANDI
      @(posedge clk_i);
      instr_i = '0;
      instr_i`opext   = 2'b11;
      instr_i`opcode  = OPC_OP_IMM;
      instr_i`funct3  = opimm_funct3[i];
      instr_i`rd      = $urandom_range(1,31);
      instr_i`rs1     = $urandom_range(0,31);
      instr_i[31:20]  = $urandom;
    end
    
    @(posedge clk_i); // SLLI
    instr_i = '0;
    instr_i`opext   = 2'b11;
    instr_i`opcode  = OPC_OP_IMM;
    instr_i`funct3  = 3'b001;
    instr_i`rd      = $urandom_range(1,31);
    instr_i`rs1     = $urandom_range(0,31);
    instr_i[24:20]  = $urandom_range(0,31);
    instr_i[31:25]  = 7'b0000000;

    @(posedge clk_i); // SRLI
    instr_i[31:25]  = 7'b0000000;

    @(posedge clk_i); // SRAI
    instr_i[31:25]  = 7'b0100000;

    store_funct3[0] = 3'b000; // SB
    store_funct3[1] = 3'b001; // SH
    store_funct3[2] = 3'b010; // SW
    s_imm = $urandom;
    foreach (store_funct3[i]) begin
      @(posedge clk_i);
      instr_i = '0;
      instr_i`opext   = 2'b11;
      instr_i`opcode  = OPC_STORE;
      instr_i`funct3  = store_funct3[i];
      instr_i`rs1     = $urandom_range(0,31);
      instr_i`rs2     = $urandom_range(0,31);
      instr_i[11:7]   = s_imm[4:0];
      instr_i[31:25]  = s_imm[11:5];
    end

    b_imm = $urandom;
    branch_funct3[0] = 3'b000; // BEQ
    branch_funct3[1] = 3'b001; // BNE
    branch_funct3[2] = 3'b100; // BLT
    branch_funct3[3] = 3'b101; // BGE
    branch_funct3[4] = 3'b110; // BLTU
    branch_funct3[5] = 3'b111; // BGEU
    foreach (branch_funct3[i]) begin
      @(posedge clk_i);
      instr_i = '0;
      instr_i`opext   = 2'b11;
      instr_i`opcode  = OPC_BRANCH;
      instr_i`funct3  = branch_funct3[i];
      instr_i`rs1     = $urandom_range(0,31);
      instr_i`rs2     = $urandom_range(0,31);
      instr_i[31]     = b_imm[12];
      instr_i[30:25]  = b_imm[10:5];
      instr_i[11:8]   = b_imm[4:1];
      instr_i[7]      = b_imm[11];
    end

    op_functs[0] = '{7'b0000000, 3'b000}; // ADD
    op_functs[1] = '{7'b0100000, 3'b000}; // SUB
    op_functs[2] = '{7'b0000000, 3'b001}; // SLL
    op_functs[3] = '{7'b0000000, 3'b010}; // SLT
    op_functs[4] = '{7'b0000000, 3'b011}; // SLTU
    op_functs[5] = '{7'b0000000, 3'b100}; // XOR
    op_functs[6] = '{7'b0000000, 3'b101}; // SRL
    op_functs[7] = '{7'b0100000, 3'b101}; // SRA
    op_functs[8] = '{7'b0000000, 3'b110}; // OR
    op_functs[9] = '{7'b0000000, 3'b111}; // AND
    foreach (op_functs[i]) begin
      @(posedge clk_i);
      instr_i = '0;
      instr_i`opext   = 2'b11;
      instr_i`opcode  = OPC_OP;
      instr_i`funct7  = op_functs[i][7:0];
      instr_i`funct3  = op_functs[i][2:0];
      instr_i`rd      = $urandom_range(1,31);
      instr_i`rs1     = $urandom_range(0,31);
      instr_i`rs2     = $urandom_range(0,31);
    end

    @(posedge clk_i); // ECALL
    instr_i = 32'h00000073;

    @(posedge clk_i); // EBREAK
    instr_i = 32'h00100073;

    instr_i = 'h0;

    #(100);
    $finish;
  end

endmodule
