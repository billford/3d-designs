"""Dracula's head, the second shell for the self-watering planter -> dracula_shapes.scad.

    .venv/bin/python dracula.py

The head is the reservoir. The pot drops in from the top, and the plant is his
hair. The face is the Dracula from Halloween Bookmarks (the owner's choice,
2026-10-28): widow's peak, heavy brows, swept-up pointed ears and a stand-up
collar. Black and white only: the face and ears are white, the rest black.

WHY THE HEAD IS A RADIUS FIELD. The outside is one surface r = R(theta, z),
a slightly flattened head with the face's relief (brow, nose, cheeks, chin)
added on the front. Every bump is then sunk from below by clamp_overhang(),
which limits how fast R may grow with height. So the underside of the nose
and the chin come out as 43-degree slopes and nothing is left to start in
mid-air. The check is done on the numbers, not reasoned about.

WHY THE COLORS ARE FRONT-PROJECTED. The face artwork is drawn flat, as seen
from the front, and pushed straight back into a 2mm skin. That is how a face
reads from the front, and the bookmark's own coordinates still apply. The
ears are separate solid plates instead, because projecting them from the
front would also paint the side of the head behind them.

WHAT IT MUST MATCH, from planter.scad (dracula.scad asserts these back): the
rim height, the reservoir and the bore that takes the pot's lip.
"""
import math
from pathlib import Path

import numpy as np
from shapely import affinity
from shapely.geometry import LineString, MultiPolygon, Point, Polygon
import shapely
from shapely.ops import unary_union

# --- must match planter.scad (dracula.scad asserts these back) ---
SHELL_H = 115.88      # shell_h: the rim, where the pot's lip sits flush
R_RES = 47.5          # r_res: the reservoir wall
BORE = 51.3           # lip_r + seat_fit: the bore that takes the pot's lip

LAYER = 0.2
LIMIT = 43.0          # design overhang, deg from vertical: 46.4 at 0.2mm, less margin
SKIN = 2.0            # depth of the white: thick enough that black can't gray it
MIN_WALL = 2.0        # black behind the white, round the reservoir

# Head: half-width W and half-depth D at key heights. Between keys a
# smoothstep, so slopes match and no rim creases round the head (the
# alien's bowl cut). The crown rounds in to the bore along a quarter ellipse.
W_KEYS = [(0, 63.0), (12, 55.5), (30, 56.5), (75, 58.0), (98, 57.5)]
D_KEYS = [(0, 60.0), (12, 54.5), (30, 55.5), (75, 57.5), (98, 57.5)]
TOP_R = BORE + 2.6    # the rim ring between bore and crown

N_T = 480             # columns round the head (0.75 deg, ~0.75mm at the face)
DZ = 0.5              # rows

# Bookmark -> head: the bookmark's head is 11.2 wide by 38 tall in its own
# mm; this head is squatter, so it maps non-uniformly. Face center at Z0.
KX, KZ, Z0 = 3.96, 3.0, 66.9
BX0, BY0 = 24.0, 64.5


def bm(x, y):
    return ((x - BX0) * KX, Z0 - (y - BY0) * KZ)


# --- 2D artwork --------------------------------------------------------------
def path(d, samples=24):
    """Points along an absolute M/L/C/Z path (the bookmark's dialect)."""
    tok = d.replace(",", " ").split()
    pts, i, cur = [], 0, None
    while i < len(tok):
        c = tok[i]
        if c in "ML":
            cur = (float(tok[i + 1]), float(tok[i + 2]))
            pts.append(cur)
            i += 3
        elif c == "C":
            p = [cur] + [(float(tok[i + 1 + 2 * k]), float(tok[i + 2 + 2 * k])) for k in range(3)]
            for t in np.linspace(0, 1, samples + 1)[1:]:
                u = 1 - t
                pts.append(tuple(u ** 3 * np.array(p[0]) + 3 * u * u * t * np.array(p[1])
                                 + 3 * u * t * t * np.array(p[2]) + t ** 3 * np.array(p[3])))
            cur = pts[-1]
            i += 7
        elif c == "Z":
            i += 1
        else:
            raise ValueError(c)
    return pts


def art(d, samples=24):
    """A bookmark path, closed, mapped onto the head's front."""
    return Polygon([bm(*p) for p in path(d, samples)]).buffer(0)


def mirror_x(g):
    return affinity.scale(g, -1, 1, origin=(0, 0))


def sym(g):
    return unary_union([g, mirror_x(g)])


def face_2d():
    """The white, seen from the front: face less the black features, plus
    the white set inside them (pupils, fangs)."""
    ax, bz = 9.6 * KX, 14.2 * KZ
    oval = []
    for t in np.linspace(0, 2 * math.pi, 240, endpoint=False):
        x, z = ax * math.sin(t), bz * math.cos(t)
        if z < 0:  # the jaw narrows to a pointed chin
            u = -z / bz
            x *= 1 - 0.32 * u ** 2
            z -= 3.0 * u ** 4
        oval.append((x, Z0 + z))
    oval = Polygon(oval)
    hairline = art("M 14.2,57.5 L 18.4,50.8 L 24,57 L 29.6,50.8 L 33.8,57.5 L 36,95 L 12,95 Z")
    face = oval.intersection(hairline)

    brow = art("M 16.6,58.2 C 19,58.4 21.2,59.4 23.1,61.4 L 22.5,62.5 C 20.6,61.1 18.6,60.4 16.3,60.0 Z")
    eye = art("M 16.9,65.0 C 18.4,63.4 20.9,63.5 22.4,65.1 C 20.9,66.1 18.4,66.3 16.9,65.0 Z")
    crease = LineString([bm(24, 61.4), bm(24, 63.4)]).buffer(1.0, cap_style="round")
    pupil = Point(bm(19.9, 64.85)).buffer(2.6)

    # the mouth: a thin open smirk, with two fangs hanging inside it
    mw = 13.0
    top = [(x, 39.5 + 1.2 * (x / mw) ** 2) for x in np.linspace(-mw, mw, 41)]
    bot = [(x, 39.5 + 1.2 * (x / mw) ** 2 - 7.0 * (1 - (x / mw) ** 2)) for x in np.linspace(mw, -mw, 41)]
    mouth = Polygon(top + bot)
    fang = Polygon([(4.4, 41.5), (8.6, 41.5), (6.9, 34.6)])

    black = unary_union([sym(brow), sym(eye), crease, mouth])
    white = unary_union([face.difference(black), sym(pupil), sym(fang).intersection(mouth.buffer(-0.01))])
    return off_grid(white), face


def off_grid(g):
    """Move the outline off the head's grid. A point within a
    micron of a row makes two vertices the 3-decimal lint (and a slicer)
    merge into one: 4-way edges on a sound mesh (z 56 and 83, 2026-10-28)."""
    def f(x, z):
        # and 14 microns sideways: the head's grid is mirror-symmetric, so a
        # symmetric outline that grazes a grid point on one side grazes its
        # mirror too (x = +-35.98, z 56)
        x = np.asarray(x, float) + 0.0137
        z = np.asarray(z, float).copy()
        near = np.abs(z / DZ - np.round(z / DZ)) * DZ < 0.01
        z[near] += 0.02
        return x, z
    return shapely.transform(g, lambda c: np.column_stack(f(c[:, 0], c[:, 1])))


# Ear, in its own plane: h runs out from the head, v is height. The bottom
# edge climbs at 60+ deg so the plate's underside prints; the base reaches
# back into the head so it is buried, not touching.
EAR = [(-9, 56.13), (0, 58.13), (8, 72.13), (16, 88.13), (22, 104.13), (15, 96.13), (8, 91.63), (0, 88.13), (-9, 88.13)]
# (every height 0.13 off the head's 0.5mm rows, so no ear edge lands on a row edge)
EAR_THETA = 50.0      # where it leaves the head, deg from the front
EAR_SWEEP = 60.0      # turned back from straight out, so the ear lies along the head
EAR_T = 4.0


# --- the head ----------------------------------------------------------------
def smooth_keys(keys, z):
    zs = np.array([k[0] for k in keys])
    vs = np.array([k[1] for k in keys])
    out = np.empty_like(z)
    for n, zz in enumerate(z):
        if zz <= zs[0]:
            out[n] = vs[0]
        elif zz >= zs[-1]:
            out[n] = vs[-1]
        else:
            i = np.searchsorted(zs, zz) - 1
            u = (zz - zs[i]) / (zs[i + 1] - zs[i])
            out[n] = vs[i] + (vs[i + 1] - vs[i]) * u * u * (3 - 2 * u)
    return out


def crown(r, z):
    """Quarter ellipse from the top key in to TOP_R at the rim."""
    z_s = W_KEYS[-1][0]
    b = SHELL_H - z_s
    u = np.clip((z - z_s) / b, 0, 1)
    return np.where(z > z_s, TOP_R + (r - TOP_R) * np.sqrt(1 - u * u), r)


def gauss(x, z, x0, z0, sx, sz):
    return np.exp(-((x - x0) / sx) ** 2 - ((z - z0) / sz) ** 2)


def base_radius(T, Z):
    W = crown(smooth_keys(W_KEYS, Z[:, 0]), Z[:, 0])[:, None]
    D = crown(smooth_keys(D_KEYS, Z[:, 0]), Z[:, 0])[:, None]
    return 1 / np.sqrt((np.sin(T) / W) ** 2 + (np.cos(T) / D) ** 2)


def relief(X, Z):
    """Bumps on the front, in front-view mm. Clamped from below afterwards."""
    in_face = np.clip(1 - (np.abs(X) - 30) / 8, 0, 1)
    brow = 3.0 * gauss(X, Z, 0, 80, 34, 4.5) * in_face
    sockets = -1.6 * (gauss(X, Z, 16.5, 66, 8, 4.5) + gauss(X, Z, -16.5, 66, 8, 4.5))
    cheeks = 2.0 * (gauss(X, Z, 25, 55, 7, 7) + gauss(X, Z, -25, 55, 7, 7))
    nose_len = np.clip((76 - Z) / 24, 0, 1)                   # grows down the bridge
    nose = 5.5 * nose_len ** 1.5 * np.exp(-(X / 4.2) ** 2) * (Z > 50.5) \
        + 5.5 * np.exp(-(X / 4.2) ** 2 - ((Z - 50.5) / 1.2) ** 2) * (Z <= 50.5)
    chin = 4.5 * gauss(X, Z, 0, 28, 9, 6)
    return brow + sockets + cheeks + nose + chin


def clamp_overhang(R, dz, limit_deg):
    """R may not grow faster than tan(limit) per unit height, column by column:
    every underside becomes a printable slope and nothing starts in the air."""
    s = math.tan(math.radians(limit_deg)) * dz
    R = R.copy()
    for j in range(1, R.shape[0]):
        R[j] = np.minimum(R[j], R[j - 1] + s)
    return R


def head():
    t = np.linspace(0, 2 * math.pi, N_T, endpoint=False)
    z = np.arange(0, SHELL_H + 1e-6, DZ)
    z[-1] = SHELL_H
    T, Z = np.meshgrid(t, z)
    R0 = base_radius(T, Z)
    X = R0 * np.sin(T)
    front = np.cos(T) > 0
    R = R0 + np.where(front, relief(X, Z), 0)
    R = clamp_overhang(R, DZ, LIMIT)
    # the top rows round in to the rim and must not be pushed out by relief
    R[-1] = np.minimum(R[-1], TOP_R)
    return t, z, R


def check_head(t, z, R):
    worst = np.max(np.diff(R, axis=0) / DZ)
    assert math.degrees(math.atan(worst)) <= LIMIT + 1e-6, f"overhang {math.degrees(math.atan(worst)):.1f} deg"
    # black wall round the reservoir, behind the white skin
    low = z <= SHELL_H - 6
    thin = R[low].min() - SKIN - R_RES
    assert thin >= MIN_WALL, f"wall behind the white only {thin:.2f}mm"
    assert R[-1].min() - BORE >= 2.4, f"rim ring {R[-1].min() - BORE:.2f}mm"
    return math.degrees(math.atan(worst)), thin


# --- the collar --------------------------------------------------------------
# A stand-up cape collar round the back, flaring out at COLLAR_FLARE from
# vertical (its inside face is that overhang). Its front ends rise to points
# behind the ears, like the bookmark's.
COLLAR_FROM = 64.0    # deg from the front where it starts, each side
COLLAR_FLARE = 15.0
COLLAR_R0 = 50.0      # inside radius at its foot, buried in the cape
COLLAR_Z0 = 10.0
COLLAR_T = 3.0
COLLAR_TIP, COLLAR_BACK = 134.0, 118.0


def collar_top(phi):
    """Top edge height, phi = 0 at a front point to 1 at the back."""
    return COLLAR_BACK + (COLLAR_TIP - COLLAR_BACK) * (1 - phi) ** 1.6


def collar():
    a0, a1 = math.radians(COLLAR_FROM), math.radians(360 - COLLAR_FROM)
    # columns half-way between the head's, so no collar edge lands on a head
    # edge: at 93 deg both had one, and the 3-decimal lint merged them
    step = 2 * math.pi / N_T
    th = np.concatenate([[a0], np.arange(a0 - a0 % step + step / 2, a1, step), [a1]])
    s = np.linspace(0, 1, 60)
    k = math.tan(math.radians(COLLAR_FLARE))
    rings = []
    for a in th:
        phi = 1 - abs(math.pi - a) / (math.pi - a0)
        zt = collar_top(phi)
        zz = COLLAR_Z0 + s * (zt - COLLAR_Z0)
        rin = COLLAR_R0 + k * (zz - COLLAR_Z0)
        rings.append((a, zz, rin))
    return rings


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


def collar_mesh(rings):
    ns = len(rings[0][1])
    V, F = [], []
    for a, zz, rin in rings:
        for r_off in (0.0, COLLAR_T):
            for zj, rj in zip(zz, rin):
                r = rj + r_off
                V.append((r * math.sin(a), -r * math.cos(a), zj))
    per = 2 * ns

    def idx(i, side, j):
        return i * per + side * ns + j

    n = len(rings)
    for i in range(n - 1):
        for j in range(ns - 1):
            for side, flip in ((0, True), (1, False)):
                a, b = idx(i, side, j), idx(i + 1, side, j)
                c, d = idx(i, side, j + 1), idx(i + 1, side, j + 1)
                F += [(a, d, b), (a, c, d)] if flip else [(a, b, d), (a, d, c)]
        for j, flip in ((0, False), (ns - 1, True)):   # foot and top edge
            a, b = idx(i, 0, j), idx(i + 1, 0, j)
            c, d = idx(i, 1, j), idx(i + 1, 1, j)
            F += [(a, d, b), (a, c, d)] if flip else [(a, b, d), (a, d, c)]
    for i, flip in ((0, True), (n - 1, False)):         # the two front ends
        for j in range(ns - 1):
            a, b = idx(i, 0, j), idx(i, 0, j + 1)
            c, d = idx(i, 1, j), idx(i, 1, j + 1)
            F += [(a, d, b), (a, c, d)] if flip else [(a, b, d), (a, d, c)]
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
    return f"polyhedron(points=[{pts}], faces=[{fcs}], convexity=6);"


def scad_polygon(g):
    polys = list(g.geoms) if isinstance(g, MultiPolygon) else [g]
    out = []
    for p in polys:
        rings = [p.exterior] + list(p.interiors)
        pts, paths = [], []
        for ring in rings:
            c = list(ring.coords)[:-1]
            paths.append(list(range(len(pts), len(pts) + len(c))))
            pts += c
        out.append("polygon(points=[" + ",".join(f"[{x:.3f},{y:.3f}]" for x, y in pts)
                   + "], paths=" + str(paths) + ");")
    return "union() {\n  " + "\n  ".join(out) + "\n}"


def main():
    t, z, R = head()
    worst, wall = check_head(t, z, R)
    white, face = face_2d()
    hv, hf = grid_mesh(t, z, R)
    cv, cf = grid_mesh(t, z, R - SKIN)
    kv, kf = collar_mesh(collar())
    assert signed_volume(kv, kf) != 0

    # where the ears leave the head: the surface at EAR_THETA, mid-ear
    ia = int(round(math.radians(EAR_THETA) / (2 * math.pi) * N_T))
    ja = int(round(72 / DZ))
    ear_at = (R[ja, ia] * math.sin(t[ia]), -R[ja, ia] * math.cos(t[ia]))

    out = [
        "// GENERATED by dracula.py - do not edit; change dracula.py and re-run it.",
        f"dracula_for_h = {SHELL_H};",
        f"dracula_for_r_res = {R_RES};",
        f"dracula_for_bore = {BORE};",
        f"dracula_skin = {SKIN};",
        "dracula_ear = [" + ",".join(f"[{h},{v}]" for h, v in EAR) + "];",
        f"dracula_ear_at = [{ear_at[0]:.3f}, {ear_at[1]:.3f}];",
        f"dracula_ear_sweep = {EAR_SWEEP};",
        f"dracula_ear_t = {EAR_T};",
        "module dracula_head() " + scad_polyhedron(hv, hf),
        "module dracula_core() " + scad_polyhedron(cv, cf),
        "module dracula_collar() " + scad_polyhedron(kv, kf),
        "module dracula_white_2d() " + scad_polygon(white),
        "module dracula_face_2d() " + scad_polygon(face),
    ]
    Path(__file__).with_name("dracula_shapes.scad").write_text("\n".join(out) + "\n")
    bx = white.bounds
    print(f"dracula_shapes.scad: worst overhang {worst:.1f} deg, wall behind white {wall:.2f}mm, "
          f"white spans z {bx[1]:.1f}..{bx[3]:.1f} ({(bx[3] - bx[1]) / LAYER:.0f} layers at {LAYER}mm before the ears)")


if __name__ == "__main__":
    main()
