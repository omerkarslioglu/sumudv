# SUMUD-V SoC stubs

Reference interconnect / peripheral stubs for the **future** PS+DDR+HDMI path.  
The **working** bitstream top is `fpga/zybo/rtl/fpga_top.sv` (see [fpga/README.md](../fpga/README.md)).

## Memory map

| Region | Base | Cacheable |
|--------|------|-----------|
| Boot / code | `0x8000_0000` | yes |
| DMEM / heap / WAD | `0x8001_0000` | yes |
| MMIO (UART / timer / GPIO) | `0x1000_0000` | no |
| Framebuffer | `0x2000_0000` | no |

MMIO offsets (from `MMIO_BASE`): UART `+0x0000`, timer `+0x1000`, GPIO `+0x2000`, PERF `+0x3000`.

## Bring-up order

1. **PL bitstream #1 (done)** — BRAM + UART + LEDs via `fpga/zybo`  
2. **Cache-less DDR (bitstream #2)** — `fpga/zybo_ps` PS HP0 + AXI-Lite adapter + memtest  
3. **HDMI colour bars** — Digilent RGB2DVI / TMDS IP  
4. **CPU → framebuffer** — pixels at `0x2000_0000`  
5. **I$ / D$ on DDR** — enable caches; never cache MMIO/FB  
6. **DOOM** — WAD in DDR + HDMI scanout  

## Files

| File | Role |
|------|------|
| `pkg/soc_pkg.sv` | Address map helpers |
| `rtl/interconnect.sv` | Addr decode stub |
| `rtl/uart_stub.sv` | Sim UART (printf) |
| `rtl/timer_stub.sv` | mtime / mtimecmp + IRQ |
| `rtl/framebuffer.sv` | Dual-port FB BRAM model |
| `rtl/hdmi_tx_stub.sv` | Timing / RGB stub (no TMDS) |
| `rtl/soc_top.sv` | Conceptual SoC; not the bitstream top |
