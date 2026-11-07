// RISC-V opcodes
typedef enum logic [4:0] {
  OPC_LUI      = 5'b01101,
  OPC_AUIPC    = 5'b00101,
  OPC_JAL      = 5'b11011,
  OPC_JALR     = 5'b11001,
  OPC_BRANCH   = 5'b11000,
  OPC_LOAD     = 5'b00000,
  OPC_STORE    = 5'b01000,
  OPC_OP_IMM   = 5'b00100,
  OPC_OP       = 5'b01100,
  OPC_MISC_MEM = 5'b00011,
  OPC_SYSTEM   = 5'b11100
} opcode_t;

// registers
typedef enum logic [4:0] {
  zero,
  ra,
  sp,
  gp,
  tp,
  t0, t1, t2,
  fp, s1,
  a0, a1, a2, a3, a4, a5, a6, a7,
  s2, s3, s4, s5, s6, s7, s8, s9, s10, s11,
  t3, t4, t5, t6
} register_t;

// internal, decoded opcodes
typedef enum logic [5:0] {
  LUI,
  AUIPC,
  JAL,
  JALR,
  BEQ,
  BNE,
  BLT,
  BGE,
  BLTU,
  BGEU,

  LOAD,
  STORE,

  ADD,
  SUB,
  SLT,
  SLTU,
  XOR,
  OR,
  AND,
  SL,
  SRL,
  SRA,

  MUL,
  MULH,
  MULHSU,
  MULHU,
  DIV,
  DIVU,
  REM,
  REMU,

  FENCE,
  FENCE_I,

  ECALL,
  EBREAK,
  MRET,
  WFI,
  CSRRW,
  CSRRS,
  CSRRC,
  INVALID
} operation_t;

// machine mode funct12 codes
typedef enum logic [11:0] {
  F12_ECALL  = 12'b000000000000,
  F12_EBREAK = 12'b000000000001,
  F12_MRET   = 12'b001100000010,
  F12_WFI    = 12'b000100000101
} funct12_t;

// memory operation widths
typedef enum logic [1:0] {
  B = 2'b00,
  H = 2'b01,
  W = 2'b10
} mem_width_t;

// holds all the information about a decoded instruction
typedef struct packed {
  logic        valid;
  operation_t  op;
  register_t   rd;
  register_t   rs1;
  register_t   rs2;
  logic        rs1_used;
  logic        rs2_used;
  logic        rd_used;
  logic        immediate_used;
  logic [31:0] immediate;
  funct12_t    funct12;
  logic        memory_write;
  logic        memory_read;
  logic        memory_read_unsigned;
  mem_width_t  memory_width;
  logic        enable_wb;
  logic        is_branch;
  logic        is_jump;
  logic        is_csr;
  logic        is_muldiv;
  logic        is_system;
  logic [31:0] pc;
  logic [31:0] raw;
} instr_t;

// all the funct3 codes
typedef enum logic [2:0] {
  F3_ADDSUB = 3'b000,
  F3_SLT    = 3'b010,
  F3_SLTU   = 3'b011,
  F3_XOR    = 3'b100,
  F3_OR     = 3'b110,
  F3_AND    = 3'b111,
  F3_SLL    = 3'b001,
  F3_SR     = 3'b101
} funct3_op_t;

typedef enum logic [2:0] {
  F3_MUL    = 3'b000,
  F3_MULH   = 3'b001,
  F3_MULHSU = 3'b010,
  F3_MULHU  = 3'b011,
  F3_DIV    = 3'b100,
  F3_DIVU   = 3'b101,
  F3_REM    = 3'b110,
  F3_REMU   = 3'b111
} funct3_muldiv_t;

typedef enum logic [2:0] {
  F3_BEQ  = 3'b000,
  F3_BNE  = 3'b001,
  F3_BLT  = 3'b100,
  F3_BGE  = 3'b101,
  F3_BLTU = 3'b110,
  F3_BGEU = 3'b111
} funct3_branch_t;

typedef enum logic [2:0] {
  F3_LB  = 3'b000,
  F3_LH  = 3'b001,
  F3_LW  = 3'b010,
  F3_LBU = 3'b100,
  F3_LHU = 3'b101
} funct3_load_t;

typedef enum logic [2:0] {
  F3_SB  = 3'b000,
  F3_SH  = 3'b001,
  F3_SW  = 3'b010
} funct3_store_t;

typedef enum logic [2:0] {
  F3_FENCE  = 3'b000,
  F3_FENCEI = 3'b001
} funct3_misc_mem_t;

typedef enum logic [2:0] {
  F3_CSRRW  = 3'b001,
  F3_CSRRS  = 3'b010,
  F3_CSRRC  = 3'b011,
  F3_CSRRWI = 3'b101,
  F3_CSRRSI = 3'b110,
  F3_CSRRCI = 3'b111,
  F3_PRIV   = 3'b000
} funct3_system_t;

// non-immediate part of the system funct3 codes
typedef enum logic [1:0] {
  F2_PRIV  = 2'b00,
  F2_CSRRW = 2'b01,
  F2_CSRRS = 2'b10,
  F2_CSRRC = 2'b11
} funct2_system_t;

// CSR addresses
typedef enum logic [11:0] {
  CYCLE     = 12'hC00,
  TIME      = 12'hC01,
  INSTRET   = 12'hC02,
  CYCLEH    = 12'hC80,
  TIMEH     = 12'hC81,
  INSTRETH  = 12'hC82,
  MISA      = 12'h301,
  MVENDORID = 12'hF11,
  MARCHID   = 12'hF12,
  MIMPID    = 12'hF13,
  MHARTID   = 12'hF14,
  MSTATUS   = 12'h300,
  MEDELEG   = 12'h302,
  MIDELEG   = 12'h303,
  MIE       = 12'h304,
  MTVEC     = 12'h305,
  MSCRATCH  = 12'h340,
  MEPC      = 12'h341,
  MCAUSE    = 12'h342,
  MTVAL     = 12'h343,
  MIP       = 12'h344,
  MCYCLE    = 12'hB00,
  MINSTRET  = 12'hB02,
  MCYCLEH   = 12'hB80,
  MINSTRETH = 12'hB82,
  MTIMECMP  = 12'h7C1,
  MTIMECMPH = 12'h7C2,
  DCSR      = 12'h7B0,
  DPC       = 12'h7B1,
  DSCRATCH  = 12'h7B2
} csr_t;

// mstatus register (RV32 subset used by core)
typedef struct packed {
  logic       sd;
  logic [7:0] unused1;
  logic       tsr;
  logic       tw;
  logic       tvm;
  logic       mxr;
  logic       sum;
  logic       mprv;
  logic [1:0] xs;
  logic [1:0] fs;
  logic [1:0] mpp;
  logic [1:0] vs;
  logic       spp;
  logic       mpie;
  logic       ube;
  logic       spie;
  logic       unused2;
  logic       mie;
  logic       unused3;
  logic       sie;
  logic       unused4;
} mstatus_t;

typedef enum logic [31:0] {
  USI = {1'b1, 31'd0},
  SSI = {1'b1, 31'd1},
  MSI = {1'b1, 31'd3},
  UTI = {1'b1, 31'd4},
  STI = {1'b1, 31'd5},
  MTI = {1'b1, 31'd7},
  UEI = {1'b1, 31'd8},
  SEI = {1'b1, 31'd9},
  MEI = {1'b1, 31'd11},
  INSTR_MISALIGN = 32'd0,
  INSTR_FAULT    = 32'd1,
  ILLEGAL_INSTR  = 32'd2,
  BREAK          = 32'd3,
  LOAD_MISALIGN  = 32'd4,
  LOAD_FAULT     = 32'd5,
  STORE_MISALIGN = 32'd6,
  STORE_FAULT    = 32'd7,
  ECALL_U        = 32'd8,
  ECALL_S        = 32'd9,
  ECALL_M        = 32'd11
} mcause_t;

typedef struct packed {
  logic [19:0] unused;
  logic meip;
  logic unused1;
  logic seip;
  logic unused2;
  logic mtip;
  logic unused3;
  logic stip;
  logic unused4;
  logic msip;
  logic unused5;
  logic ssip;
  logic unused6;
} mip_t;

typedef struct packed {
  logic [19:0] unused;
  logic meie;
  logic unused1;
  logic seie;
  logic unused2;
  logic mtie;
  logic unused3;
  logic stie;
  logic unused4;
  logic msie;
  logic unused5;
  logic ssie;
  logic unused6;
} mie_t;

// Pipeline helper: EX result select
typedef enum logic [2:0] {
  RES_ALU,
  RES_MEM,
  RES_PC4,
  RES_IMM,
  RES_CSR,
  RES_MULDIV
} result_src_t;
