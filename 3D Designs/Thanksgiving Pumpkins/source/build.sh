#!/usr/bin/env bash
# Rebuild every printable part. Run from anywhere: ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

OPENSCAD=$(command -v openscad || echo /opt/homebrew/bin/openscad)
MCP="$HOME/Projects/mcp-bambu/.venv/bin/python"

# The art parts and the stakes plate are linted with --no-lint: art is many
# separate islands and the plate holds four pieces, so the lint reports separate
# bodies by design. pumpkin_1 and pumpkin_2 (both colours as one body) are what
# the lint judges; stake_lower and stake_upper are judged one at a time.
for p in pumpkin_1 pumpkin_2 pumpkin_1_board pumpkin_1_art pumpkin_2_board pumpkin_2_art \
         stake_lower stake_upper stakes; do
    out="$p.stl"
    echo "==> $out"
    rm -f "$out"   # never let a failed render leave the previous STL behind
    if [ -x "$MCP" ]; then
        lint=""; case $p in *_art|stakes) lint="--no-lint" ;; esac
        log=$("$MCP" -m bambu_mcp.export pumpkins.scad -o "$out" -D part="$p" \
            --layer-height 0.2 --printer p1s $lint 2>&1) || true
    else
        log=$("$OPENSCAD" --render -D "part=\"$p\"" -o "$out" pumpkins.scad 2>&1) || true
    fi
    echo "$log" | grep -v '^rendering' | grep -v '^TRACE' || true
    if echo "$log" | grep -q 'Assertion' || [ ! -s "$out" ]; then
        echo "!! $out FAILED - stopping"; exit 1
    fi
done
