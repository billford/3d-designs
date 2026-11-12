"""A dragon-scale gift box for a 52 x 61mm egg -> box_base_shape.stl, box_lid_shape.stl.

    python box.py        # needs numpy and manifold3d

Read by dragon_egg_box.scad, which adds the BX mark and is what gets exported.
Same method as Candy Bowl/bowl.py: every surface is a radius field r(theta, z)
on a grid, so the overhang limit can be enforced row by row instead of hoped for.

TWO PRINTS, one plate, no supports, no brim:
  base - upright, open side up. The egg stands in it on its flat bottom.
  lid  - upright, RIM ON THE BED, open side down. Slips over the base's collar
         and rests on the ledge below it.

THE EGG. Measured, not estimated, off the vertex cloud of NUKDDD's "Textured
Twisty Dragon Egg Fidget" as downloaded from MakerWorld,
https://makerworld.com/en/models/2865269-textured-twisty-dragon-egg-fidget
(file twisty_textured_dragon_egg_fidget_16.3mf, 448,540 vertices): 61.38mm
tall, flat-bottomed, widest 26.0mm radius at 22mm up. EGG_R below is the
LARGEST radius of any vertex in each 1mm band, so it is an upper bound on the
textured skin, not an average. The egg's own model is not ours and does not ship.

WHY THE BASE CAVITY ONLY WIDENS GOING UP. It is the egg's profile plus clearance,
carried as a running maximum. Below the widest point it cradles the egg; above
it, it stays at the widest radius, or the egg could not come out. Never
narrowing also means the inside has no overhang anywhere.

WHY THE LID'S CEILING IS A POINT. Over the egg's top the inside is a ceiling,
printed over air. It may narrow by at most tan(LIMIT) per mm, so it is the
egg's top plus clearance, but never steeper than that: a pointed dome, not a
round one. A round ceiling over a 52mm egg would be a bridge.

WHY THE SCALES AND ROPES ARE SAFE. Each is an outward displacement; wherever
one steps outward going up (every scale's free lower edge), fill_overhang()
adds material underneath at LIMIT, so every edge has a sloped underside that
reads as a shadow line. It only ever adds, so it cannot thin a wall.
"""
import math
from pathlib import Path

import numpy as np
from manifold3d import Manifold, Mesh

HERE = Path(__file__).resolve().parent

LAYER = 0.2           # the sliced layer height; everything below is checked against it
LIMIT = 43.0          # deg from vertical: atan(0.42 / (2 * 0.2)) = 46.4, less margin
DZ = 0.2              # one grid row per layer
N_T = 720             # columns: 0.5 deg, 0.3mm round the widest point

# --- the egg (mm). index = mm above its flat bottom; value = max vertex radius in that band
EGG_R = [18.25, 19.51, 19.64, 20.66, 21.74, 22.45, 22.73, 22.64, 23.20, 23.89,
         24.38, 24.79, 24.67, 24.69, 25.07, 25.58, 25.85, 25.86, 25.42, 25.59,
         25.83, 25.97, 26.00, 25.34, 25.36, 25.52, 25.57, 25.54, 25.01, 24.67,
         24.59, 24.63, 24.55, 24.20, 23.45, 23.38, 23.31, 23.19, 22.99, 21.77,
         21.55, 21.40, 21.30, 21.00, 19.72, 19.36, 19.09, 18.83, 18.43, 16.91,
         16.44, 16.21, 15.65, 14.23, 13.24, 12.69, 11.99, 9.68, 8.81, 7.85,
         4.66, 3.11]
EGG_H = 61.38

# --- fits
C_EGG = 1.5           # radial, egg to box: a loose fit, so it drops in and lifts out by its top
C_TOP = 1.5           # the same over the egg's crown
FIT = 0.22            # lid bore over the collar: the UFO dome's proven locating fit (CLAUDE.md)
WALL = 2.4            # 6 lines at 0.42 - the collar and the lid's skirt, the thinnest walls here
FLOOR = 2.4           # under the egg; the BX mark is engraved 0.6 into its underside

# --- heights (base frame, z = 0 on the bed)
Z_LEDGE = FLOOR + 30.0          # where the base's body steps in to the collar: 30mm of egg below it
Z_SEAT = Z_LEDGE + DZ           # the lid's rim sits here, on top of the one-row step
COLLAR_H = 7.0                  # how far the collar reaches up into the lid
Z_TOP = Z_SEAT + COLLAR_H       # top of the base
BORE_H = COLLAR_H + 0.4         # the lid's bore is deeper, so it rests on the ledge, not the collar

R_CAV = max(EGG_R) + C_EGG                  # 27.5: the cavity at its widest
R_COLLAR = R_CAV + WALL                     # 29.9
R_BORE = R_COLLAR + FIT                     # 30.12
R_SEAM = R_BORE + WALL                      # 32.52: base body and lid skirt meet flush here

# --- decoration
SCALE_H = 2.2         # how proud a scale's free edge stands: >= 2mm reads as shadow (CLAUDE.md)
ROPE_A = 2.2          # rope strand height, same reason
ROPE_N = 28           # strands round the band: 7.3mm apart at R_SEAM, each ~3.6mm wide
FEATURE_MIN = 1.2     # CLAUDE.md: smallest reliable relief feature, and the smallest gap

# --- finial
R_NECK = 6.0
NECK_SOLID = 7.0      # solid dome between the ceiling's apex and the neck: the finial's footing
COLLAR_ROPE = 3.2     # a rope collar round the neck, which the orb rises out of
ORB_SEAT_R = 5.0      # the orb's cone leaves the collar's top at this radius, so there is no bare stem
ORB_R = 8.5
ORB_CONE = 40.0       # deg from vertical under the orb: under LIMIT, so its underside prints
TALONS = 4


def smooth(u):
    u = np.clip(u, 0.0, 1.0)
    return u * u * (3 - 2 * u)


def egg_need(z_egg):
    """Radius the egg reaches at height z_egg above its bottom (0 outside it).
    Takes the larger of the two bands either side, so it never under-reads between them."""
    z = np.asarray(z_egg, dtype=float)
    i = np.clip(np.floor(z).astype(int), 0, len(EGG_R) - 1)
    j = np.clip(i + 1, 0, len(EGG_R) - 1)
    r = np.maximum(np.take(EGG_R, i), np.take(EGG_R, j))
    return np.where((z >= 0) & (z <= EGG_H), r, 0.0)


def fill_overhang(R, s):
    """Outside: R may not grow faster than s per row going up; raise what is below."""
    R = R.copy()
    for j in range(R.shape[0] - 2, -1, -1):
        R[j] = np.maximum(R[j], R[j + 1] - s)
    return R


def rope(T, Z, zc, hb, r_ref, n=ROPE_N, a=ROPE_A):
    """A twisted rope band hb tall centred on zc: n helical strands with deep grooves between."""
    w = (Z - zc) / (hb / 2)
    env = np.sqrt(np.clip(1 - w * w, 0, 1))
    phase = n * T + n * (Z - zc) / r_ref                # strands lean at 45 deg
    strand = np.sqrt(0.5 + 0.5 * np.cos(phase))
    return a * env * strand


def scales(T, S, R, s_top, s_bot, row, n, height, s_clip=math.inf):
    """Overlapping dragon scales hanging downward, in rows `row` apart in S (arc length
    along the profile, so scales on the sloping lid are not stretched), n per row,
    alternate rows offset half a scale. Each scale is a shield whose top is flush and
    whose rounded free edge stands `height` proud, with a keel ridge down its middle.
    The max() over overlapping scales puts each one's edge over the top of the one below,
    which is how real scales lie. Nothing is drawn above s_clip, so a row can start
    hidden behind a band and show only its lower edges."""
    d = np.zeros_like(S)
    L = row * 1.75                                           # long enough to overlap the next row
    halfw = math.pi * R / n                                  # mm, half a scale's width at this radius
    k = 0
    while s_top - k * row - L * 0.55 > s_bot - row:
        st = s_top - k * row
        a = T / (2 * math.pi) * n - 0.5 * (k % 2)
        u = 2 * (a - np.round(a))                            # -1..1 across the scale
        c = np.sqrt(np.clip(1 - u * u, 0, 1))
        v = (st - S) / L                                      # 0 at its top, growing downward
        edge = 0.55 + 0.45 * c                               # rounded free edge, longest in the middle
        prog = np.clip(v / edge, 0, 1)
        keel = 0.3 * np.clip(1 - np.abs(u) * halfw / FEATURE_MIN, 0, 1)
        h = height * prog ** 0.7 * (0.72 + 0.28 * c + keel)
        inside = (v >= 0) & (v < edge) & (S >= s_bot) & (S <= s_clip)
        d = np.maximum(d, np.where(inside, h, 0.0))
        k += 1
    return d


def solid(t, z, R):
    """A closed tube from radius rows R[z, theta], capped by a centre vertex at each end."""
    nt, nz = len(t), len(z)
    T, Z = np.meshgrid(t, z)
    V = np.stack([R * np.cos(T), R * np.sin(T), Z], -1).reshape(-1, 3)
    V = np.vstack([V, [[0, 0, z[0]], [0, 0, z[-1]]]])
    bot, top = nz * nt, nz * nt + 1
    j, i = np.meshgrid(np.arange(nz - 1), np.arange(nt), indexing="ij")
    a = (j * nt + i).ravel()
    b = (j * nt + (i + 1) % nt).ravel()
    c, d = a + nt, b + nt
    i = np.arange(nt)
    F = np.vstack([np.stack([a, b, d], 1), np.stack([a, d, c], 1),
                   np.stack([np.full(nt, bot), (i + 1) % nt, i], 1),
                   np.stack([np.full(nt, top), (nz - 1) * nt + i, (nz - 1) * nt + (i + 1) % nt], 1)])
    return Manifold(Mesh(vert_properties=V.astype(np.float32), tri_verts=F.astype(np.uint32)))


def rows(z0, z1):
    n = int(round((z1 - z0) / DZ))
    return z0 + DZ * np.arange(n + 1)


def arc_length(z, r):
    return np.concatenate([[0], np.cumsum(np.hypot(np.diff(z), np.diff(r)))])


# ---------------------------------------------------------------- base
def base_profile(z):
    """Axisymmetric outside of the base, before decoration: plinth, rope, waist, belly, rope."""
    r = np.full_like(z, R_SEAM + 0.5)
    r = np.where(z < 2.0, 37.0, r)                                         # plinth
    r = np.where((z >= 2.0) & (z < 3.6), 37.0 - (z - 2.0) * (3.0 / 1.6), r)  # chamfer in, going up
    r = np.where((z >= 3.6) & (z < 7.6), 34.0, r)                          # under rope A
    waist = 34.0 - 3.0 * smooth((z - 7.6) / 3.0)                           # 34 -> 31
    belly = 31.0 + (R_SEAM + 0.5 - 31.0) * smooth((z - 10.6) / 9.0)        # 31 -> 33, gently out
    r = np.where((z >= 7.6) & (z < 10.6), waist, r)
    r = np.where((z >= 10.6) & (z < 19.6), belly, r)
    r = np.where((z >= 27.4) & (z < Z_LEDGE + DZ / 2), R_SEAM, r)          # under rope B, flush with the lid
    collar = R_COLLAR - np.clip(z - (Z_TOP - 0.6), 0, 0.6)                 # 0.6mm lead-in chamfer
    return np.where(z > Z_LEDGE + DZ / 2, collar, r)


def make_base():
    s = math.tan(math.radians(LIMIT)) * DZ
    t = np.linspace(0, 2 * math.pi, N_T, endpoint=False)
    z = rows(0.0, Z_TOP)
    T, Z = np.meshgrid(t, z)
    R0 = base_profile(Z)
    on_body = Z < Z_LEDGE + DZ / 2
    deco = rope(T, Z, 5.6, 4.0, 34.0) + rope(T, Z, Z_LEDGE - 2.5, 4.6, R_SEAM)
    S = Z                                                                   # the belly is near vertical
    # 9.4mm wide at the belly. The top row starts behind rope B, so its edges cover the band
    # under the rope; without it that band showed only the next row's flush tops, as fluting.
    deco += scales(T, S, R0, 27.2 + 5.6, 9.0, 5.6, 22, SCALE_H, s_clip=27.4)
    R = fill_overhang(np.where(on_body, R0 + deco, R0), s)
    R = np.where(Z > Z_LEDGE + DZ / 2, R0, R)                               # the collar stays exact: it is the fit
    worst = np.max(np.diff(R, axis=0))
    assert worst <= s + 1e-9, f"base outside overhang {math.degrees(math.atan(worst / DZ)):.1f} deg"

    zi = rows(FLOOR, Z_TOP)
    need = egg_need(zi - FLOOR) + C_EGG
    Ri = np.maximum.accumulate(np.maximum(need, need[0]))                   # only ever widens going up
    Ri = np.append(Ri, Ri[-1])
    zi = np.append(zi, Z_TOP + 2)                                           # past the top, so the cut is clean
    Ri2 = np.repeat(Ri[:, None], N_T, 1)
    walls = (R[z >= FLOOR - 1e-9] - Ri2[:-1]).min(1)
    lead_in = zi[:-1] > Z_TOP - 0.6 - 1e-9         # the collar's chamfered top edge: thinner by design
    assert walls[~lead_in].min() >= WALL - 1e-6, f"base wall {walls[~lead_in].min():.2f} < {WALL}"
    assert walls[lead_in].min() >= FEATURE_MIN, f"collar lead-in {walls[lead_in].min():.2f} < {FEATURE_MIN}"
    assert abs(Ri[-1] - R_CAV) < 1e-6, "cavity top is not the egg's widest + clearance"
    return solid(t, z, R) - solid(t, zi, Ri2), R


# ---------------------------------------------------------------- lid
def lid_cavity(lz):
    """The lid's inside: the bore over the collar, then a ceiling narrowing at no more than LIMIT."""
    s = math.tan(math.radians(LIMIT)) * DZ
    need = egg_need(lz + Z_SEAT - FLOOR)
    need = np.where(need > 0, need + C_TOP, 0.0)
    Ri = np.where(lz <= BORE_H, R_BORE, need)
    for j in range(1, len(Ri)):
        Ri[j] = max(Ri[j], Ri[j - 1] - s)
    return Ri


def lid_profile(lz, top):
    """Outside of the lid, before decoration: skirt flush with the base, an onion swell,
    then an ogive narrowing to the finial's neck."""
    r = np.full_like(lz, R_SEAM)
    swell = R_SEAM + 1.6 * np.sin(np.pi * np.clip((lz - 5.0) / 14.0, 0, 1))
    u = np.clip((lz - 12.0) / (top - 12.0), 0, 1)
    ogive = R_NECK + (R_SEAM + 1.6 * np.sin(np.pi * 7 / 14) - R_NECK) * np.cos(u * np.pi / 2) ** 1.25
    r = np.where(lz >= 5.0, swell, r)
    return np.where(lz >= 12.0, ogive, r)


def talon(base_ang, c, r_orb):
    """One talon up the orb's coned underside and over its shoulder, as hulls of spheres
    tapering to the tip. Each sphere's centre sits 0.5 r inside the orb's surface so the
    talon is fused to it (>= 0.4mm overlap), never resting on it."""
    pts = []
    for k, lat in enumerate(np.linspace(-74, 52, 10)):
        rad = 2.6 - 1.85 * (k / 9)                     # 2.6 -> 0.75: tip is 1.5mm across, above FEATURE_MIN
        la = math.radians(lat)
        rr = r_orb + 0.5 * rad
        sway = math.radians(10) * (k / 9)              # a slight curl, like a grip
        a = base_ang + sway
        pts.append(([c[0] + rr * math.cos(la) * math.cos(a), c[1] + rr * math.cos(la) * math.sin(a),
                     c[2] + rr * math.sin(la)], rad))
    out = None
    for (p0, r0), (p1, r1) in zip(pts, pts[1:]):
        # the shared sphere is bumped 0.25mm so consecutive hulls interpenetrate (DESIGN-NOTES: tangency)
        h = Manifold.batch_hull([Manifold.sphere(r0 + 0.25, 24).translate(p0),
                                 Manifold.sphere(r1, 24).translate(p1)])
        out = h if out is None else out + h
    return out


def make_finial(cap_z):
    """A coned orb rising out of the neck collar (top at cap_z), and TALONS talons gripping it.
    The cone's apex is buried in the solid dome, so the orb grows out of the lid, not onto it."""
    apex_z = cap_z - ORB_SEAT_R / math.tan(math.radians(ORB_CONE))
    d = ORB_R / math.sin(math.radians(ORB_CONE))              # apex to centre for a 40 deg tangent cone
    c = [0, 0, apex_z + d]
    out = Manifold.batch_hull([Manifold.sphere(ORB_R, 96).translate(c),
                               Manifold.sphere(0.6, 12).translate([0, 0, apex_z])])
    for k in range(TALONS):
        out = out + talon(2 * math.pi * k / TALONS + math.pi / TALONS, c, ORB_R)
    return out, c[2] + ORB_R


def make_lid():
    s = math.tan(math.radians(LIMIT)) * DZ
    t = np.linspace(0, 2 * math.pi, N_T, endpoint=False)
    # The ceiling's apex is set by the bore narrowing at LIMIT, not by the egg, so derive
    # the neck from it: NECK_SOLID of solid dome over the apex carries the finial.
    probe = rows(0.0, 90.0)
    apex = probe[np.argmax(lid_cavity(probe) < 0.4)]
    lz_top = round((apex + NECK_SOLID) / DZ) * DZ
    cap_z = lz_top + COLLAR_ROPE
    lz = rows(0.0, cap_z)
    Ri1 = lid_cavity(lz)
    assert lid_cavity(rows(0.0, lz_top))[-1] < 0.4 and apex < lz_top - 6, "no solid under the finial"
    R0 = np.maximum(lid_profile(lz, lz_top), Ri1 + WALL)                    # never thinner than WALL
    T, Z = np.meshgrid(t, lz)
    R0g = np.repeat(R0[:, None], N_T, 1)
    S = np.repeat(arc_length(lz, R0)[:, None], N_T, 1)
    s_lo, s_hi = np.interp(7.0, lz, S[:, 0]), np.interp(lz_top - 1.0, lz, S[:, 0])
    # scales run up to the collar, shrinking with the dome and lower near the top, so none
    # is narrower than ~2.3mm or stands proud of a surface it could curl off
    fade = np.clip((R0g - 7.0) / 6.0, 0, 1)
    deco = (rope(T, Z, 2.4, 4.6, R_SEAM) + fade * scales(T, S, R0g, s_hi, s_lo, 5.6, 22, SCALE_H)
            + rope(T, Z, lz_top + COLLAR_ROPE / 2, COLLAR_ROPE, R_NECK, n=10, a=1.4))
    R = fill_overhang(R0g + deco, s)
    worst = np.max(np.diff(R, axis=0))
    assert worst <= s + 1e-9, f"lid outside overhang {math.degrees(math.atan(worst / DZ)):.1f} deg"

    keep = Ri1 >= 0.4
    zi = np.concatenate([[-1.0], lz[keep]])
    Ri = np.concatenate([[R_BORE], Ri1[keep]])
    shrink = np.min(np.diff(Ri[1:]))
    assert shrink >= -s - 1e-9, f"lid ceiling overhang {math.degrees(math.atan(-shrink / DZ)):.1f} deg"
    Ri2 = np.repeat(Ri[:, None], N_T, 1)
    wall = (R[keep] - Ri2[1:]).min()
    assert wall >= WALL - 1e-6, f"lid wall {wall:.2f} < {WALL}"
    finial, top = make_finial(cap_z)
    lid = solid(t, lz, R) - solid(t, zi, Ri2) + finial
    # The talons cut through the collar's flat top and leave slivers under 0.001mm. Exact,
    # but mesh checkers and slicers round to 3dp and count those edges 4-10 times
    # (2026-11-06: 20 edges at z 48.9-51.3, 0 at 6dp). Collapse anything under 0.01mm.
    return lid.simplify(0.01), top


# ---------------------------------------------------------------- checks + output
def egg_proxy():
    """The egg as stacked 1mm discs of its MAX radius per band: bigger than the real egg everywhere."""
    out = None
    for i, r in enumerate(EGG_R):
        h = min(1.0, EGG_H - i)
        c = Manifold.cylinder(h, r, r, 128).translate([0, 0, i])
        out = c if out is None else out + c
    return out


def weld(m, places=3):
    """Snap to the grid mesh checkers and slicers round to, merge, drop collapsed triangles,
    and PROVE the result is watertight at that grid.

    Why (2026-11-06): the talons cross the orb at shallow angles and the boolean leaves
    vertex pairs under 0.001mm apart. Exact, but rounded to 3dp they merge, and the lint
    counted 20-52 edges seen 4-10 times. Moving the talons only moved the edges, and
    Manifold.simplify() did not touch them: they are not short edges, just near neighbours.
    Same job as Web Hand/weld.py, without needing Blender to build."""
    mesh = m.to_mesh()
    V = np.round(np.asarray(mesh.vert_properties)[:, :3].astype(float), places)
    V, inv = np.unique(V, axis=0, return_inverse=True)
    F = inv.reshape(-1)[np.asarray(mesh.tri_verts)]
    F = F[(F[:, 0] != F[:, 1]) & (F[:, 1] != F[:, 2]) & (F[:, 0] != F[:, 2])]
    e = np.sort(np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]]), axis=1)
    _, counts = np.unique(e, axis=0, return_counts=True)
    bad = int((counts != 2).sum())
    assert bad == 0, f"{bad} edges not shared by exactly two triangles at {places}dp"
    return V[F]


def write_stl(m, path):
    tri = weld(m)
    n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    rec = np.zeros(len(tri), dtype=[("n", "<f4", 3), ("v", "<f4", (3, 3)), ("a", "<u2")])
    rec["n"], rec["v"] = n, tri
    with open(path, "wb") as f:
        f.write(b"\0" * 80 + np.uint32(len(tri)).tobytes() + rec.tobytes())
    return len(tri)


def main():
    base, _ = make_base()
    lid, top = make_lid()
    for name, m in (("base", base), ("lid", lid)):
        parts = len(m.decompose())
        assert parts == 1, f"{name} is {parts} separate bodies"

    seated = lid.translate([0, 0, Z_SEAT])
    clash = (base ^ seated).volume()
    assert clash < 1e-3, f"lid and base collide: {clash:.3f} mm3"
    touch = (base ^ lid.translate([0, 0, Z_SEAT - 0.4])).volume()
    assert touch > 50, f"lid does not rest on the ledge ({touch:.1f} mm3 at -0.4)"
    egg = egg_proxy().translate([0, 0, FLOOR])
    for name, m in (("base", base), ("lid", seated)):
        v = (egg ^ m).volume()
        assert v < 1e-3, f"egg hits the {name}: {v:.3f} mm3"

    nb = write_stl(base, HERE / "box_base_shape.stl")
    nl = write_stl(lid, HERE / "box_lid_shape.stl")
    write_stl(base + seated, HERE / "view_assembly.stl")
    write_stl(base + seated + egg, HERE / "view_with_egg.stl")
    for name, m, n in (("base", base, nb), ("lid", lid, nl)):
        lo, hi = m.bounding_box()[:3], m.bounding_box()[3:]
        print(f"{name}: {hi[0]-lo[0]:.1f} x {hi[1]-lo[1]:.1f} x {hi[2]-lo[2]:.1f} mm, "
              f"{m.volume()/1000:.1f} cm3, {n} triangles")
    print(f"closed: {Z_SEAT + top:.1f} mm tall; lid rests at z {Z_SEAT:.1f}; "
          f"egg clearance {C_EGG} radial, {C_TOP} over the crown; lid fit {FIT}")


if __name__ == "__main__":
    main()
