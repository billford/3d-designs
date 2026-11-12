#!/usr/bin/env bash
# Rebuild every printable part. Run from anywhere: ./build.sh
#   tentacles.py -> tentacles.scad, dracula.py and tree.py -> their _shapes.scad, then
#   each part through the export wrapper, then the shells' boolean slivers
#   collapsed (clean_mesh.py) and re-linted.
# The first run makes .venv/ with numpy and manifold3d.
set -euo pipefail
cd "$(dirname "$0")"

OPENSCAD=$(command -v openscad || echo /opt/homebrew/bin/openscad)
MCP="$HOME/Projects/mcp-bambu/.venv/bin/python"
LINT="$HOME/Projects/print-lint/print_lint.py"

if [ ! -x .venv/bin/python ]; then
    python3 -m venv .venv
    .venv/bin/pip -q install numpy manifold3d shapely
fi
.venv/bin/python tentacles.py
# the Dracula and tree shells are still in progress and aren't in the
# published release
dracula=false tree=false
[ -f dracula.py ] && dracula=true
[ -f tree.py ] && tree=true
if $dracula; then .venv/bin/python dracula.py; fi
if $tree; then .venv/bin/python tree.py; fi

export_part() {   # export_part <scad> <part> <stl>
    echo "==> $3"
    rm -f "$3"   # never let a failed render leave the previous STL behind
    if [ -x "$MCP" ]; then
        log=$("$MCP" -m bambu_mcp.export "$1" -o "$3" -D part="$2" \
            --layer-height 0.2 --printer p1s 2>&1) || true
    else
        log=$("$OPENSCAD" --render -D "part=\"$2\"" -o "$3" "$1" 2>&1) || true
    fi
    echo "$log" | grep -v '^rendering' | grep -v '^TRACE' || true
    if echo "$log" | grep -q 'Assertion' || [ ! -s "$3" ]; then
        echo "!! $3 FAILED - stopping"; exit 1
    fi
}

for p in shell pot dipstick shell_mark_silver shell_mark_red; do
    export_part planter.scad "$p" "planter_$p.stl"
done
clean=(planter_shell.stl)
if $dracula; then
    for p in black white mark_silver mark_red; do
        export_part dracula.scad "dracula_$p" "dracula_$p.stl"
    done
    clean+=(dracula_black.stl dracula_white.stl)
fi
if $tree; then
    for p in tree tree_mark_silver tree_mark_red; do
        export_part tree.scad "$p" "$p.stl"
    done
    clean+=(tree.stl)
fi

# The white is an inlay: many separate islands, so the lint calls the pupils
# and fangs "internal voids" (DESIGN-NOTES, flat color inlays). Only the
# manifold result matters for it.
for f in "${clean[@]}"; do
    echo "==> cleaning $f"
    .venv/bin/python clean_mesh.py "$f"
    if [ -x "$MCP" ] && [ -f "$LINT" ]; then
        # report, don't stop: the white's known inlay warnings exit nonzero
        "$MCP" "$LINT" "$f" --layer-height 0.2 --printer p1s || true
    fi
done
