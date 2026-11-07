#!/usr/bin/env python3
"""SUMUD-V Score (0–100) from a metrics JSON file.

component_i = min(100, 100 * measured_i / target_i)
score       = sum(weight_i * component_i)

If doom_fps is null / missing / \"N/A\", that weight is redistributed
proportionally across the remaining components.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

WEIGHTS = {
    "coremark_mhz": 0.25,
    "dmips_mhz": 0.15,
    "ipc": 0.15,
    "bp_pct": 0.10,
    "icache_hit_pct": 0.10,
    "dcache_hit_pct": 0.10,
    "doom_fps": 0.15,
}

TARGETS = {
    "coremark_mhz": 2.5,
    "dmips_mhz": 1.0,
    "ipc": 0.7,
    "bp_pct": 90.0,
    "icache_hit_pct": 95.0,
    "dcache_hit_pct": 90.0,
    "doom_fps": 15.0,
}

# Accept common aliases from result JSON keys
ALIASES = {
    "coremark_mhz": ("coremark_mhz", "cm_mhz", "CoreMark/MHz"),
    "dmips_mhz": ("dmips_mhz", "DMIPS/MHz"),
    "ipc": ("ipc", "IPC"),
    "bp_pct": ("bp_pct", "bp_accuracy", "BP%", "bp"),
    "icache_hit_pct": ("icache_hit_pct", "i_hit", "I$hit", "ihit"),
    "dcache_hit_pct": ("dcache_hit_pct", "d_hit", "D$hit", "dhit"),
    "doom_fps": ("doom_fps", "fps", "DOOM_FPS"),
}


def _is_na(v: Any) -> bool:
    if v is None:
        return True
    if isinstance(v, str) and v.strip().upper() in {"N/A", "NA", ""}:
        return True
    return False


def _lookup(metrics: dict[str, Any], key: str) -> Any:
    for alias in ALIASES[key]:
        if alias in metrics:
            return metrics[alias]
    return None


def component_score(measured: float, target: float) -> float:
    if target <= 0:
        return 0.0
    return min(100.0, 100.0 * measured / target)


def compute_score(metrics: dict[str, Any]) -> dict[str, Any]:
    active: dict[str, float] = {}
    for key in WEIGHTS:
        raw = _lookup(metrics, key)
        if _is_na(raw):
            continue
        active[key] = float(raw)

    if not active:
        return {"sumudv_score": 0.0, "components": {}, "note": "no metrics"}

    total_w = sum(WEIGHTS[k] for k in active)
    components: dict[str, Any] = {}
    score = 0.0

    for key, measured in active.items():
        w = WEIGHTS[key] / total_w
        c = component_score(measured, TARGETS[key])
        components[key] = {
            "measured": measured,
            "target": TARGETS[key],
            "weight": round(w, 4),
            "component": round(c, 2),
        }
        score += w * c

    return {
        "sumudv_score": round(score, 2),
        "components": components,
        "redistributed": sorted(set(WEIGHTS) - set(active)),
    }


def main() -> int:
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <metrics.json>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    with path.open() as f:
        data = json.load(f)

    metrics = data.get("metrics", data)
    result = compute_score(metrics)
    result["source"] = str(path)
    for meta in ("git_sha", "config", "fmax_mhz", "date", "bp_type", "cache"):
        if meta in data:
            result[meta] = data[meta]

    print(json.dumps(result, indent=2))
    print(f"\nSUMUD-V Score: {result['sumudv_score']:.2f} / 100")
    return 0


if __name__ == "__main__":
    sys.exit(main())
