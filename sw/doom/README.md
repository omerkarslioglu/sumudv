# DOOM on SUMUD-V

Upstream **doomgeneric** is a git submodule (Chocolate Doom–derived, GPL-2.0):

```text
third_party/doomgeneric  → https://github.com/ozkl/doomgeneric
```

See `third_party/doomgeneric/LICENSE`. This directory only adds the SUMUD-V platform:

- [`doomgeneric_sumudv.c`](doomgeneric_sumudv.c) — `DG_*` hooks → UART + 320×200×8 framebuffer at `0x2000_0000`
- Build: RV32IM, `-DCMAP256`

## Setup / build

```bash
git submodule update --init --recursive
# Optional: provide an IWAD you own (e.g. shareware doom1.wad) — never commit WADs
make -C sw/doom
```

Outputs: `sw/doom/build/doomgeneric.elf` / `.bin`

Load `.bin` at `0x8000_0000`. WAD can sit in DRAM (`0x8100_0000`) once path args / stubs exist.

## Controls (UART)

| Key | Action |
|-----|--------|
| W/A/S/D | Move / turn |
| J | Fire |
| Space | Use |
| Enter | Menu OK |
| Esc | Escape |

## Notes

- Full playable DOOM needs DDR + L1 caches + HDMI scanout of `FB_BASE`.
- Without a legally obtained IWAD the binary still links; runtime will error until one is provided.
- Do not vendor doomgeneric sources or commercial IWAD files into this repository.
