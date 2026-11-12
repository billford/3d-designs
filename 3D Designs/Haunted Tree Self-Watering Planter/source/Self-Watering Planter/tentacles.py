"""Lovecraftian tentacles for the planter's stone shell -> tentacles.scad.

    .venv/bin/python tentacles.py

Each tentacle is a tube swept along a path drawn on the shell's surface,
thick and ringed at the root, thin and curled at the tip, like Cthulhu's.

WHY THE TUBES SINK AND SURFACE. The shell prints upright, so the underside of
every tube is an overhang. A tube climbing at elevation phi has surface
normals at most cos(phi) downward, so above ~46 degrees all of it prints. Where
the path runs flatter, only a shallow cap of the tube may stand proud of the
stone: a cap whose edge meets the wall at psi0 overhangs by
asin(sin(psi0) * cos(phi)), so the tube is sunk until that is within the
limit. Steep runs stand out in the round and flat runs (the curls) become
relief. Every point is checked, not reasoned: see check_overhang().

ONLY THE PART THAT SHOWS IS BUILT. Each cross-section is the visible arc of
the circle, closed by a chord 0.4mm inside the stone (below the groove floor
where a tentacle crosses a course joint). So each tentacle is ONE polyhedron
that meets the stone at a clear angle. The first version swept full tubes in
overlapping segments; their skins crossed at a grazing angle at every joint
and left ~400 sliver edges the lint flagged (2026-10-27). A curl must then not
touch itself, which check() asserts on the footprints.
"""
import math
from pathlib import Path
import numpy as np

# --- must match planter.scad (it asserts these back) ---
APOTHEM = 56.0        # stone_ap: the stone's inscribed radius, tubes sit on it
SHELL_H = 115.88      # shell_h: the rim
INNER_KEEP = 52.3     # lip_r + seat_fit + 1: nothing above the rim reaches inside this
COURSES = [38, 79]    # courses: the V-grooves round the stone
COURSE_D = 2          # course_d
CHORD_IN = 0.4        # how far the buried chord sits inside the stone (>= 0.4 overlap)

LIMIT = 42.0          # design overhang, degrees from vertical: 46.4 at 0.2mm, less margin
STEP = 0.7            # path resampling, mm
SIDES = 24            # facets round each tube
RING_A = 0.07         # ring amplitude, fraction of radius
RING_L = 1.5          # ring wavelength, multiples of radius
MIN_TIP_R = 0.8       # 1.6mm across: just over min_feat

# Each tentacle: control points as (degrees round the stone, z), its radius at
# the root (r0), where its end begins (rm) and at the tip (r1); then the end:
#   ("curl", turns, r_start, r_end)  a spiral lying on the stone
#   ("rise", height, lean)           climbs free above the rim, leaning out
# emerge=True starts it buried in the stone, coming out of a crack, instead of
# rising out of the ground.
TENTACLES = [
    dict(pts=[(20, -3), (35, 30), (25, 60), (45, 90), (52, SHELL_H)],
         r0=12, rm=4, r1=1.2, end=("rise", 20, 15)),
    dict(pts=[(115, -3), (126, 25), (110, 55), (122, 78)],
         r0=11, rm=5.5, r1=1.4, end=("curl", 0.8, 12, 4)),
    dict(pts=[(205, -3), (194, 35), (214, 70), (200, 100), (196, SHELL_H)],
         r0=12, rm=4, r1=1.2, end=("rise", 16, 12)),
    dict(pts=[(295, -3), (306, 22), (291, 46)],
         r0=10, rm=5, r1=1.4, end=("curl", 0.8, 10, 3.5)),
    dict(pts=[(248, 70), (257, 84), (252, 96)],
         r0=5, rm=4, r1=1.0, end=("curl", 0.8, 7, 2.5), emerge=True),
    dict(pts=[(346, 34), (338, 48), (342, 58)],
         r0=5, rm=4, r1=1.0, end=("curl", 0.8, 7, 2.5), emerge=True),
]
WRINKLE_A, WRINKLE_L = 0.03, 0.45   # fine skin wrinkles: amplitude, wavelength x radius
SWELL_A, SWELL_L = 0.08, 25.0       # slow swellings along the length, mm


def catmull(pts, step):
    """Catmull-Rom through the points, resampled evenly by arc length."""
    p = np.array(pts, float)
    p = np.vstack([2 * p[0] - p[1], p, 2 * p[-1] - p[-2]])
    fine = []
    for i in range(1, len(p) - 2):
        a, b, c, d = p[i - 1], p[i], p[i + 1], p[i + 2]
        for t in np.linspace(0, 1, 60, endpoint=False):
            fine.append(0.5 * (2 * b + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t * t
                               + (3 * b - a - 3 * c + d) * t ** 3))
    fine.append(p[-2])
    return resample(np.array(fine), step)


def resample(q, step):
    s = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(q, axis=0), axis=1))])
    n = max(2, int(s[-1] / step) + 1)
    t = np.linspace(0, s[-1], n)
    return np.stack([np.interp(t, s, q[:, k]) for k in range(q.shape[1])], axis=1)


def path(t):
    """Center line samples as (u, z, out): out is extra radial offset, mm."""
    uz = catmull([(math.radians(a) * APOTHEM, z) for a, z in t["pts"]], STEP)
    out = np.zeros(len(uz))
    kind = t["end"][0]
    # carry on in the direction the path ends in
    d = uz[-1] - uz[-2]
    d /= np.linalg.norm(d)
    if kind == "curl":
        turns, ra, rb = t["end"][1:]
        # spiral starts tangent to the path, center to the side it is already bending
        bend = (uz[-1] - uz[-6]) - (uz[-6] - uz[-11])
        nrm = np.array([-d[1], d[0]])
        nrm = nrm if np.dot(nrm, bend) >= 0 else -nrm
        center = uz[-1] + nrm * ra
        a0 = math.atan2(*(uz[-1] - center)[::-1])
        k = np.linspace(0, 1, int(2 * math.pi * turns * (ra + rb) / 2 / STEP))[1:]
        # wind the way the path is already heading, or it doubles back in a cusp
        rot = 1 if np.dot([-math.sin(a0), math.cos(a0)], d) > 0 else -1
        ang = a0 + rot * 2 * math.pi * turns * k
        rr = ra + (rb - ra) * k
        sp = center + np.stack([rr * np.cos(ang), rr * np.sin(ang)], axis=1)
        split = len(uz)
        uz = np.vstack([uz, sp])
        out = np.zeros(len(uz))
    else:
        rise, lean = t["end"][1:]
        n = int(rise / STEP)
        h = np.linspace(0, rise, n + 1)[1:]
        ext = uz[-1] + np.outer(h, d / d[1])          # keep the climb's sideways drift
        ext[:, 1] = uz[-1][1] + h
        split = len(uz)
        uz = np.vstack([uz, ext])
        # lean eased in over the first 8mm: a sudden kink folds the tube
        ease = np.where(h < 8, h * h / 16, h - 4)
        out = np.concatenate([np.zeros(len(uz) - n), ease * math.tan(math.radians(lean))])
    return uz, out, split


def radius(s, s_split, t):
    """Root to rm along the body, rm to the tip along the end; a flare where it
    erupts from the ground, slow swellings and fine wrinkles all along."""
    total = s[-1]
    body = t["rm"] + (t["r0"] - t["rm"]) * np.clip(1 - s / s_split, 0, 1) ** 1.2
    end = t["r1"] + (t["rm"] - t["r1"]) * np.clip(1 - (s - s_split) / (total - s_split), 0, 1) ** 0.8
    r = np.where(s < s_split, body, end)
    if not t.get("emerge"):
        r = r * (1 + 0.3 * np.exp(-np.maximum(s, 0) / 6))
    r = r * (1 + SWELL_A * np.sin(2 * math.pi * s / SWELL_L + len(t["pts"])))
    return r * (1 + WRINKLE_A * np.sin(2 * math.pi * s / (WRINKLE_L * r)))


def cover(x, A=36):
    """A smooth curve that is >= x everywhere: a running max reaching A rings
    each way, then three box averages of radius A/3 (close to a Gaussian).
    Every value averaged lies within A rings, so none is below x there."""
    y = np.array([x[max(0, i - A):i + A + 1].max() for i in range(len(x))])
    b = A // 3
    for _ in range(3):
        y = np.convolve(np.pad(y, b, mode="edge"), np.ones(2 * b + 1) / (2 * b + 1), mode="valid")
    return y


def sweep(t):
    uz, out, split = path(t)
    th = uz[:, 0] / APOTHEM
    radial = np.stack([np.cos(th), np.sin(th), 0 * th], axis=1)
    surf = np.stack([APOTHEM * np.cos(th), APOTHEM * np.sin(th), uz[:, 1]], axis=1)
    T = np.gradient(surf, axis=0)
    T /= np.linalg.norm(T, axis=1)[:, None]
    s = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(surf, axis=0), axis=1))])
    R = np.maximum(radius(s, s[split], t), MIN_TIP_R)
    # how deep each section must sit: see the module docstring. On the wall the
    # ring's outward axis is horizontal, so the skin at angle psi from it faces
    # down by |sin psi| cos(phi); where the radius changes along the path (g =
    # dR/ds) the skin also tips by g toward the direction of travel, which adds
    # g * Tz downward. Solve for the widest psi0 that stays inside the limit.
    cphi = np.sqrt(np.maximum(0, 1 - T[:, 2] ** 2))
    g = np.gradient(R, s)
    sl = math.sin(math.radians(LIMIT))
    num = sl * np.sqrt(1 + g * g) - g * T[:, 2]
    psi0 = np.where(num <= 0, 0.0,
           np.where(cphi <= num, math.pi / 2, np.arcsin(np.clip(num / np.maximum(cphi, 1e-9), 0, 1))))
    need = np.maximum(R * np.cos(psi0), 0.15 * R)
    # never flush: a tube top level with the stone is a tangency and leaves
    # slivers, so a run that may barely show is buried 0.4mm instead
    need = np.where(need > R - 0.4, R + 0.4, need)
    above = uz[:, 1] > SHELL_H                                 # nothing to sink into up there
    need = np.where(above, 0.15 * R, need)
    need = np.where(above, need, np.maximum(need, 0.45 - R))  # thin tips still overlap the stone 0.4
    # The need wiggles with every wrinkle, and following it would wobble the
    # center line until a 25mm tube folds. So: a running max reaching A rings
    # each way, then three box averages of radius A/3. That is smooth (close to
    # a Gaussian) and never shallower than the need at any ring, since every
    # value averaged lies within A rings of it.
    d = cover(need)
    # from 20mm below the rim, ease out so the inner edge clears the pot's lip
    # (the pot has to lift straight out); the wall part still overlaps the stone.
    # A smoothstep, because a linear ramp's corner folded the tube.
    clear = APOTHEM - INNER_KEEP - R - 0.3
    w = np.clip((uz[:, 1] - (SHELL_H - 20)) / 20, 0, 1)
    w = w * w * (3 - 2 * w) * (t["end"][0] == "rise")   # only tips that go past the rim
    d = d - w * cover(np.maximum(0, d - clear), 15)   # smoothed, and still at least the excess
    if t.get("emerge"):   # buried at first, surfacing over 12mm, as if out of a crack
        # (over 15mm it surfaced at a grazing angle, a tangency, and left slivers;
        # over 6mm the center line bent so hard the tube folded; at 10mm the
        # underside came out at 46.3 deg)
        e = np.clip(1 - s / 12, 0, 1)
        d = d + cover(np.maximum(0, R + 0.6 - d), 12) * e * e * (3 - 2 * e)
    center = surf + radial * (out - d)[:, None]
    # the tip closes to nearly a point; done after the depth so the center line
    # does not jump (a sudden step there folded the tube)
    R[-1] = 0.75 * MIN_TIP_R   # blunt: a 0.24mm tip ring crowded 24 vertices into slivers
    # The arc's half-angle: wide enough that its chord lies CHORD_IN inside the
    # stone, deeper across a course groove. Above the rim, nearly the whole round.
    z = uz[:, 1]
    floor = np.where(np.any([np.abs(z - c) < COURSE_D + 2 for c in COURSES], axis=0), COURSE_D, 0)
    # the chord's ends sit R sin(a) to the side, where the round stone has
    # curved away beneath them, so solve with their true radius:
    # (c + R cos a)^2 + (R sin a)^2 <= rt^2
    c = APOTHEM - d + out
    rt = APOTHEM - floor - CHORD_IN
    a = np.arccos(np.clip((rt * rt - c * c - R * R) / (2 * c * R), -1, 1))
    a = np.where(z > SHELL_H - 1, math.pi, a)
    a = np.minimum(a, 0.97 * math.pi)
    return center, R, T, radial, uz, a


def frames(center, radial):
    T = np.gradient(center, axis=0)
    T /= np.linalg.norm(T, axis=1)[:, None]
    N = radial - (radial * T).sum(1)[:, None] * T
    N /= np.linalg.norm(N, axis=1)[:, None]
    return T, N, np.cross(T, N)


def check(t, center, R, radial, uz, a):
    T, N, B = frames(center, radial)
    # 1. no ring may be wider than the path's bend, or the tube folds over itself
    ds = np.linalg.norm(np.gradient(center, axis=0), axis=1)
    k = np.linalg.norm(np.gradient(T, axis=0), axis=1) / ds
    i = int(np.argmax(R * k))
    assert R[i] * k[i] < 0.95, f"tube folds on its bend: R*k = {R[i] * k[i]:.2f} at ring {i}/{len(R)}, z {center[i, 2]:.1f}"
    # 2. overhang of every exposed facet, measured on the tube as built
    psi = np.linspace(0, 2 * math.pi, 72, endpoint=False)
    dRds = np.gradient(R) / ds          # the skin leans by this where the radius changes
    worst, where = 0, None
    for i in range(len(center) - 1):     # the last ring is the capped point
        ps = np.linspace(-a[i], a[i], 72)
        rad_dir = np.cos(ps)[:, None] * N[i] + np.sin(ps)[:, None] * B[i]
        pts = center[i] + R[i] * rad_dir
        nrm = rad_dir - dRds[i] * T[i]
        nrm /= np.linalg.norm(nrm, axis=1)[:, None]
        rr = np.hypot(pts[:, 0], pts[:, 1])
        exposed = (rr > APOTHEM + 0.05) | (pts[:, 2] > SHELL_H)
        down = -nrm[:, 2]
        if exposed.any() and pts[:, 2].min() > 0.5:
            ang = math.degrees(math.asin(np.clip(down[exposed].max(), -1, 1)))
            if ang > worst:
                worst, where = ang, (i, round(float(center[i, 2]), 1), round(float(R[i]), 2))
    # chord buried: both ends of every wall ring's arc inside the stone
    wall = (uz[:, 1] >= 0) & (uz[:, 1] < SHELL_H - 1)   # below the bed is trimmed off
    ends = center + R[:, None] * (np.cos(a)[:, None] * N + np.sin(a)[:, None] * B)
    er = np.hypot(ends[wall, 0], ends[wall, 1])
    j = np.where(wall)[0][int(np.argmax(er))]
    assert er.max() <= APOTHEM - CHORD_IN + 0.05, f"chord shows: r {er.max():.2f} at ring {j}/{len(R)} z {uz[j, 1]:.1f} R {R[j]:.2f} a {math.degrees(a[j]):.0f}"
    # a curl must not touch itself: footprints of rings far apart along the
    # tentacle stay apart on the wall (unrolled u, z)
    s = np.concatenate([[0], np.cumsum(ds[1:])])
    half = R * np.sin(np.minimum(a, math.pi / 2))
    th = np.arctan2(center[:, 1], center[:, 0])
    u = np.unwrap(th) * APOTHEM
    for i in np.where(wall)[0]:
        far = wall & (s - s[i] > 2.5 * (R + R[i]))
        if far.any():
            gap = np.hypot(u[far] - u[i], uz[far, 1] - uz[i, 1]) - half[far] - half[i]
            assert gap.min() > 0.3, f"coils touch: ring {i} at z {uz[i, 1]:.1f}, gap {gap.min():.2f}"
    # 3. above the rim, keep clear of the pot's lip
    hi = center[:, 2] > SHELL_H
    if hi.any():
        inner = (np.hypot(center[hi, 0], center[hi, 1]) - R[hi]).min()
        assert inner >= INNER_KEEP, f"tip reaches r {inner:.1f}, inside the lip"
    # 4. it has to join the stone: >= 0.4mm into it wherever it is on the wall
    wall = ~hi
    pen = APOTHEM - (np.hypot(center[wall, 0], center[wall, 1]) - R[wall])
    assert pen.min() >= 0.4, f"tube only {pen.min():.2f}mm into the stone"
    return worst, where


def tube(center, R, radial, a):
    """One closed polyhedron: each ring is the arc -a..a, closed by its chord."""
    T, N, B = frames(center, radial)
    rings = []
    for i in range(len(center)):
        ps = np.linspace(-a[i], a[i], SIDES)
        rings.append(center[i] + R[i] * (np.cos(ps)[:, None] * N[i] + np.sin(ps)[:, None] * B[i]))
    V = np.vstack(rings + [rings[0].mean(0)[None], rings[-1].mean(0)[None]])
    m, n = len(rings), SIDES
    p0, p1 = m * n, m * n + 1
    F = []
    for j in range(m - 1):
        for k in range(n):
            p, q = j * n + k, j * n + (k + 1) % n
            F += [[p, p + n, q + n], [p, q + n, q]]
    for k in range(n):
        F += [[p0, k, (k + 1) % n], [p1, (m - 1) * n + (k + 1) % n, (m - 1) * n + k]]
    return V, F


def main():
    out = [f"// GENERATED by tentacles.py - edit that, not this.\n",
           f"tentacles_for_apothem = {APOTHEM};\ntentacles_for_h = {SHELL_H};\n",
           f"tentacles_for_courses = {COURSES};\ntentacles_for_course_d = {COURSE_D};\n",
           "module tentacles() {\n"]
    for i, t in enumerate(TENTACLES):
        center, R, T, radial, uz, a = sweep(t)
        worst, where = check(t, center, R, radial, uz, a)
        print(f"tentacle {i}: {len(center)} rings, worst exposed overhang {worst:.1f} deg at (ring, z, R) {where}")
        assert worst <= 46.0, f"tentacle {i} overhangs {worst:.1f} deg"
        V, F = tube(center, R, radial, a)
        out.append("  polyhedron(points=[" + ",".join(f"[{x:.4f},{y:.4f},{z:.4f}]" for x, y, z in V)
                   + "], faces=[" + ",".join(f"[{p},{q},{r}]" for p, q, r in F) + "]);\n")
    out.append("}\n")
    Path(__file__).with_name("tentacles.scad").write_text("".join(out))


if __name__ == "__main__":
    main()
