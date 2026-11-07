# SUMUD-V CoreMark port

Upstream **EEMBC CoreMark®** is a git submodule:

```text
third_party/coremark  → https://github.com/eembc/coremark
```

License: Apache-2.0 + EEMBC Acceptable Use Agreement — see `third_party/coremark/LICENSE.md`.

This directory holds only the SUMUD-V bare-metal port (`core_portme.*`, linker script, Makefile). Upstream sources (including `barebones/ee_printf.c`) are built from the submodule.

## Setup

```bash
git submodule update --init --recursive
make -C sw/coremark_eembc ITERATIONS=4
```

Do not vendor or commit CoreMark sources into this tree; keep them in the submodule.
