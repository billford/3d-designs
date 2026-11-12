#!/bin/sh
# Regenerate previews, OpenSCAD sources and per-colour STLs for both bookmarks.
#
# Needs python3 and OpenSCAD on PATH. The first run creates .venv/ with
# shapely and matplotlib.
#
# If bambu_mcp.export is available (BAMBU_EXPORT overrides where), STLs go
# through it so they are linted and recorded; otherwise plain OpenSCAD renders
# them. Only the plate is linted: an inlay layer is dozens of separate islands,
# which the lint reports as errors by design.
set -e
cd "$(dirname "$0")"
EXPORT="${BAMBU_EXPORT:-$HOME/Projects/mcp-bambu/.venv/bin/python -m bambu_mcp.export}"
[ -x "${EXPORT%% *}" ] || EXPORT=""
[ -x .venv/bin/python ] || { python3 -m venv .venv && .venv/bin/pip install -q shapely matplotlib; }
mkdir -p out
for b in dracula poe; do
  .venv/bin/python "$b.py" --scad
  for part in purple bone red; do
    if [ -n "$EXPORT" ]; then
      lint=""; [ "$part" = purple ] || lint="--no-lint"
      $EXPORT "out/$b.scad" -o "out/${b}_${part}.stl" -D "part=$part" \
        --layer-height 0.2 --printer h2d $lint
    else
      openscad --render -q -D "part=\"$part\"" -o "out/${b}_${part}.stl" "out/$b.scad"
    fi
  done
done
