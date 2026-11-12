#!/usr/bin/env bash
# Rebuild the artwork and every printable part. Run from anywhere: ./build.sh
#
# Needs python3 and OpenSCAD. The artwork uses the Halloween Bookmarks drawing
# kit (../Halloween Bookmarks/lib.py), which needs shapely and matplotlib; the
# first run makes a .venv/ with them.
set -euo pipefail
cd "$(dirname "$0")"

OPENSCAD=$(command -v openscad || echo /opt/homebrew/bin/openscad)
MCP="$HOME/Projects/mcp-bambu/.venv/bin/python"
[ -x .venv/bin/python ] || { python3 -m venv .venv && .venv/bin/pip install -q shapely matplotlib; }
.venv/bin/python art.py --scad

# Only the body and the gauge are linted: an inlay layer is dozens of separate
# islands, which the lint reports as errors by design.
for p in gauge body bone red mark_silver; do
    out="sherlock_double_$p.stl"
    echo "==> $out"
    rm -f "$out"   # never let a failed render leave the previous STL behind
    if [ -x "$MCP" ]; then
        lint=""; case $p in gauge|body) ;; *) lint="--no-lint" ;; esac
        log=$("$MCP" -m bambu_mcp.export switchplate.scad -o "$out" -D part="$p" \
            --layer-height 0.2 --printer p1s $lint 2>&1) || true
    else
        log=$("$OPENSCAD" --render -D "part=\"$p\"" -o "$out" switchplate.scad 2>&1) || true
    fi
    echo "$log" | grep -v '^rendering' | grep -v '^TRACE' || true
    if echo "$log" | grep -q 'Assertion' || [ ! -s "$out" ]; then
        echo "!! $out FAILED - stopping"; exit 1
    fi
done
