`timescale 1ns/100ps

// Minimal UART TX stub: writes to DATA are accepted; STATUS always ready.
module uart_stub (
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic        req_i,
  input  logic        we_i,
  input  logic [3:0]  be_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] wdata_i,
  output logic        gnt_o,
  output logic        rvalid_o,
  output logic [31:0] rdata_o
);

  localparam logic [31:0] REG_DATA   = 32'h0;
  localparam logic [31:0] REG_STATUS = 32'h4;

  logic [7:0] last_tx;

  assign gnt_o = req_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rvalid_o <= 1'b0;
      rdata_o  <= '0;
      last_tx  <= '0;
    end else begin
      rvalid_o <= req_i;
      if (req_i && we_i && (addr_i[7:0] == REG_DATA[7:0]) && be_i[0]) begin
        last_tx <= wdata_i[7:0];
        // synthesis translate_off
        $write("%c", wdata_i[7:0]);
        // synthesis translate_on
      end
      if (req_i && !we_i) begin
        unique case (addr_i[7:0])
          REG_DATA[7:0]:   rdata_o <= {24'h0, last_tx};
          REG_STATUS[7:0]: rdata_o <= 32'h1; // TX ready
          default:         rdata_o <= '0;
        endcase
      end else begin
        rdata_o <= '0;
      end
    end
  end

endmodule
