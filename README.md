# SUMUD-V

RV32IM in-order 5-stage RISC-V core targeting Xilinx Zybo Z7-20 (HDMI / DOOM roadmap).

## Status

| Area | State |
|------|--------|
| Pipeline | 5-stage IF→ID→EX→MEM→WB, forwarding, load-use stall |
| Branch predictor | BTB + 2-bit BHT |
| M extension | Multi-cycle MUL + iterative DIV/REM |
| CSR / trap | M-mode minimum (`mstatus`, `mtvec`, `mepc`, …) |
| Cache | 32 B I$/D$ WB+WA + store buffer (sim-proven) |
| FPGA | Zybo Z7-20 PL bitstream path (`fpga/zybo`, LED+UART) |
| SoC stubs | `soc/` interconnect, UART, timer, FB, HDMI stub |
| UVM | Skeleton under `dv/` (`+UVM_TESTNAME=smoke_test`) |
| Bench | `sw/` benches + `bench/scripts` scorecard |

Full roadmap: [docs/SUMUD-V-ROADMAP.md](docs/SUMUD-V-ROADMAP.md)

## Build / simulate

```bash
cd work
make              # pipeline smoke TB
make sim-cache    # L1 caches + DDR-latency model (PASS: I$ hits/misses)
make gui
```

```bash
git submodule update --init --recursive
cd sw
make fb_demo dhrystone coremark mem_latency
make coremark_eembc   # EEMBC CoreMark
make doom
make -C ../work sim-coremark-vlt ITERATIONS=4   # Verilator CoreMark/MHz
```

```bash
# FPGA (Vivado 2025.1 + Zybo Z7-20) — see fpga/README.md
make -C fpga/zybo bitstream      # #1 PL BRAM blink
make -C fpga/zybo_ps bitstream   # #2 PS+DDR memtest
make -C fpga/zybo_ps program && make -C fpga/zybo_ps load-fw
```

Requires Vivado for FPGA, ModelSim/Questa or Verilator for sim, and `/opt/riscv` GCC.

Clone with submodules (CoreMark + doomgeneric):

```bash
git clone --recurse-submodules <repo-url>
# or: git submodule update --init --recursive
```

Third-party licenses: [THIRD_PARTY.md](THIRD_PARTY.md).

## Layout

```
rtl/          # core, core_cached, pipeline, cache, CSR, BP
pkg/ includes/
dv/           # tb_top, tb_cache, UVM skeleton
soc/          # interconnect + UART/timer/FB/HDMI stubs
sw/           # all firmware + benches (ports use third_party/)
third_party/  # git submodules (coremark, doomgeneric)
bench/        # score scripts + results JSON (no software sources)
fpga/         # Zybo bitstream flow (see fpga/README.md)
docs/         # roadmap
work/         # sim Makefiles (ModelSim / Verilator)
```

## ISA / style

- [RISC-V unprivileged spec](https://docs.riscv.org/reference/isa/_attachments/riscv-unprivileged.pdf)
- [lowRISC SystemVerilog style](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md)
