`timescale 1ns/100ps

// Simple LED GPIO at MMIO offset 0 (word).
module gpio_leds (
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

  output logic [3:0]  led_o
);

  logic [3:0] led_q;

  assign gnt_o = req_i;
  assign led_o = led_q;

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      led_q    <= 4'h0;
      rvalid_o <= 1'b0;
      rdata_o  <= '0;
    end else begin
      rvalid_o <= req_i;
      if (req_i && we_i && (addr_i[7:0] == 8'h00) && be_i[0])
        led_q <= wdata_i[3:0];
      if (req_i && !we_i)
        rdata_o <= {28'h0, led_q};
      else
        rdata_o <= '0;
    end
  end

endmodule
