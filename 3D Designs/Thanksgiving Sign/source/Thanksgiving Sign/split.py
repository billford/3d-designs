"""Split the yard sign into printable pieces, with joins that miss the art.

    python split.py            # writes sign_split.scad, prints the checks

The sign is 600mm wide and no printer here takes that, so it prints in three
pieces of about 200mm (the P1S's practical limit is 230, DESIGN-NOTES). A
straight cut would run through letters, and a raised letter cut in two shows
its seam. So each join is routed: a shortest path from the top edge to the
bottom edge that keeps JOIN_CLEAR away from the lettering and the turkey.
It may cross the border, which is a plain band where a cut reads as a joint.

Each join gets a jigsaw knob above the lettering and, where there is room, a
second one below it, so the pieces can neither pull apart nor turn. The
stake pockets sit wholly inside one piece each, and the joins are routed round
them: a pocket across a join left each half's roof hanging off one side, a
10mm cantilever over air (2026-10-19, caught before printing). Every piece edge along a join is set back CLEAR, the 0.22mm
proven per side (CLAUDE.md; the fire pit tree tabs, 2026-10-19).

Needs shapely and numpy. The art comes from sign.scad itself (OpenSCAD exports
it as SVG), so the join follows whatever the art currently is.
"""

import heapq
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import shapely
from shapely.geometry import LineString, Point, Polygon, box
from shapely.ops import substring, unary_union

HERE = Path(__file__).resolve().parent
SCAD = HERE / "sign.scad"
OUT = HERE / "sign_split.scad"

BOARD_W, BOARD_H = 600.0, 200.0      # must match sign.scad
# where each join should run: between the turkey and the words, then down
# through HAPPY and between THANKS and GIVING, the middle of the text block
SEAM_X = [212.0, 394.0]
KNOB_REACH_DIR = [+1, -1]
# join to art: 1.2, the minimum feature (CLAUDE.md), so a join can thread a
# 3.2mm gap between letters
JOIN_CLEAR = 1.2
CLEAR = 0.22         # per side, at every join
GRID = 0.25          # path search resolution, mm: it has to find a 3.2mm gap
SEARCH_HALF = 60.0   # search this far either side of SEAM_X, to keep the grid small
STRAY = 0.02         # cost per mm of sideways distance from SEAM_X: keeps joins near it

# knob: a neck from the join, then a round head. Head 12 across, neck 7: the
# neck is the narrowest part, 7 x 10mm of board, and holds glue on three sides
KNOB_NECK, KNOB_R, KNOB_REACH = 7.0, 6.0, 10.0
KNOB_CLEAR = 1.5     # knob to art and border, so no letter sits over a knob's edge
KNOB_STRAIGHT = 8.0  # the join must run straight this far either side of a knob

# stake pockets in the board's bottom edge (sign.scad cuts them): at a quarter
# and three quarters of the width, where two stakes hold a beam best
POCKET_X = [150.0, 450.0]
POCKET_W, POCKET_D = 20.0, 70.0
POCKET_KEEP = 4.0    # board left between a pocket and a join or knob
MAX_PIECE = 230.0    # P1S practical bed (DESIGN-NOTES "Bed and machine limits")


def scad_2d(part):
    """Render one 2D part of sign.scad and read it back as a shapely shape."""
    with tempfile.TemporaryDirectory() as tmp:
        svg = Path(tmp) / "a.svg"
        subprocess.run(["openscad", "-q", "-o", str(svg), "-D", f'part="{part}"', str(SCAD)],
                       check=True)
        text = svg.read_text()
    shape = Polygon()
    for d in re.findall(r'd="([^"]*)"', text):
        for sub in re.split(r"[Mm]", d):
            pts = [(float(x), -float(y)) for x, y in re.findall(r"(-?[\d.e+-]+),(-?[\d.e+-]+)", sub)]
            if len(pts) >= 3:
                # OpenSCAD's SVG is even-odd: a hole is a ring inside a ring
                shape = shape.symmetric_difference(Polygon(pts).buffer(0))
    return shape


def route(blocked, x_target):
    """Shortest top-to-bottom grid path through free cells, staying near x_target."""
    x_lo = x_target - SEARCH_HALF
    nx, ny = int(2 * SEARCH_HALF / GRID) + 1, int(BOARD_H / GRID) + 1
    xs, ys = np.meshgrid(x_lo + np.arange(nx) * GRID, np.arange(ny) * GRID, indexing="ij")
    free = ~shapely.contains_xy(blocked, xs, ys)
    stray = STRAY * np.abs(xs - x_target)
    INF = float("inf")
    dist = np.full((nx, ny), INF)
    prev = {}
    heap = []
    for i in range(nx):
        if free[i, ny - 1]:
            dist[i, ny - 1] = stray[i, ny - 1]
            heapq.heappush(heap, (dist[i, ny - 1], i, ny - 1))
    steps = [(dx, dy, GRID * (dx * dx + dy * dy) ** 0.5)
             for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
    end = None
    while heap:
        d, i, j = heapq.heappop(heap)
        if d > dist[i, j]:
            continue
        if j == 0:
            end = (i, j)
            break
        for dx, dy, step in steps:
            a, b = i + dx, j + dy
            if 0 <= a < nx and 0 <= b < ny and free[a, b]:
                nd = d + step * (1 + stray[a, b])
                if nd < dist[a, b]:
                    dist[a, b] = nd
                    prev[(a, b)] = (i, j)
                    heapq.heappush(heap, (nd, a, b))
    assert end, f"no clear path for the join near x = {x_target}"
    path = [end]
    while path[-1] in prev:
        path.append(prev[path[-1]])
    pts = [(x_lo + i * GRID, j * GRID) for i, j in path]
    line = LineString(pts).simplify(GRID * 0.7)
    return line


def knob(at, tangent, side):
    """A jigsaw knob at point `at`, reaching to `side` (+1/-1) of the join."""
    t = np.array(tangent) / np.linalg.norm(tangent)
    n = np.array([-t[1], t[0]]) * side
    p = np.array(at)
    neck = Polygon([p - t * KNOB_NECK / 2 - n, p + t * KNOB_NECK / 2 - n,
                    p + t * KNOB_NECK / 2 + n * (KNOB_REACH - KNOB_R),
                    p - t * KNOB_NECK / 2 + n * (KNOB_REACH - KNOB_R)])
    head = Point(p + n * (KNOB_REACH - KNOB_R)).buffer(KNOB_R, quad_segs=24)
    return neck.union(head)


def place_knobs(line, keep_out, pocket, reach):
    """A knob high on the join, and a second low down if there is room."""
    picks = []
    # `reach`: which way (+1 right, -1 left) the knobs point. Both point INTO
    # the middle piece, which keeps it narrow: 230 wide with them pointing out.
    # One knob already stops a join pulling apart; two stop it turning
    for band, want in (((BOARD_H / 2, BOARD_H), reach), ((0, BOARD_H / 2), reach)):
        best = None
        for s in np.arange(KNOB_STRAIGHT, line.length - KNOB_STRAIGHT, 1.0):
            p = line.interpolate(s)
            if not band[0] <= p.y <= band[1]:
                continue
            a, b = line.interpolate(s - KNOB_STRAIGHT), line.interpolate(s + KNOB_STRAIGHT)
            seg = LineString([a, b])
            if substring(line, s - KNOB_STRAIGHT, s + KNOB_STRAIGHT).hausdorff_distance(seg) > 0.3:
                continue    # the join bends here
            for sd in (1, -1):
                k = knob((p.x, p.y), (b.x - a.x, b.y - a.y), sd)
                side = 1 if k.centroid.x > p.x else -1
                if k.buffer(KNOB_CLEAR).intersects(keep_out) or k.intersects(pocket):
                    continue
                # prefer knobs far from the middle of the sign's height
                if side != want:
                    continue
                score = abs(p.y - BOARD_H / 2)
                if best is None or score > best[0]:
                    best = (score, k, (round(p.x, 1), round(p.y, 1)))
                break
        if best:
            picks.append(best)
    assert picks and picks[0][2][1] > BOARD_H / 2, "no room for a knob above the lettering"
    return picks


def main():
    pictures = scad_2d("pictures_2d")
    border = scad_2d("border_2d")
    board = box(0, 0, BOARD_W, BOARD_H)
    # search with a grid cell to spare, so simplifying the path cannot cut a
    # corner into JOIN_CLEAR
    pockets = unary_union([box(x - POCKET_W / 2, -1, x + POCKET_W / 2, POCKET_D) for x in POCKET_X])
    blocked = unary_union([pictures.buffer(JOIN_CLEAR + GRID), pockets.buffer(POCKET_KEEP + GRID)])
    keep_out = unary_union([pictures, border, board.exterior.buffer(9)])

    regions = []      # the area to the LEFT of each join, knobs included
    report = []
    for x, reach in zip(SEAM_X, KNOB_REACH_DIR):
        line = route(blocked, x)
        # extend past the board, so the region closes cleanly outside it
        pts = list(line.coords)
        top, bot = (pts[0], pts[-1]) if pts[0][1] > pts[-1][1] else (pts[-1], pts[0])
        if pts[0][1] < pts[-1][1]:
            pts = pts[::-1]
        pts = [(top[0], BOARD_H + 20)] + pts + [(bot[0], -20)]
        left = Polygon(pts + [(-50, -20), (-50, BOARD_H + 20)]).buffer(0)
        knobs = place_knobs(line, keep_out, pockets.buffer(POCKET_KEEP), reach)
        for _, k, _ in knobs:
            # a knob reaching right is part of the left piece; reaching left, it isn't
            reaches_right = k.difference(left).area > k.area / 2
            left = left.union(k) if reaches_right else left.difference(k)
        regions.append(left)
        report.append((x, [p for _, _, p in knobs], line))

    pieces = []
    prev = None
    for left in regions + [None]:
        region = board if left is None else board.intersection(left.buffer(-CLEAR, join_style="mitre"))
        if prev is not None:
            region = region.difference(prev.buffer(CLEAR, join_style="mitre"))
        pieces.append(region)
        prev = left

    # ---- checks -------------------------------------------------------------
    ok = True
    for i, pc in enumerate(pieces):
        assert pc.geom_type == "Polygon", f"piece {i + 1} came out in {len(pc.geoms)} parts"
        x0, y0, x1, y1 = pc.bounds
        print(f"piece {i + 1}: x {x0:.1f}..{x1:.1f} ({x1 - x0:.1f} wide), {pc.area / 100:.0f} cm2")
        ok &= x1 - x0 <= MAX_PIECE
    gaps = board.difference(unary_union(pieces))
    cut = gaps.intersection(pictures).area
    print(f"art cut by a join: {cut:.3f} mm2 (must be 0)")
    ok &= cut < 1e-6
    # every letter and turkey part lies wholly in one piece
    for g in getattr(pictures, "geoms", [pictures]):
        n = sum(1 for pc in pieces if pc.intersection(g).area > 1e-6)
        ok &= n == 1
    for x, ks, line in report:
        print(f"join near x {x:.0f}: knobs at {ks}, "
              f"min distance to art {line.distance(pictures):.2f} mm, to a pocket {line.distance(pockets):.1f} mm")
        ok &= line.distance(pictures) >= JOIN_CLEAR and line.distance(pockets) >= POCKET_KEEP
    for x in POCKET_X:
        pk = box(x - POCKET_W / 2, 0, x + POCKET_W / 2, POCKET_D)
        ok &= sum(1 for pc in pieces if pc.intersection(pk).area > 1e-6) == 1
    assert ok, "a check failed (above)"

    def poly(p):
        return "[" + ",".join(f"[{x:.3f},{y:.3f}]" for x, y in list(p.exterior.coords)[:-1]) + "]"
    with OUT.open("w") as f:
        f.write("// GENERATED by split.py from sign.scad's art - do not edit.\n")
        f.write(f"// joins keep {JOIN_CLEAR}mm off the art; {CLEAR}mm clearance per side.\n")
        f.write(f"split_clear = {CLEAR};\n")
        f.write("split_pockets = [" + ", ".join(f"{x:.3f}" for x in POCKET_X) + "];\n")
        f.write("function split_piece(i) =\n")
        for i, pc in enumerate(pieces):
            f.write(f"    i == {i} ? {poly(pc)} :\n")
        f.write("    undef;\n")
        f.write(f"split_n = {len(pieces)};\n")
    print(f"wrote {OUT.name}")


if __name__ == "__main__":
    sys.exit(main())
