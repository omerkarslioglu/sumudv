`timescale 1ns/100ps

// MMIO UART TX (8N1). Compatible with platform.h UART_BASE map.
//   +0x00 DATA   (WO): push byte when STATUS.TX_READY
//   +0x04 STATUS (RO): bit0 = TX ready
module uart_tx #(
  parameter int unsigned ClkHz  = 50_000_000,
  parameter int unsigned Baud   = 115_200
) (
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic        req_i,
  input  logic        we_i,
  input  logic [3:0]  be_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,
  output logic        gnt_o,
  output logic        rvalid_o,
  output logic [31:0] rdata_o,

  output logic        uart_tx_o
);

  localparam int unsigned Div = (ClkHz + Baud/2) / Baud;

  logic        busy_q;
  logic [9:0]  shift_q;   // {stop, data[7:0], start}
  logic [3:0]  bit_q;
  logic [15:0] div_q;

  logic tx_ready;
  assign tx_ready = !busy_q;
  assign gnt_o    = req_i;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      busy_q    <= 1'b0;
      shift_q   <= '1;
      bit_q     <= '0;
      div_q     <= '0;
      uart_tx_o <= 1'b1;
      rvalid_o  <= 1'b0;
      rdata_o   <= '0;
    end else begin
      rvalid_o <= req_i;

      if (req_i && !we_i) begin
        unique case (addr_i[7:0])
          8'h00:   rdata_o <= '0;
          8'h04:   rdata_o <= {31'b0, tx_ready};
          default: rdata_o <= '0;
        endcase
      end else begin
        rdata_o <= '0;
      end

      if (req_i && we_i && (addr_i[7:0] == 8'h00) && be_i[0] && tx_ready) begin
        busy_q  <= 1'b1;
        shift_q <= {1'b1, wdata_i[7:0], 1'b0};
        bit_q   <= 4'd0;
        div_q   <= Div[15:0] - 16'd1;
      end else if (busy_q) begin
        if (div_q == '0) begin
          uart_tx_o <= shift_q[0];
          shift_q   <= {1'b1, shift_q[9:1]};
          div_q     <= Div[15:0] - 16'd1;
          if (bit_q == 4'd9)
            busy_q <= 1'b0;
          else
            bit_q <= bit_q + 4'd1;
        end else begin
          div_q <= div_q - 16'd1;
        end
      end
    end
  end

endmodule
