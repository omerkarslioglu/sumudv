package soc_pkg;

  // Memory map (roadmap §3.1)
  localparam logic [31:0] BOOT_BASE       = 32'h8000_0000; // code — cacheable
  localparam logic [31:0] DMEM_BASE       = 32'h8001_0000; // heap / WAD — cacheable
  localparam logic [31:0] MMIO_BASE       = 32'h1000_0000; // UART/timer/GPIO — uncached
  localparam logic [31:0] FRAMEBUF_BASE   = 32'h2000_0000; // framebuffer — uncached

  localparam logic [31:0] UART_BASE       = MMIO_BASE + 32'h0000;
  localparam logic [31:0] TIMER_BASE      = MMIO_BASE + 32'h1000;
  localparam logic [31:0] GPIO_BASE       = MMIO_BASE + 32'h2000;
  localparam logic [31:0] PERF_BASE       = MMIO_BASE + 32'h3000;

  localparam int unsigned FB_WIDTH        = 320; // DOOM native; HDMI scales up
  localparam int unsigned FB_HEIGHT       = 200;
  localparam int unsigned FB_BPP          = 8;  // CMAP256

  function automatic bit is_cacheable(logic [31:0] addr);
    return (addr >= BOOT_BASE) && (addr < FRAMEBUF_BASE);
  endfunction

  function automatic bit is_mmio(logic [31:0] addr);
    return (addr >= MMIO_BASE) && (addr < FRAMEBUF_BASE);
  endfunction

  function automatic bit is_framebuffer(logic [31:0] addr);
    return (addr >= FRAMEBUF_BASE);
  endfunction

endpackage
