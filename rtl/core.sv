`timescale 1ns/100ps

module core 
  import core_pkg::*;
(
  input                                    clk_i,
  input                                    rst_ni,
  // L1 instruction cache port
  input                  [InsXLen-1    :0] instr_i,
  output logic           [AddrLen-1    :0] instr_addr_o,
  // L1 data cache port
  input                  [   XLen-1    :0] data_i,
  output logic                             wr_data_en_o,
  output logic           [   XLen-1    :0] data_o,
  output logic           [AddrLen-1    :0] data_addr_o,
  output mem_width_t                       data_width_o // it's for stores
);

  localparam int unsigned WordByteOffset = 4;

  register_t registers;
  logic [AddrLen-1:0] pc;
  instr_t decoded_instr;
  logic decode_error;
  logic [XLen-1:0] rs1_data;
  logic [XLen-1:0] rs2_data;
  logic [XLen-1:0] alu_second_operand;
  logic [XLen-1:0] alu_result;
  logic wr_reg_en;
  logic [XLen-1:0] lsu_result;
  logic [XLen-1:0] lsu_data;

  always_comb begin
//    instr_addr_o = is_branch_taken ? decoded_instr.immediate : pc;

    rs1_data = fetch(decoded_instr.rs1);
    rs2_data = fetch(decoded_instr.rs2);

    alu_second_operand = decoded_instr.immediate_used ? decoded_instr.immediate : rs2_data;
    alu_result = execute_alu(rs1_data, alu_second_operand, decoded_instr.op);

    data_width_o = decoded_instr.memory_width;
    if (decoded_instr.memory_read) begin
      data_addr_o = rs1_data + decoded_instr.immediate;
      wr_data_en_o = 0;
    end else if (decoded_instr.memory_write) begin
      data_addr_o = rs1_data;
      wr_data_en_o = 1;
    end else begin
      data_addr_o = '0;
      wr_data_en_o = 0;
    end

    lsu_data = decoded_instr.memory_read ? rs2_data : data_i;
    lsu_result = execute_lsu(lsu_data, decoded_instr.memory_width, decoded_instr.memory_read_unsigned);
    data_o = decoded_instr.memory_write ? lsu_result : '0;
  end

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pc <= BootAddr;
      registers[0] <= '0;
    end else begin
      pc <= pc + WordByteOffset;
      if (decoded_instr.enable_wb) registers[decoded_instr.rd] <= (decoded_instr.memory_read) ? lsu_result : alu_result;
    end
  end

  decoder u_decoder (
    .instr_i(instr_i),
    .pc_i(pc),
    .instr_o(decoded_instr),
    .error_o(decode_error)
  );

  function automatic logic [31:0] fetch (register_t register);
    return register == zero ? '0 : registers[register];
  endfunction

  function automatic logic [XLen-1:0] execute_alu (logic [XLen-1:0] data_1, logic [XLen-1:0] data_2, operation_t op);
    case (op)
      ADD: return data_1 + data_2;
      SUB: return data_1 - data_2;
      SLT: return ( $signed(data_1) < $signed(data_2) ) ? 1 : 0;
      SLTU: return ( data_1 < data_2 ) ? 1 : 0;
      XOR: return data_1 ^ data_2;
      OR: return data_1 | data_2;
      AND: return data_1 & data_2;
      SL: return data_1 << data_2[4:0];
      SRL: return data_1 >> data_2[4:0];
      SRA: return $signed(data_1) >>> data_2[4:0];
      default: return '0;
    endcase 
  endfunction

  function automatic logic [XLen-1:0] execute_lsu (logic [XLen-1:0] data, mem_width_t mem_width, logic is_unsigned);
    logic [XLen-1:0] lsu_result;
    case (mem_width)
      B: begin
        if (is_unsigned)
          lsu_result = {24'b0, data[7:0]};
        else
          lsu_result = {{24{data[7]}}, data[7:0]};
      end
      H: begin
        if (is_unsigned)
          lsu_result = {16'b0, data[15:0]};
        else
          lsu_result = {{16{data[15]}}, data[15:0]};
      end
      W: begin
        lsu_result = data;
      end
      default: lsu_result = '0;
    endcase
    return lsu_result;
  endfunction

  function automatic logic is_branch_taken (operation_t op, logic [XLen-1:0] rs1_data, logic [XLen-1:0] rs2_data); // todo: branch instr will be done
    case (op)
      BEQ: return (rs1_data == rs2_data);
      BNE: return (rs1_data != rs2_data);
      BLT: return ($signed(rs1_data) < $signed(rs2_data));
      BGE: return ($signed(rs1_data) >= $signed(rs2_data));
      BLTU: return (rs1_data < rs2_data);
      BGEU: return (rs1_data >= rs2_data);
      default: return 0;
    endcase
  endfunction

  function automatic logic [AddrLen-1:0] calculate_branch_target (logic [AddrLen-1:0] pc, logic [31:0] immediate);
    return pc + immediate;
  endfunction

endmodule
