#!/usr/bin/env bash
# Rebuild both printable parts. Run from anywhere: ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

OPENSCAD=$(command -v openscad || echo /opt/homebrew/bin/openscad)
MCP="$HOME/Projects/mcp-bambu/.venv/bin/python"

for p in wafer cream; do
    out="cookies_$p.stl"
    echo "==> $out"
    rm -f "$out"   # never let a failed render leave the previous STL behind
    if [ -x "$MCP" ]; then
        log=$("$MCP" -m bambu_mcp.export cookies.scad -o "$out" -D part="$p" \
            --layer-height 0.2 --printer h2d 2>&1) || true
    else
        log=$("$OPENSCAD" --render -D "part=\"$p\"" -o "$out" cookies.scad 2>&1) || true
    fi
    echo "$log" | grep -v '^rendering' | grep -v '^TRACE' || true
    if echo "$log" | grep -q 'Assertion' || [ ! -s "$out" ]; then
        echo "!! $out FAILED - stopping"; exit 1
    fi
done
