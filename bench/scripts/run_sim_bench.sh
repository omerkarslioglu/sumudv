#!/usr/bin/env bash
# Run micro-benchmark suite in simulation (placeholder skeleton).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BENCH="$ROOT/bench"
RESULTS="$BENCH/results"
CONFIG="${1:-sim-bram-ideal}"
SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo nogit)"
OUT="$RESULTS/${SHA}_${CONFIG}.json"

mkdir -p "$RESULTS"

echo "[run_sim_bench] ROOT=$ROOT CONFIG=$CONFIG"
echo "[run_sim_bench] TODO: build sw/{mem_latency,branch_torture,mul_heavy,dhrystone,coremark_eembc} + extract metrics"
echo "[run_sim_bench] TODO: extract mcycle/minstret / UART metrics into JSON"

cat >"$OUT" <<EOF
{
  "git_sha": "$SHA",
  "config": "$CONFIG",
  "fmax_mhz": 50,
  "date": "$(date -Iseconds)",
  "bp_type": "none",
  "cache": "off",
  "metrics": {
    "coremark_mhz": null,
    "dmips_mhz": null,
    "ipc": null,
    "bp_pct": null,
    "icache_hit_pct": null,
    "dcache_hit_pct": null,
    "doom_fps": "N/A"
  },
  "note": "placeholder — fill after sim harness is wired"
}
EOF

echo "[run_sim_bench] wrote $OUT"
echo "[run_sim_bench] score with: python3 $BENCH/scripts/score.py $OUT"
