# Third-party software

Upstream projects are pulled in as **git submodules** under `third_party/`. Do not copy their sources into `sw/` or commit binary assets that you do not have rights to redistribute.

| Path | Upstream | License (see tree) | Used for |
|------|----------|--------------------|----------|
| `third_party/coremark` | [eembc/coremark](https://github.com/eembc/coremark) | Apache-2.0 + EEMBC AUA (`LICENSE.md`) | CoreMark port in `sw/coremark_eembc/` |
| `third_party/doomgeneric` | [ozkl/doomgeneric](https://github.com/ozkl/doomgeneric) | GPL-2.0 (`LICENSE`) | DOOM port glue in `sw/doom/` |

## Clone with submodules

```bash
git clone --recurse-submodules <this-repo-url>
# or later:
git submodule update --init --recursive
```

## Assets you must supply yourself

- **DOOM IWAD** (e.g. shareware `doom1.wad` or a retail IWAD you own): place outside the repo or in a local ignored path. **Never commit `.wad` / `.WAD` files.**

## SUMUD-V-owned files

Platform glue and build wrappers stay in-tree (e.g. `sw/doom/doomgeneric_sumudv.c`, `sw/coremark_eembc/core_portme.c`). CoreMark’s `barebones/ee_printf.c` is compiled from the submodule; `uart_send_char()` is implemented in `core_portme.c`.
