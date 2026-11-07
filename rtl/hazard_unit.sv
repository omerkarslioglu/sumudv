`timescale 1ns/100ps

module hazard_unit
  import core_pkg::*;
(
  input  logic      id_rs1_used_i,
  input  logic      id_rs2_used_i,
  input  register_t id_rs1_i,
  input  register_t id_rs2_i,
  input  logic      ex_is_load_i,
  input  logic      ex_wb_i,
  input  register_t ex_rd_i,
  input  logic      imem_stall_i,
  input  logic      dmem_stall_i,
  input  logic      muldiv_stall_i,
  output logic      stall_if_o,
  output logic      stall_id_o,
  output logic      stall_ex_o,
  output logic      stall_mem_o,
  output logic      flush_id_o,
  output logic      flush_ex_o
);

  logic load_use;

  assign load_use = ex_is_load_i && ex_wb_i && ex_rd_i != zero &&
                    ((id_rs1_used_i && id_rs1_i == ex_rd_i) ||
                     (id_rs2_used_i && id_rs2_i == ex_rd_i));

  logic stall_mem_sys;
  assign stall_mem_sys = dmem_stall_i || muldiv_stall_i;

  // Freeze IF/ID on I$ miss: otherwise IF/ID is overwritten with a bubble
  // and the instruction already there is dropped (fatal once fills take
  // more than one cycle — combo 0-latency IMEM never hits this).
  assign stall_if_o  = load_use || imem_stall_i || stall_mem_sys;
  assign stall_id_o  = load_use || imem_stall_i || stall_mem_sys;
  assign stall_ex_o  = stall_mem_sys;
  assign stall_mem_o = stall_mem_sys;

  assign flush_id_o = 1'b0; // set by core on mispredict
  assign flush_ex_o = load_use; // insert bubble into EX

endmodule
