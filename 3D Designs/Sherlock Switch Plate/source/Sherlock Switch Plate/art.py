"""Sherlock Holmes as a rocker (Decora) switch plate: the 2D artwork.

The deerstalker seen straight on, sitting on the plate, and a magnifying glass
held in front of it with one huge eye staring out through the lens. The top
screw is the eye's pupil, ringed by a red iris. The rocker comes through the
plate below. Fourth draft, after the owner's reference photo (2026-10-18): a
deerstalker front-on, a big lens over the face under its peak, a dark wooden
handle angling away. Drawn here in flat colour, not traced from the photo.

The deerstalker itself is Sidney Paget's (1891 on), public domain.

Coordinates are millimetres, y DOWN (like SVG), origin at the switch centre.

    python3 art.py            # view_art.png
    python3 art.py --scad     # also art.scad, read by switchplate.scad
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "Halloween Bookmarks"))

from shapely import affinity  # noqa: E402
from shapely.geometry import box  # noqa: E402
from shapely.ops import unary_union  # noqa: E402

from lib import P, S, Canvas, circle, mirror  # noqa: E402


# ---- the switch: identical to the Poe plate, fitted by gauge 2026-10-16 ----
PLATE_W, PLATE_H = 69.85, 114.3     # 2.75" x 4.5": what a standard plate covers
OPEN_W, OPEN_H = 33.3, 66.7         # the Decora opening
SCREW_Y = 96.8 / 2                  # plate screws 3-13/16" apart
SCREW_DROP = 1.0                    # switchplate.scad screw_drop
MARK = (22.0, 49.0)                 # BX mark centre, lower right, inside the border line
RIM = 3.0                           # beyond the standard plate, all round

# The owner's wall, as for Poe: clear and flat to the viewer's RIGHT for 89mm
# from the switch centre, a door casing about 70-75mm out on the LEFT.
REACH_R, REACH_L = 89.0, 63.0

PW, PH = PLATE_W / 2 + RIM, PLATE_H / 2 + RIM     # half sizes of the plate


def rocker():
    return box(-OPEN_W / 2, -OPEN_H / 2, OPEN_W / 2, OPEN_H / 2)


# ---- the plate: a rounded slab ---------------------------------------------
PLATE = box(-PW + 6, -PH + 6, PW - 6, PH - 6).buffer(6, quad_segs=12)

# ---- the deerstalker, front on --------------------------------------------
# The crown sits on a band at y = -76; the front peak and the folded-down side
# peaks make one wide brim that droops at its tips, as in the reference.
CROWN = P("M -38,-76 C -40,-100 -24,-130 0,-131 C 24,-130 40,-100 38,-76 "
          "C 20,-79 -20,-79 -38,-76 Z")
BRIM = P("M -40,-80 C -50,-74 -57,-64 -59,-55 C -57,-53.5 -54,-53.5 -51,-55 "
         "C -44,-60 -30,-66 0,-67 C 30,-66 44,-60 51,-55 C 54,-53.5 57,-53.5 59,-55 "
         "C 57,-64 50,-74 40,-80 C 20,-77 -20,-77 -40,-80 Z")
# the ear flaps, tied up along the crown's sides
FLAP = P("M -36.5,-80 C -38.5,-96 -33.5,-110 -24.5,-121 L -18.5,-117.5 "
         "C -25.5,-108 -29.5,-95 -29.5,-80 Z")
BUTTON = circle(0, -130.6, 2.6)
BOW = P("M 0,-132.5 C -3,-138 -9,-139.5 -10,-136 C -9.5,-133 -4,-132 0,-132.5 "
        "C 4,-132 9.5,-133 10,-136 C 9,-139.5 3,-138 0,-132.5 Z")
# scaled down about the brim: the lens can't grow (it would run into the
# rocker), so the hat shrinks to keep the reference's proportions
HAT_K, HAT_O = 0.82, (0.0, -70.0)


def ht(g):
    return affinity.scale(g, HAT_K, HAT_K, origin=HAT_O)


CROWN, BRIM, FLAP, BUTTON, BOW = (ht(g) for g in (CROWN, BRIM, FLAP, BUTTON, BOW))
HAT = unary_union([CROWN, BRIM, FLAP, mirror(FLAP, 0), BUTTON, BOW])

# ---- the glass ---------------------------------------------------------------
# Centred above the rocker so its rim clears the rocker's frame, and with the
# eye low in it, as in the photo, so the top screw (0, -SCREW_Y) is the pupil.
LENS_C, LENS_R, RIM_W = (0.0, -59.6), 22.0, 2.8
EYE_C = (0.0, -SCREW_Y)
ROCK_TOP = -OPEN_H / 2 - 3.0            # the top of the rocker's frame line
assert LENS_C[1] + LENS_R <= ROCK_TOP - 1.2, "the lens runs into the rocker's frame"
# the handle angles down to the right, over the plate and out past its edge;
# to the left it would cross the rocker
H_DIR = (0.8, 0.6)
def along(t):
    return (LENS_C[0] + t * H_DIR[0], LENS_C[1] + t * H_DIR[1])
FERRULE = S(f"M {along(LENS_R - 0.5)[0]},{along(LENS_R - 0.5)[1]} L {along(30)[0]},{along(30)[1]}", 7.6)
HANDLE = S(f"M {along(29)[0]},{along(29)[1]} L {along(72)[0]},{along(72)[1]}", 7.0)
COLLAR = S(f"M {along(33.5)[0]},{along(33.5)[1]} L {along(35.5)[0]},{along(35.5)[1]}", 8.2)


def draw():
    lens = circle(*LENS_C, LENS_R)
    outline = unary_union([PLATE, HAT, lens, FERRULE, HANDLE, COLLAR])
    outline = outline.buffer(1.0, join_style=1).buffer(-1.0, join_style=1)
    outline = outline.buffer(-0.8, join_style=1).buffer(0.8, join_style=1)

    c = Canvas(outline, outline.buffer(-1.0))

    # the plate: a single bone line round it, inset, and a frame round the rocker
    c.paint(PLATE.buffer(-3.2).difference(PLATE.buffer(-4.2)), "bone")
    c.paint(rocker().buffer(3.0, join_style=2).difference(rocker().buffer(2.1, join_style=2)), "bone")

    # ---- the hat: tweed, a check of bone and red lines ----
    def tweed(g):
        # a sparse red windowpane check: a full bone-and-red grid read as a cage
        inner = g.buffer(-1.8)
        for x in range(-54, 55, 9):
            c.paint(S(f"M {x},-140 L {x * 0.9},-50", 0.55).intersection(inner), "red")
        for y in range(-128, -50, 9):
            c.paint(S(f"M -62,{y} C -20,{y - 2.5} 20,{y - 2.5} 62,{y}", 0.55).intersection(inner), "red")

    # no bone inside the hat (owner: too much detail): its silhouette and the
    # red check carry it
    c.paint(HAT, "purple")
    tweed(HAT)

    # ---- the glass: dark rim, light face behind the lens ----
    c.paint(lens, "purple")
    c.paint(circle(*LENS_C, LENS_R - 0.9).difference(circle(*LENS_C, LENS_R - 1.7)), "bone")
    face = circle(*LENS_C, LENS_R - RIM_W)
    c.paint(face, "bone")
    ex, ey = EYE_C
    # the brow: heavy, arched, lower at the nose (viewer's right)
    c.paint(P(f"M {ex - 16},{ey - 11} C {ex - 9},{ey - 19} {ex + 5},{ey - 19.5} {ex + 14},{ey - 13.5} "
              f"L {ex + 13.2},{ey - 11} C {ex + 5},{ey - 16} {ex - 8},{ey - 15.6} {ex - 15},{ey - 9} Z"), "purple")
    # the lids: a heavy upper lash line, a fine lower one, a crease above
    upper = S(f"M {ex - 13.5},{ey + 0.6} C {ex - 7},{ey - 8} {ex + 7},{ey - 8.4} {ex + 13.5},{ey}", 1.5)
    lower = S(f"M {ex - 13.5},{ey + 0.6} C {ex - 6},{ey + 6.4} {ex + 7},{ey + 6.2} {ex + 13.5},{ey}", 0.7)
    almond = P(f"M {ex - 13.5},{ey + 0.6} C {ex - 7},{ey - 8} {ex + 7},{ey - 8.4} {ex + 13.5},{ey} "
               f"C {ex + 7},{ey + 6.2} {ex - 6},{ey + 6.4} {ex - 13.5},{ey + 0.6} Z")
    # the iris, round the screw: the screw head is the pupil
    c.paint(circle(ex, ey, 7.2).difference(circle(ex, ey, 3.9)).intersection(almond.buffer(-0.5)), "red")
    c.paint(circle(ex, ey, 3.9), "purple")     # the pupil: the screw hole, so the screw head shows
    c.paint(circle(ex - 4.6, ey - 2.4, 1.1).intersection(almond), "bone")    # glint
    c.paint(upper, "purple")
    c.paint(lower, "purple")
    c.paint(S(f"M {ex - 11.5},{ey - 5.4} C {ex - 5},{ey - 11.4} {ex + 6},{ey - 11.6} {ex + 12},{ey - 6}", 0.55), "purple")
    for k in range(-4, 5):                                 # lashes, fanning out
        x0 = ex + k * 2.9
        y0 = ey - 6.2 + 0.18 * k * k
        c.paint(S(f"M {x0},{y0} L {x0 + k * 0.45},{y0 - 2.6}", 0.55), "purple")
    c.paint(S(f"M {ex - 9},{ey + 9.4} C {ex - 3},{ey + 11.6} {ex + 5},{ey + 11.4} {ex + 11},{ey + 8.4}", 0.5), "purple")
    # the lens's shine, a streak top left
    c.paint(S(f"M {LENS_C[0] - 15.5},{LENS_C[1] - 4} C {LENS_C[0] - 15},{LENS_C[1] - 9} "
              f"{LENS_C[0] - 12},{LENS_C[1] - 13} {LENS_C[0] - 8},{LENS_C[1] - 15.4}", 1.0), "purple")

    # ---- the handle: wood in red, a bone ferrule and collar ----
    c.paint(HANDLE, "red")
    c.paint(FERRULE, "bone")
    c.paint(COLLAR, "bone")
    c.paint(S(f"M {along(31.2)[0]},{along(31.2)[1]} L {along(31.8)[0]},{along(31.8)[1]}", 8.4), "purple")

    # keep the corner clear for the BX mark (switchplate.scad: mark_at)
    c.paint(box(MARK[0] - 10.5, MARK[1] - 5, MARK[0] + 10.5, MARK[1] + 5), "purple")
    c.paint(rocker(), "purple")
    return outline, c


def write_scad(outline, layers, path):
    """2D modules for switchplate.scad, y flipped to point UP."""
    from lib import _scad_poly
    # grown 0.02 so inlays touching at a corner don't leave pinch edges in the plate
    pocket = unary_union([layers["bone"], layers["red"]]).buffer(0.02, quad_segs=4)
    with open(path, "w") as f:
        f.write("// generated by art.py - edit the python, not this file\n\n")
        for name, g in [("outline2d", outline), ("bone2d", layers["bone"]),
                        ("red2d", layers["red"]), ("inlay2d", pocket)]:
            f.write(f"module {name}() {{\n{_scad_poly(g, 0)}\n}}\n\n")


if __name__ == "__main__":
    from lib import render
    outline, c = draw()
    layers = c.final()
    cover = box(-PLATE_W / 2 - RIM, -PLATE_H / 2 - RIM, PLATE_W / 2 + RIM, PLATE_H / 2 + RIM)
    miss = cover.difference(outline).area
    x0, y0, x1, y1 = outline.bounds
    print(f"outline {x1 - x0:.1f} x {y1 - y0:.1f} mm, reaches {-x0:.1f} left / {x1:.1f} right, "
          f"misses {miss:.1f} mm2 of the plate+rim area")
    # the rounded corners leave the rim's own corners uncovered by a few mm2;
    # the standard plate inside is covered
    std = box(-PLATE_W / 2, -PLATE_H / 2, PLATE_W / 2, PLATE_H / 2)
    assert std.difference(outline).area < 0.5, "the plate doesn't cover a standard plate"
    assert x1 <= REACH_R + 0.01, f"reaches {x1:.1f}mm right; the wall is clear to {REACH_R}"
    assert -x0 <= REACH_L + 0.01, f"reaches {-x0:.1f}mm left; the casing starts past {REACH_L}"
    render(outline.difference(rocker()), layers, str(HERE / "view_art.png"), scale=6)
    if "--scad" in sys.argv:
        write_scad(outline, layers, HERE / "art.scad")
