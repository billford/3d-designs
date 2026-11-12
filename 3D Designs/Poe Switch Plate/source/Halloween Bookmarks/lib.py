"""Tiny 2D drawing kit for multi-colour inlay bookmarks.

Coordinates are millimetres, y pointing down (like SVG). Shapes are painted
back-to-front onto a Canvas; painting a shape removes it from every other
colour, so the final layers never overlap. "purple" is the base plate colour,
so painting purple just erases.
"""
import functools
import math
import re
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties, findfont
from matplotlib.patches import PathPatch
from matplotlib.path import Path as MPath
from matplotlib.textpath import TextPath
from shapely import affinity
from shapely.geometry import LineString, MultiPolygon, Point, Polygon
from shapely.ops import unary_union

EMPTY = Polygon()

# ---------------------------------------------------------------- paths


def _pts(d):
    toks = re.findall(r"[MLCQZ]|-?\d*\.?\d+(?:e-?\d+)?", d)
    out, subs, cmd, i = [], [], None, 0
    cur = (0.0, 0.0)

    def num():
        nonlocal i
        v = float(toks[i]); i += 1
        return v

    while i < len(toks):
        t = toks[i]
        if t in "MLCQZ":
            cmd = t; i += 1
            if t == "Z":
                if out:
                    subs.append(out); out = []
                continue
        if cmd == "M":
            if len(out) > 1:
                subs.append(out)
            cur = (num(), num()); out = [cur]; cmd = "L"
        elif cmd == "L":
            cur = (num(), num()); out.append(cur)
        elif cmd == "C":
            p0 = cur; p1 = (num(), num()); p2 = (num(), num()); p3 = (num(), num())
            for k in range(1, 21):
                t_ = k / 20; u = 1 - t_
                out.append((u**3*p0[0] + 3*u*u*t_*p1[0] + 3*u*t_*t_*p2[0] + t_**3*p3[0],
                            u**3*p0[1] + 3*u*u*t_*p1[1] + 3*u*t_*t_*p2[1] + t_**3*p3[1]))
            cur = p3
        elif cmd == "Q":
            p0 = cur; p1 = (num(), num()); p2 = (num(), num())
            for k in range(1, 17):
                t_ = k / 16; u = 1 - t_
                out.append((u*u*p0[0] + 2*u*t_*p1[0] + t_*t_*p2[0],
                            u*u*p0[1] + 2*u*t_*p1[1] + t_*t_*p2[1]))
            cur = p2
    if len(out) > 1:
        subs.append(out)
    return subs


def P(d):
    """Filled shape from a path (subpaths are unioned)."""
    return unary_union([Polygon(s).buffer(0) for s in _pts(d) if len(s) > 2])


def S(d, w):
    """Stroked path of width w with round ends."""
    return unary_union([LineString(s).buffer(w / 2, quad_segs=8) for s in _pts(d)])


def circle(x, y, r):
    return Point(x, y).buffer(r, quad_segs=24)


def ellipse(x, y, rx, ry, rot=0):
    e = affinity.scale(Point(0, 0).buffer(1, quad_segs=24), rx, ry)
    return affinity.translate(affinity.rotate(e, rot, origin=(0, 0)), x, y)


def mirror(g, cx):
    return affinity.scale(g, -1, 1, origin=(cx, 0))


def sym(g, cx):
    return unary_union([g, mirror(g, cx)])


def place(g, x, y, s=1.0, rot=0.0, flip=False):
    """Scale a unit-space shape, rotate (degrees), optionally mirror, move."""
    g = affinity.scale(g, -s if flip else s, s, origin=(0, 0))
    g = affinity.rotate(g, rot, origin=(0, 0))
    return affinity.translate(g, x, y)


# ---------------------------------------------------------------- text


@functools.cache
def _font(family):
    """The bold face of `family`, wherever this OS keeps it. Georgia is not
    redistributable, so without it fall back to DejaVu Serif Bold, which ships
    with matplotlib: the lettering then differs slightly from the published STLs."""
    try:
        path = findfont(FontProperties(family=family, weight="bold"), fallback_to_default=False)
    except ValueError:
        print(f"note: font {family!r} not installed, using DejaVu Serif Bold", file=sys.stderr)
        path = findfont(FontProperties(family="DejaVu Serif", weight="bold"))
    return FontProperties(fname=path)


def text(s, font, cx, cy, height=None, width=None, track=0.0, bold=0.12):
    """Text outline in the bold face of font family `font`, centred at (cx, cy).
    Scaled to cap `height`, or squeezed to fit `width` if it would overflow."""
    fp = _font(font)
    glyphs, x = [], 0.0
    for ch in s:
        if ch == " ":
            x += 3.0 + track
            continue
        tp = TextPath((x, 0), ch, size=10, prop=fp)
        polys = [Polygon([(px, -py) for px, py in r]) for r in tp.to_polygons() if len(r) > 2]
        g = EMPTY
        for p in polys:  # even-odd fill handles counters (holes in O, R, ...)
            g = g.symmetric_difference(p.buffer(0))
        glyphs.append(g)
        adv = TextPath((0, 0), ch, size=10, prop=fp).get_extents().width
        x += adv + 0.9 + track
    g = unary_union(glyphs)
    cap = TextPath((0, 0), "H", size=10, prop=fp).get_extents().height
    k = height / cap if height else 1.0
    minx, miny, maxx, maxy = g.bounds
    if width and (maxx - minx) * k > width:
        k = width / (maxx - minx)
    g = affinity.scale(g, k, k, origin=(0, 0))
    minx, miny, maxx, maxy = g.bounds
    # centre on cap height, not descenders
    g = g.buffer(bold, quad_segs=4)  # fatten hairline serifs so they survive a 0.4 nozzle
    return affinity.translate(g, cx - (minx + maxx) / 2, cy + cap * k / 2)


# ---------------------------------------------------------------- canvas


class Canvas:
    COLOURS = ("bone", "red")

    def __init__(self, outline, clip):
        self.outline = outline
        self.clip = clip
        self.L = {c: EMPTY for c in self.COLOURS}

    def paint(self, g, colour, clip=True):
        if clip:
            g = g.intersection(self.clip)
        for c in self.L:
            self.L[c] = self.L[c].difference(g)
        if colour != "purple":
            self.L[colour] = unary_union([self.L[colour], g])

    def outlined(self, g, fill, line="bone", w=0.9):
        self.paint(g, line)
        self.paint(g.buffer(-w, quad_segs=8), fill)

    def haloed(self, g, colour, halo=0.45):
        """Paint with a thin purple gap around it so it reads against
        same-coloured neighbours."""
        self.paint(g.buffer(halo, quad_segs=8), "purple")
        self.paint(g, colour)

    def final(self, min_feature=0.35):
        """Clean up: drop slivers thinner than min_feature, clip to plate."""
        r = min_feature / 2
        out = {}
        for c, g in self.L.items():
            g = g.buffer(-r, quad_segs=6).buffer(r, quad_segs=6)
            g = g.intersection(self.outline).buffer(0)
            out[c] = g
        return out


# ---------------------------------------------------------------- output

PALETTE = {"purple": "#424379", "bone": "#F7F3F0", "red": "#C12E1F"}


def _patch(g, colour):
    polys = [g] if isinstance(g, Polygon) else list(getattr(g, "geoms", []))
    verts, codes = [], []
    for p in polys:
        if p.is_empty or not isinstance(p, Polygon):
            continue
        for ring in [p.exterior, *p.interiors]:
            xy = list(ring.coords)
            verts += xy
            codes += [MPath.MOVETO] + [MPath.LINETO] * (len(xy) - 2) + [MPath.CLOSEPOLY]
    if not verts:
        return None
    return PathPatch(MPath(verts, codes), facecolor=colour, edgecolor="none")


def render(outline, layers, path, scale=14, crop=None):
    minx, miny, maxx, maxy = crop or outline.bounds
    w, h = maxx - minx, maxy - miny
    fig = plt.figure(figsize=(w * scale / 100, h * scale / 100), dpi=100)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(minx, maxx); ax.set_ylim(maxy, miny); ax.axis("off")
    fig.patch.set_facecolor("#1b1b1b")
    for g, c in [(outline, PALETTE["purple"]), (layers["bone"], PALETTE["bone"]),
                 (layers["red"], PALETTE["red"])]:
        p = _patch(g, c)
        if p:
            ax.add_patch(p)
    fig.savefig(path, facecolor=fig.get_facecolor())
    plt.close(fig)


def _scad_poly(g, H):
    polys = [g] if isinstance(g, Polygon) else [p for p in getattr(g, "geoms", []) if isinstance(p, Polygon)]
    parts = []
    for p in polys:
        if p.is_empty or p.area < 0.05:
            continue
        p = p.simplify(0.02)
        pts, paths = [], []
        for ring in [p.exterior, *p.interiors]:
            xy = list(ring.coords)[:-1]
            paths.append(list(range(len(pts), len(pts) + len(xy))))
            pts += [[round(x, 3), round(H - y, 3)] for x, y in xy]
        parts.append("polygon(points=%s, paths=%s);" % (pts, paths))
    return "\n".join(parts)


def write_scad(outline, layers, path, total=1.8, inlay=0.6, hole=None):
    """OpenSCAD file with modules plate2d/bone2d/red2d and a `part` selector."""
    H = outline.bounds[3]
    body = outline if hole is None else outline.difference(hole)
    with open(path, "w") as f:
        f.write("// generated by dracula.py / poe.py - edit the python, not this file\n")
        f.write(f"total = {total};  // mm, overall thickness\n")
        f.write(f"inlay = {inlay};  // mm, depth of the coloured artwork\n")
        f.write('part = "preview";  // preview | purple | bone | red\n\n')
        # pocket grown 0.02mm so inlay regions touching at a corner don't leave
        # pinch-point (non-manifold) edges in the plate
        pocket = unary_union([layers["bone"], layers["red"]]).buffer(0.02, quad_segs=4)
        for name, g in [("plate2d", body), ("bone2d", layers["bone"]), ("red2d", layers["red"]),
                        ("pocket2d", pocket)]:
            f.write(f"module {name}() {{\n{_scad_poly(g, H)}\n}}\n\n")
        f.write("""module art(m) { translate([0,0,total-inlay]) linear_extrude(inlay) children(); }
module purple() { difference() { linear_extrude(total) plate2d();
    translate([0,0,total-inlay]) linear_extrude(inlay+1) pocket2d(); } }
if (part == "purple" || part == "preview") color("#424379") purple();
if (part == "bone" || part == "preview") color("#F7F3F0") art() bone2d();
if (part == "red" || part == "preview") color("#C12E1F") art() red2d();
""")


def plate(W=48, H=176, R=31, spring=31, corner=5):
    """Gothic-arch topped bookmark blank."""
    cx = W / 2
    left = [(R + R * math.cos(a), spring - R * math.sin(a))
            for a in [math.pi - i * (math.pi - math.acos((cx - R) / R)) / 40 for i in range(41)]]
    right = [(W - x, y) for x, y in reversed(left)]
    body = Polygon(left + right[1:] + [(W, H - corner), (W, H), (0, H), (0, H - corner)])
    body = body.buffer(-1.6, join_style=1).buffer(1.6, join_style=1)  # soften the apex
    # round bottom corners
    bottom = Polygon([(0, H - 20), (W, H - 20), (W, H), (0, H)])
    tall = Polygon([(0, H - 40), (W, H - 40), (W, H), (0, H)])
    rounded = tall.buffer(-corner, join_style=1).buffer(corner, join_style=1).intersection(bottom)
    return unary_union([body.difference(bottom), rounded]).buffer(0)
