#!/usr/bin/env bash
# Rebuild every printable part. Run from anywhere: ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

OPENSCAD=$(command -v openscad || echo /opt/homebrew/bin/openscad)
MCP="$HOME/Projects/mcp-bambu/.venv/bin/python"

for p in cap cream black amber cap_plain test_plate snap_plate plate_body plate_parts plate_cream plate_black plate_amber discs base wolf_mark_silver wolf_mark_red; do
    case $p in wolf_*) out="$p.stl" ;; *) out="wolf_$p.stl" ;; esac
    echo "==> $out"
    rm -f "$out"   # never let a failed render leave the previous STL behind
    if [ -x "$MCP" ]; then
        log=$("$MCP" -m bambu_mcp.export wolf_fidget.scad -o "$out" -D part="$p" \
            --layer-height 0.2 --printer p1s 2>&1) || true
    else
        log=$("$OPENSCAD" --render -D "part=\"$p\"" -o "$out" wolf_fidget.scad 2>&1) || true
    fi
    echo "$log" | grep -v '^rendering' | grep -v '^TRACE' || true
    if echo "$log" | grep -q 'Assertion' || [ ! -s "$out" ]; then
        echo "!! $out FAILED - stopping"; exit 1
    fi
done

# Weld every STL to the 3dp grid the lint and slicers round to, and prove each
# watertight there (weld_stl.py says why). Then lint the welded files, since
# the export wrapper linted them before the weld.
PY=../.venv/bin/python; [ -x "$PY" ] || PY=python3
"$PY" weld_stl.py wolf_*.stl
if [ -x "$MCP" ]; then
    "$MCP" - wolf_*.stl <<'PYEOF'
import sys
from pathlib import Path
from bambu_mcp.diagnose import lint_source
# separate bodies and voids are normal in an inlay layer (DESIGN-NOTES,
# 2026-10-05) and in a plate of several discs; anything else is a fault
ok = {"mesh.separate_body", "mesh.internal_void"}
for p in sys.argv[1:]:
    f = lint_source(Path(p), "p1s", 0.2) or []
    bad = sorted({x["id"] for x in f if x["severity"] == "error"} - ok)
    print(f"  lint {p}: {'clean' if not bad else 'FAULT ' + ', '.join(bad)}")
    if bad: sys.exit(1)
PYEOF
fi

# Bambu Studio silently scales any part under 9 mm3 by 25.4 ("looks like
# inches"). The amber irises at 4.2 mm3 loaded 356mm wide (2026-11-11).
../.venv/bin/python - <<'PY'
import glob, sys, numpy as np
from weld_stl import read_stl
bad = []
for f in sorted(glob.glob("wolf_*.stl")):
    t = read_stl(f)
    v = np.einsum("ij,ij->i", t[:, 0], np.cross(t[:, 1], t[:, 2])).sum() / 6
    if v < 10:
        bad.append(f"{f}: {v:.1f} mm3")
if bad:
    sys.exit("UNDER Studio's 9 mm3 'inches' threshold (+1 margin):\n  " + "\n  ".join(bad))
print("  volumes: every STL over Studio's 9 mm3 inches threshold")
PY

