# SUMUD-V software

All bare-metal firmware and benches live here (RV32IM, `/opt/riscv` toolchain).

## Layout

| Path | Role |
|------|------|
| `common/` | crt0, linker, syscalls, `platform.h` |
| `fb_demo/` | framebuffer smoke |
| `dhrystone/` | Dhrystone |
| `coremark/` | lightweight CoreMark-like smoke (not EEMBC) |
| `coremark_eembc/` | EEMBC CoreMark port → `third_party/coremark` submodule |
| `mem_latency/` `branch_torture/` `mul_heavy/` | micro-benches |
| `doom/` | DOOM glue → `third_party/doomgeneric` submodule |

Scoring scripts / JSON: [`../bench/`](../bench/) (no duplicate `sw/` tree).

## Build

```bash
git submodule update --init --recursive

cd sw
make fb_demo dhrystone coremark mem_latency branch_torture mul_heavy
make coremark_eembc          # or: make -C coremark_eembc ITERATIONS=4
make doom
```

## Memory map

| Region | Address |
|--------|---------|
| Code / data | `0x8000_0000` |
| BSS / heap / stack | after image / DDR |
| UART / timer | `0x1000_0000` |
| Framebuffer 320×200×8 | `0x2000_0000` |

## Third-party

See [THIRD_PARTY.md](../THIRD_PARTY.md). Do not commit IWAD (`.wad`) files.
