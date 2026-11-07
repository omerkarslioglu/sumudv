# SUMUD-V Benchmark harness

**Software lives under [`sw/`](../sw/)** (apps + micro-benches). This directory only holds scoring scripts and result JSON — not a second software tree.

```
sw/                 # bare-metal apps & benches (source of truth)
bench/
  scripts/          # run_sim_bench.sh, score.py
  results/          # <git-sha>_<config>.json
  SCORECARD.md
```

## Quick start

```bash
# Build benches
make -C sw mem_latency branch_torture mul_heavy dhrystone
make -C sw/coremark_eembc ITERATIONS=4   # official CoreMark (submodule)

# Placeholder harness → stub JSON
./bench/scripts/run_sim_bench.sh sim-bram-ideal

# Score
python3 bench/scripts/score.py bench/results/<sha>_sim-bram-ideal.json

# CoreMark on Verilator (RTL, ideal BRAM)
make -C work sim-coremark-vlt ITERATIONS=4
```

## Suites (under `sw/`)

| Suite | Path | Metric |
|-------|------|--------|
| dhrystone | `sw/dhrystone/` | DMIPS/MHz |
| coremark (lite) | `sw/coremark/` | smoke |
| coremark (EEMBC) | `sw/coremark_eembc/` + `third_party/coremark` | CoreMark/MHz |
| mem_latency | `sw/mem_latency/` | cycles/access |
| branch_torture | `sw/branch_torture/` | BP% / IPC |
| mul_heavy | `sw/mul_heavy/` | cycles |
| doom | `sw/doom/` + submodule | FPS (FPGA) |

## Config labels

- `sim-bram-ideal`
- `fpga-ddr-uncached`
- `fpga-ddr-cached` ← primary comparison
- `fpga-doom`
