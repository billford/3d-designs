#!/usr/bin/env bash
# Rebuild the joins and every printable part. Run from anywhere: ./build.sh
#
# Needs python3 and OpenSCAD. split.py needs shapely and numpy; the first run
# makes a .venv/ with them.
set -euo pipefail
cd "$(dirname "$0")"

OPENSCAD=$(command -v openscad || echo /opt/homebrew/bin/openscad)
MCP="$HOME/Projects/mcp-bambu/.venv/bin/python"
[ -x .venv/bin/python ] || { python3 -m venv .venv && .venv/bin/pip install -q shapely numpy; }
.venv/bin/python split.py

# The art parts and the stakes plate are linted with --no-lint: a layer of
# raised letters is a dozen separate islands, and the plate holds two stakes,
# so the lint reports separate bodies by design. sign_1..3 (both colours as
# one body) are what the lint judges.
for p in sign_1 sign_2 sign_3 sign_1_board sign_1_art sign_2_board sign_2_art \
         sign_3_board sign_3_art sign_3_mark_silver sign_3_mark_red stakes; do
    out="$p.stl"
    echo "==> $out"
    rm -f "$out"   # never let a failed render leave the previous STL behind
    if [ -x "$MCP" ]; then
        lint=""; case $p in *_art|stakes) lint="--no-lint" ;; esac
        log=$("$MCP" -m bambu_mcp.export sign.scad -o "$out" -D part="$p" \
            --layer-height 0.2 --printer p1s $lint 2>&1) || true
    else
        log=$("$OPENSCAD" --render -D "part=\"$p\"" -o "$out" sign.scad 2>&1) || true
    fi
    echo "$log" | grep -v '^rendering' | grep -v '^TRACE' || true
    if echo "$log" | grep -q 'Assertion' || [ ! -s "$out" ]; then
        echo "!! $out FAILED - stopping"; exit 1
    fi
done
