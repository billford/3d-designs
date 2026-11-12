"""Write pendant_shape.scad: the pendant's outline from scarlet_b.scad, cleaned.

    python3 shape.py            # needs openscad on PATH, or OPENSCAD=/path/to/it

Run it after changing the letter, the loop or the break. It also checks the
balance: the loop must sit over the pendant's centroid, or the B hangs tilted.

Why the outline goes through here rather than straight to the extrusion: the
pen's offset(r=) passes leave vertices thousandths of a millimetre apart, and a
slicer's rounding merges them into non-manifold edges. See scarlet_b.scad.
"""
import math
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCAD = HERE / "scarlet_b.scad"
OUT = HERE / "pendant_shape.scad"
TOL = 0.005    # mm: simplification tolerance, far under a 0.4mm nozzle
MIN_EDGE = 0.01
MAX_TILT = 2   # degrees off level the loop may hang the letter


def rdp(pts, tol):
    """Ramer-Douglas-Peucker on an open polyline."""
    if len(pts) < 3:
        return pts
    (x0, y0), (x1, y1) = pts[0], pts[-1]
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy) or 1e-12
    far, i_far = -1, 0
    for i, (x, y) in enumerate(pts[1:-1], 1):
        d = abs(dy * (x - x0) - dx * (y - y0)) / L
        if d > far:
            far, i_far = d, i
    if far <= tol:
        return [pts[0], pts[-1]]
    return rdp(pts[:i_far + 1], tol)[:-1] + rdp(pts[i_far:], tol)


def simplify_ring(ring, tol):
    # Split the closed ring at its two most distant points, simplify each half.
    a = 0
    b = max(range(len(ring)), key=lambda i: math.dist(ring[0], ring[i]))
    half1 = ring[a:b + 1]
    half2 = ring[b:] + ring[:1]
    out = rdp(half1, tol)[:-1] + rdp(half2, tol)[:-1]
    # RDP keeps true corners, and a few sit closer than MIN_EDGE: merge them.
    merged = [out[0]]
    for q in out[1:]:
        if math.dist(q, merged[-1]) >= MIN_EDGE:
            merged.append(q)
    if math.dist(merged[0], merged[-1]) < MIN_EDGE:
        merged.pop()
    return merged


def rings_from_svg(text):
    rings = []
    for d in re.findall(r'd="([^"]+)"', text):
        for part in re.split(r"[Mm]", d):
            pts = [(float(x), -float(y)) for x, y in re.findall(r"(-?[\d.]+),(-?[\d.]+)", part)]
            if len(pts) >= 3:
                if pts[0] == pts[-1]:
                    pts = pts[:-1]
                rings.append(pts)
    return rings


def area_centroid(rings):
    A = cx = cy = 0.0
    for r in rings:   # holes run the other way, so they subtract
        for (x0, y0), (x1, y1) in zip(r, r[1:] + r[:1]):
            c = x0 * y1 - x1 * y0
            A += c
            cx += (x0 + x1) * c
            cy += (y0 + y1) * c
    A /= 2
    return abs(A), cx / (6 * A), cy / (6 * A)


def scad_value(name):
    m = re.search(rf"^{name}\s*=\s*([\d.]+);", SCAD.read_text(), re.M)
    return float(m.group(1))


def main():
    openscad = os.environ.get("OPENSCAD", "openscad")
    with tempfile.TemporaryDirectory() as tmp:
        svg = Path(tmp) / "outline.svg"
        subprocess.run([openscad, "-o", str(svg), "-D", 'part="outline"', str(SCAD)],
                       check=True, capture_output=True)
        raw = rings_from_svg(svg.read_text())
    rings = [simplify_ring(r, TOL) for r in raw]

    edges = [math.dist(a, b) for r in rings for a, b in zip(r, r[1:] + r[:1])]
    short = sum(e < MIN_EDGE for e in edges)
    area, cx, cy = area_centroid(rings)
    hang_x = scad_value("hang_x")
    top = max(y for r in rings for _, y in r)
    tilt = math.degrees(math.atan2(cx - hang_x, top - cy))
    print(f"{sum(map(len, raw))} -> {sum(map(len, rings))} vertices in {len(rings)} rings; "
          f"{short} edges under {MIN_EDGE}mm")
    print(f"area {area:.1f}mm2, centroid x {cx:.2f}; loop at {hang_x}: hangs {tilt:+.1f} deg")
    if short:
        sys.exit("short edges survived the merge: look at the outline")
    if abs(tilt) > MAX_TILT:
        sys.exit(f"set hang_x = {cx:.1f} in scarlet_b.scad and run this again")

    pts, paths = [], []
    for r in rings:
        paths.append(list(range(len(pts), len(pts) + len(r))))
        pts += r
    OUT.write_text(
        "// generated from scarlet_b.scad by shape.py - do not edit\n"
        "module pendant_outline() polygon(points = ["
        + ", ".join(f"[{x:.4f}, {y:.4f}]" for x, y in pts)
        + "], paths = " + str(paths) + ");\n")
    print(f"wrote {OUT.name}")


if __name__ == "__main__":
    main()
