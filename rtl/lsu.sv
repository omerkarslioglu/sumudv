`timescale 1ns/100ps

module lsu
  import core_pkg::*;
(
  input  logic [XLen-1:0] data_i,
  input  mem_width_t      width_i,
  input  logic            unsigned_i,
  input  logic [1:0]      byte_addr_i,
  output logic [XLen-1:0] load_data_o,
  // store shaping
  input  logic [XLen-1:0] store_data_i,
  output logic [XLen-1:0] store_data_o,
  output logic [3:0]      byte_enable_o
);

  logic [XLen-1:0] shifted;

  always_comb begin
    shifted = data_i >> (8 * byte_addr_i);
    unique case (width_i)
      B: begin
        load_data_o = unsigned_i ? {24'b0, shifted[7:0]}
                                 : {{24{shifted[7]}}, shifted[7:0]};
        store_data_o = {4{store_data_i[7:0]}};
        byte_enable_o = 4'b0001 << byte_addr_i;
      end
      H: begin
        load_data_o = unsigned_i ? {16'b0, shifted[15:0]}
                                 : {{16{shifted[15]}}, shifted[15:0]};
        store_data_o = {2{store_data_i[15:0]}};
        byte_enable_o = 4'b0011 << byte_addr_i;
      end
      default: begin // W
        load_data_o   = data_i;
        store_data_o  = store_data_i;
        byte_enable_o = 4'b1111;
      end
    endcase
  end

endmodule
