#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GUI_MODE=0
CLEAN_FIRST=1
COMPILE_ONLY=0

while [[ $# -gt 0 ]]; do
  case $1 in
    -g|--gui) GUI_MODE=1; shift ;;
    -c|--compile-only) COMPILE_ONLY=1; shift ;;
    -n|--no-clean) CLEAN_FIRST=0; shift ;;
    -h|--help)
      echo "Usage: $0 [-g] [-c] [-n]"
      exit 0
      ;;
    *) echo "Unknown option $1"; exit 1 ;;
  esac
done

command -v vsim >/dev/null || { echo "vsim not in PATH"; exit 1; }

if [[ $CLEAN_FIRST -eq 1 ]]; then
  make clean
fi

make compile

if [[ $COMPILE_ONLY -eq 1 ]]; then
  exit 0
fi

if [[ $GUI_MODE -eq 1 ]]; then
  make gui
else
  make sim
fi
