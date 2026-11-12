"""A haunted tree, the third shell for the self-watering planter -> tree_shapes.scad.

    .venv/bin/python tree.py

The shell is the trunk of a dead tree with a face in its bark: hollow knot-hole
eyes under a heavy brow, a long gnarled nose and a crooked-toothed grin. The trunk is
broken off at the top in jagged splinters, and the plant grows out of the
break as the tree's crown. Roots flare out over the ground at the foot. One
color: the face is all carving and shadow (owner's choice, 2026-10-28).

WHY THE TRUNK IS A RADIUS FIELD. As in dracula.py, the outside is one surface
r = R(theta, z): trunk, roots, bark furrows and the face's relief. Every bump
is then built up from below by fill_overhang(), which limits how fast R may
grow with height. So the undersides of the nose and brow come out as
43-degree slopes. The eye holes and the gaps between the teeth are cut in
tree.scad, not made in the field: see HOLES and the grin.

WHY THE HOLES CAN BE DEEP. The face swells out of the trunk (the "mound"),
which buys depth for the eyes and the grin without thinning the reservoir wall.
Every point of the field keeps MIN_WALL between it and the cavity, and the
holes stop at a plane MIN_WALL outside the reservoir.

WHAT IT MUST MATCH, from planter.scad (tree.scad asserts these back): the rim
height, the reservoir and the bore that takes the pot's lip.
"""
import math
from pathlib import Path

import numpy as np
from shapely import affinity
from shapely.geometry import MultiPolygon, Polygon
from shapely.ops import unary_union

# --- must match planter.scad (tree.scad asserts these back) ---
SHELL_H = 115.88      # shell_h: the rim, where the pot's lip sits flush
R_RES = 47.5          # r_res: the reservoir wall
BORE = 51.3           # lip_r + seat_fit: the bore that takes the pot's lip
Z_SEAT = 109.709      # z_seat: where the cavity starts to flare out to the bore
Z_FLARE = 113.88      # dz + z_flare: where it reaches the bore

LIMIT = 43.0          # design overhang, deg from vertical: 46.4 at 0.2mm, less margin
MIN_WALL = 2.0        # solid between the deepest carving and the water
SPLINTER_IN = BORE + 1.5   # the splinters' inside face, clear of the pot's lip

N_T = 540             # columns round the trunk (0.67 deg, ~0.7mm at the face)
DZ = 0.5              # rows
Z_TOP = SHELL_H + 24  # the tallest splinter

# The trunk: radius at the foot and at the top, tapering like a real one
R_FOOT, R_TOP = 59.5, 58.0


def gauss(x, z, x0, z0, sx, sz):
    return np.exp(-((x - x0) / sx) ** 2 - ((z - z0) / sz) ** 2)


def hole(x, z, x0, z0, sx, sz, tilt=0.0):
    """1 inside an ellipse, 0 outside, with a crisp but not knife edge, so a
    hole reads as a hole and not as a dimple."""
    c, s = math.cos(math.radians(tilt)), math.sin(math.radians(tilt))
    dx, dz = x - x0, z - z0
    u, v = (c * dx + s * dz) / sx, (-s * dx + c * dz) / sz
    return np.exp(-(u * u + v * v) ** 3)


def ridge(x, z, p0, p1, w, h0, h1):
    """A ridge along the segment p0-p1, height h0 at p0 to h1 at p1."""
    (x0, z0), (x1, z1) = p0, p1
    dx, dz = x1 - x0, z1 - z0
    t = np.clip(((x - x0) * dx + (z - z0) * dz) / (dx * dx + dz * dz), 0, 1)
    d2 = (x - x0 - t * dx) ** 2 + (z - z0 - t * dz) ** 2
    ends = np.clip(np.minimum(t, 1 - t) / 0.12, 0, 1)   # taper off at both ends
    return (h0 + (h1 - h0) * t) * np.exp(-d2 / (w * w)) * (0.4 + 0.6 * ends)


def groove(x, z, pts, w, depth):
    """A wrinkle along a polyline."""
    out = np.zeros_like(x)
    for p0, p1 in zip(pts, pts[1:]):
        out = np.minimum(out, -ridge(x, z, p0, p1, w, depth, depth))
    return out


# --- the grin ------------------------------------------------------------------
# A wide crescent, corners pulled up into the cheeks, full of crooked teeth in
# two staggered rows. It is carved, not cut through: the teeth sit 3mm behind a
# rolled lip, a V-groove between the rows is the mouth line (fill_overhang()
# gives its top a 43-deg slope, which reads dark), and the gaps between the
# teeth are deep vertical slits cut in tree.scad. A gaping hole with a smile's
# curved top would be a flat ceiling over air; the open "O" it replaced looked
# wrong to the owner (2026-10-28).
GRIN_W = 27.0         # half-width, to the corners
GRIN_TOP = 41.0       # the top lip's height at the middle
GRIN_LIFT = 8.0       # how far the corners rise
GRIN_H = 15.0         # the crescent's height at the middle
# where the gaps between the teeth fall, upper and lower rows staggered and
# uneven on purpose: crooked teeth
GAPS_UP = [-21.5, -15.0, -8.5, -2.5, 3.5, 9.5, 16.0, 22.0]
GAPS_LO = [-18.0, -11.5, -5.5, 0.5, 6.5, 12.5, 18.5]
GAP_W = 1.4           # min_feat: the slit is a gap, and the same rule applies


def grin_top(x):
    u = np.clip(x / GRIN_W, -1, 1)
    return GRIN_TOP + GRIN_LIFT * u * u


def grin_bottom(x):
    u = np.clip(x / GRIN_W, -1, 1)
    return grin_top(x) - GRIN_H * (1 - u * u)


def grin_mid(x):
    return (grin_top(x) + grin_bottom(x)) / 2


def sig(v):
    return 1 / (1 + np.exp(-v))


def grin_relief(X, Z):
    zt, zb = grin_top(X), grin_bottom(X)
    inside = sig((zt - Z) / 0.5) * sig((Z - zb) / 0.5) * sig((GRIN_W - np.abs(X)) / 0.8)
    env = np.clip(1 - (np.abs(X) / GRIN_W) ** 4, 0, 1)
    lips = 2.2 * env * (np.exp(-((Z - zt - 1.6) / 1.5) ** 2) + np.exp(-((Z - zb + 1.6) / 1.5) ** 2))
    line = -4.5 * np.exp(-((Z - grin_mid(X)) / 0.8) ** 2) * sig((GRIN_W - 1.5 - np.abs(X)) / 0.6)
    return -3.0 * inside + lips + line


def grin_2d():
    """The grin's outline, for clipping the slits."""
    xs = np.linspace(-GRIN_W, GRIN_W, 81)
    return Polygon([(x, grin_top(x)) for x in xs] + [(x, grin_bottom(x)) for x in xs[::-1]]).buffer(0)


def slits_2d():
    m = grin_mid(np.array([0.0]))[0]
    rects = [Polygon([(x - GAP_W / 2, grin_mid(x) - 0.3), (x + GAP_W / 2, grin_mid(x) - 0.3),
                      (x + GAP_W / 2, 80), (x - GAP_W / 2, 80)]) for x in GAPS_UP] \
        + [Polygon([(x - GAP_W / 2, 0), (x + GAP_W / 2, 0),
                    (x + GAP_W / 2, grin_mid(x) + 0.3), (x - GAP_W / 2, grin_mid(x) + 0.3)]) for x in GAPS_LO]
    # stop the slits 0.8mm inside the lips, so the lip's edge stays whole
    g = unary_union(rects).intersection(grin_2d().buffer(-0.8))
    return affinity.translate(g, 0.0137, 0.13)


# --- the face, in front-view mm (x across, z up) -------------------------------
def face(X, Z):
    """Relief added to the front of the trunk. Holes are negative; fill_overhang()
    then slopes their ceilings."""
    mound = 10.0 * np.exp(-(X / 33) ** 4 - ((Z - 60) / 42) ** 4)

    # a heavy, frowning brow: each side slopes down to the bridge of the nose
    brow = ridge(X, Z, (-35, 92), (-4, 83), 4.5, 4.0, 9.0) \
        + ridge(X, Z, (34, 90), (4, 83), 4.5, 4.0, 9.0)
    cheeks = 4.0 * (gauss(X, Z, -25, 56, 7, 6) + gauss(X, Z, 25, 55, 7, 6))
    # shallow sockets round the eye holes (the holes themselves are cut in
    # tree.scad, see HOLES)
    sockets = -3.0 * (gauss(X, Z, -17, 69, 11, 9) + gauss(X, Z, 17, 68, 10, 8))
    # a long gnarled nose like a broken branch, crooked, with a knob at the tip
    nose = ridge(X, Z, (0, 83), (2.5, 63), 4.5, 5.0, 9.0) + 3.5 * gauss(X, Z, 2.5, 62, 5, 4)
    grin = grin_relief(X, Z)
    # wrinkles: from the nose down to the grin's corners, curling on past them
    # into the cheeks, and across the forehead
    lines = groove(X, Z, [(-8, 64), (-17, 58), (-GRIN_W - 1, GRIN_TOP + GRIN_LIFT + 1)], 1.3, 2.6) \
        + groove(X, Z, [(8, 64), (17, 58), (GRIN_W + 1, GRIN_TOP + GRIN_LIFT + 1)], 1.3, 2.6) \
        + groove(X, Z, [(-GRIN_W + 1, GRIN_TOP + GRIN_LIFT - 1), (-GRIN_W - 4, GRIN_TOP + GRIN_LIFT + 5)], 1.2, 2.4) \
        + groove(X, Z, [(GRIN_W - 1, GRIN_TOP + GRIN_LIFT - 1), (GRIN_W + 4, GRIN_TOP + GRIN_LIFT + 5)], 1.2, 2.4) \
        + groove(X, Z, [(-26, 99), (-8, 96), (6, 98), (24, 96)], 1.3, 2.2) \
        + groove(X, Z, [(-19, 105), (-2, 103), (15, 105)], 1.3, 2.0)
    return mound + brow + cheeks + sockets + nose + grin + lines, mound


def bark(T, Z):
    """Vertical furrows that meander, at two scales."""
    w1 = 0.9 * np.sin(Z / 17 + 1.3) + 0.35 * np.sin(Z / 6.1 + 3 * T)
    w2 = 0.7 * np.sin(Z / 23 + 4.0 * T) + 0.2 * np.sin(Z / 4.3)
    coarse = (0.5 + 0.5 * np.cos(34 * T + w1)) ** 2.5
    fine = (0.5 + 0.5 * np.cos(13 * T + w2)) ** 4
    return 2.6 * coarse + 1.2 * fine - 2.4


def roots(T, Z):
    """Six roots flaring out over the ground, two flanking the grin."""
    lobes = (0.5 + 0.5 * np.cos(6 * (T - math.radians(30)) + 0.25 * np.sin(5 * T))) ** 6
    return 15.0 * np.exp(-Z / 13) * lobes + 3.5 * np.exp(-Z / 18)


# A knot on the back: a raised ring with a hole in it
def knot(T, Z):
    a = (T - math.radians(200) + math.pi) % (2 * math.pi) - math.pi
    s = a * 58
    rr = np.sqrt((s / 7.5) ** 2 + ((Z - 84) / 9) ** 2)
    return 3.0 * np.exp(-((rr - 1) / 0.35) ** 2) - 5.0 * np.exp(-(rr / 0.7) ** 6)


def cavity_r(z):
    """The cavity's radius at height z, from planter.scad's shell_cavity()."""
    return np.where(z < Z_SEAT, R_RES,
                    np.where(z < Z_FLARE, R_RES + (BORE - R_RES) * (z - Z_SEAT) / (Z_FLARE - Z_SEAT),
                             np.where(z <= SHELL_H, BORE, SPLINTER_IN)))


def fill_overhang(R, dz, limit_deg):
    """R may not grow faster than tan(limit) per unit height. Worked from the
    top down, it FILLS: everything under a high point is raised to a slope
    falling away below it. So a hole keeps whatever is above it and gets a
    sloped ceiling instead. dracula.py's clamp cut from below, and here that
    planed away the nose above the open mouth (2026-10-28). Filling only adds
    material, so it can never thin a wall."""
    s = math.tan(math.radians(limit_deg)) * dz
    R = R.copy()
    for j in range(R.shape[0] - 2, -1, -1):
        R[j] = np.maximum(R[j], R[j + 1] - s)
    return R


def trunk():
    t = np.linspace(0, 2 * math.pi, N_T, endpoint=False)
    z = np.arange(0, Z_TOP + 1e-6, DZ)
    T, Z = np.meshgrid(t, z)
    R0 = R_FOOT + (R_TOP - R_FOOT) * Z / SHELL_H
    X = R0 * np.sin(T)
    front = np.cos(T) > 0
    rel, mound = face(X, Z)
    rel = np.where(front, rel, 0)
    mound = np.where(front, mound, 0)
    # the bark goes on everywhere, but smoother on the face so it still reads
    R = R0 + bark(T, Z) * (1 - 0.65 * mound / 10.0) + rel + roots(T, Z) + knot(T, Z)
    floor = cavity_r(Z) + MIN_WALL
    R = np.maximum(R, floor)
    R = fill_overhang(R, DZ, LIMIT)
    return t, z, R


def check_trunk(t, z, R):
    worst = np.max(np.diff(R, axis=0) / DZ)
    assert math.degrees(math.atan(worst)) <= LIMIT + 1e-6, f"overhang {math.degrees(math.atan(worst)):.1f} deg"
    wall = (R - cavity_r(z)[:, None]).min()
    assert wall >= MIN_WALL - 1e-6, f"wall only {wall:.2f}mm"
    return math.degrees(math.atan(worst)), wall


# --- the broken top ------------------------------------------------------------
# Splinters: (angle from the front, deg; height above the rim; half-width, deg)
SPLINTERS = [(-150, 24, 16), (-105, 13, 11), (-62, 7, 9), (128, 19, 14),
             (170, 15, 10), (75, 9, 10), (-25, 5, 7), (30, 4, 8)]


def splinter_h(a):
    """Height of the break above the rim at angle a (radians): the highest
    splinter there, with a ragged edge."""
    h = np.zeros_like(a)
    for deg, ht, half in SPLINTERS:
        d = np.abs((a - math.radians(deg) + math.pi) % (2 * math.pi) - math.pi) / math.radians(half)
        jag = 1 + 0.12 * np.sin(a * 97 + deg)
        h = np.maximum(h, ht * np.clip(1 - d, 0, 1) ** 1.3 * jag)
    return np.minimum(h, Z_TOP - SHELL_H - 0.3)


def top_cutter():
    """Everything below the broken top. Columns half-way between the trunk's,
    so no cutter edge lands on a trunk edge (the 3-decimal lint merges those)."""
    step = 2 * math.pi / N_T
    a = np.arange(N_T) * step + step / 2
    h = SHELL_H + splinter_h(a)
    V, F = [], []
    rings = [(SPLINTER_IN - 1.0, h), (200.0, h)]
    for r, hh in rings:
        for i in range(N_T):
            V.append((r * math.sin(a[i]), -r * math.cos(a[i]), hh[i]))
    for r, _ in rings:
        for i in range(N_T):
            V.append((r * math.sin(a[i]), -r * math.cos(a[i]), -1.0))
    ctop, cbot = len(V), len(V) + 1
    V += [(0, 0, SHELL_H + 0.3), (0, 0, -1.0)]
    n = N_T

    def q(a_, b_, c_, d_):   # quad a-b-c-d
        return [(a_, b_, c_), (a_, c_, d_)]
    for i in range(n):
        j = (i + 1) % n
        it, ot, ib, ob = i, n + i, 2 * n + i, 3 * n + i
        jt, jo, jb, job = j, n + j, 2 * n + j, 3 * n + j
        F += [(ctop, jt, it)]                 # top cap, center to the inner ring
        F += q(it, jt, jo, ot)                # top, inner ring to outer
        F += q(ot, jo, job, ob)               # outside wall
        F += q(ob, job, jb, ib)               # bottom, outer ring to inner
        F += [(cbot, ib, jb)]                 # bottom cap
    return V, F


# --- the holes -----------------------------------------------------------------
# The eyes are cut straight back into the trunk, front to back, by
# tree.scad, as teardrops: a round hole with a peaked top whose two sides lean
# at CAP_A from vertical. Side walls are vertical, the peak's walls are a 40-deg
# overhang and the floor faces up, so the hole is deep and dark and needs no
# support. Holes inside the radius field could only ever be 43-deg chutes,
# which read as a snout from the front (2026-10-28).
# (center x, center z, half-width, half-height) in front-view mm
HOLES = {"eye_l": (-17, 69.13, 8.0, 6.5), "eye_r": (17, 68.13, 6.6, 4.8)}
CAP_A = 40.0
HOLE_BACK = R_RES + MIN_WALL      # the holes' back wall: a plane this far out
SLIT_BACK = 56.0      # the slits between the teeth go back to this plane


def teardrop(x0, z0, sx, sz, n=96):
    """An ellipse with a peaked top, the peak's sides CAP_A from vertical:
    the hull of the ellipse and the apex where its two tangents meet."""
    m = math.tan(math.radians(90 - CAP_A))      # the tangents' slope, dz/dx
    tt = math.atan2(sz, m * sx)                 # where the right tangent touches
    xt, zt = sx * math.cos(tt), sz * math.sin(tt)
    apex = zt + m * xt
    pts = [(sx * math.cos(a), sz * math.sin(a)) for a in np.linspace(0, 2 * math.pi, n, endpoint=False)]
    hull = Polygon(pts + [(0, apex)]).convex_hull
    return affinity.translate(hull, x0 + 0.0137, z0)


def holes_2d():
    out = {k: teardrop(*v) for k, v in HOLES.items()}
    out["slits"] = slits_2d()
    return out


# --- meshes ------------------------------------------------------------------
def grid_mesh(t, z, R):
    """Closed solid from a radius field: side grid, fans to the axis at both ends."""
    nt, nz = len(t), len(z)
    V = []
    for j in range(nz):
        for i in range(nt):
            V.append((R[j, i] * math.sin(t[i]), -R[j, i] * math.cos(t[i]), z[j]))
    bot, top = len(V), len(V) + 1
    V += [(0, 0, z[0]), (0, 0, z[-1])]
    F = []
    for j in range(nz - 1):
        for i in range(nt):
            a, b = j * nt + i, j * nt + (i + 1) % nt
            c, d = a + nt, b + nt
            F += [(a, b, d), (a, d, c)]
    for i in range(nt):
        F.append((bot, (i + 1) % nt, i))
        F.append((top, (nz - 1) * nt + i, (nz - 1) * nt + (i + 1) % nt))
    return V, F


def signed_volume(V, F):
    P = np.array(V)
    f = np.array(F)
    a, b, c = P[f[:, 0]], P[f[:, 1]], P[f[:, 2]]
    return np.einsum("ij,ij->i", a, np.cross(b, c)).sum() / 6


def scad_polyhedron(V, F):
    # OpenSCAD wants faces clockwise seen from outside: reverse if outward-CCW
    if signed_volume(V, F) > 0:
        F = [(a, c, b) for a, b, c in F]
    pts = ",".join(f"[{x:.3f},{y:.3f},{z:.3f}]" for x, y, z in V)
    fcs = ",".join(f"[{a},{b},{c}]" for a, b, c in F)
    return f"polyhedron(points=[{pts}], faces=[{fcs}], convexity=8);"


def scad_polygon(g):
    polys = list(g.geoms) if isinstance(g, MultiPolygon) else [g]
    out = []
    for p in polys:
        c = list(p.exterior.coords)[:-1]
        out.append("polygon(points=[" + ",".join(f"[{x:.3f},{y:.3f}]" for x, y in c) + "]);")
    return "union() {\n  " + "\n  ".join(out) + "\n}"


def main():
    t, z, R = trunk()
    worst, wall = check_trunk(t, z, R)
    tv, tf = grid_mesh(t, z, R)
    cv, cf = top_cutter()
    assert signed_volume(cv, cf) != 0
    out = [
        "// GENERATED by tree.py - do not edit; change tree.py and re-run it.",
        f"tree_for_h = {SHELL_H};",
        f"tree_for_r_res = {R_RES};",
        f"tree_for_bore = {BORE};",
        f"tree_splinter_in = {SPLINTER_IN};",
        f"tree_top = {Z_TOP};",
        "module tree_trunk() " + scad_polyhedron(tv, tf),
        "module tree_top_cutter() " + scad_polyhedron(cv, cf),
        f"tree_hole_back = {HOLE_BACK};",
        f"tree_slit_back = {SLIT_BACK};",
    ] + [f"module tree_{k}_2d() " + scad_polygon(g) for k, g in holes_2d().items()]
    Path(__file__).with_name("tree_shapes.scad").write_text("\n".join(out) + "\n")
    print(f"tree_shapes.scad: worst overhang {worst:.1f} deg, thinnest wall {wall:.2f}mm, "
          f"footprint {2 * R[0].max():.0f}mm across the roots")


if __name__ == "__main__":
    main()
