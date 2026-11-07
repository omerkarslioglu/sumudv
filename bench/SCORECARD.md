# SUMUD-V Scorecard

Template — fill after `scripts/run_sim_bench.sh` / FPGA runs. Primary comparison row: **fpga-ddr-cached**.

## Current snapshot

| Config | Score | IPC | CM/MHz | DMIPS/MHz | I$hit | D$hit | BP% | DOOM FPS |
|--------|------:|----:|-------:|----------:|------:|------:|----:|---------:|
| sim-bram-ideal | — | — | — | — | — | — | — | N/A |
| fpga-ddr-uncached | — | — | — | — | — | — | — | N/A |
| fpga-ddr-cached | — | — | — | — | — | — | — | N/A |
| fpga-doom | — | — | — | — | — | — | — | — |

## A/B deltas

| Config | Score | IPC | CM/MHz | I$hit | D$hit | BP% | DOOM FPS |
|--------|------:|----:|-------:|------:|------:|----:|---------:|
| baseline (no BP) | — | — | — | — | — | — | — |
| +BTB/2bit | — | — | — | — | — | — | — |
| +I$/D$ | — | — | — | — | — | — | — |

## Score model

```
component = min(100, 100 * measured / target)
SUMUD_V_Score = Σ (weight_i * component_i)
```

| Component | Weight | Target |
|-----------|-------:|-------:|
| CoreMark/MHz | 25% | 2.5 |
| DMIPS/MHz | 15% | 1.0 |
| IPC | 15% | 0.7 |
| BP% | 10% | 90 |
| I$ hit | 10% | 95 |
| D$ hit | 10% | 90 |
| DOOM FPS | 15% | 15 |

Missing / N/A metrics redistribute weight to remaining components (`scripts/score.py`).

## Metadata checklist

Each `results/<sha>_<config>.json` should include: git SHA, fmax (MHz), cache on/off, BP type, toolchain flags, date.
