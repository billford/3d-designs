"""Sherlock Holmes on a two-gang rocker (Decora) switch plate: the 2D artwork.

The plate is a magnifying glass: a big round lens with both rockers in its
glass, the handle running off to the lower right, and the deerstalker resting
on top of the rim, tipped. A riff on the Sherlock Switch Plate (one gang),
reusing its deerstalker. First draft, 2026-10-30.

The deerstalker itself is Sidney Paget's (1891 on), public domain.

Coordinates are millimeters, y DOWN (like SVG), origin at the center between
the two switches.

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


# ---- the switches: two Decora gangs, spec numbers (Poe's, fitted by gauge) ----
PLATE_W, PLATE_H = 115.8, 114.3     # 4.56" x 4.5": what a standard 2-gang plate covers
GANG = 46.04                        # 1.812" between the gangs' centers
OPEN_W, OPEN_H = 33.3, 66.7         # each Decora opening
SCREW_Y = 96.8 / 2                  # plate screws 3-13/16" apart, in line with each opening
SCREW_DROP = 1.0                    # switchplate.scad screw_drop
GANG_X = (-GANG / 2, GANG / 2)


def rockers():
    return unary_union([box(x - OPEN_W / 2, -OPEN_H / 2, x + OPEN_W / 2, OPEN_H / 2) for x in GANG_X])


# ---- the glass ---------------------------------------------------------------
# The lens must cover a standard 2-gang plate: its corners set the radius. They
# fall under the dark rim, which keeps the lens as small as it can be.
RIM_W = 6.0
LENS_R = (PLATE_W ** 2 + PLATE_H ** 2) ** 0.5 / 2 + 1.5
LENS_C = (0.0, 0.0)
GLASS_R = LENS_R - RIM_W

# the handle, down and to the right at 40 degrees below horizontal
H_DIR = (0.766, 0.643)


def along(t):
    return (LENS_C[0] + t * H_DIR[0], LENS_C[1] + t * H_DIR[1])


def bar(t0, t1, w0, w1=None):
    """A square-ended band along the handle, w0 wide at t0 tapering to w1."""
    w1 = w0 if w1 is None else w1
    nx, ny = -H_DIR[1], H_DIR[0]
    (x0, y0), (x1, y1) = along(t0), along(t1)
    return P(f"M {x0 + nx * w0 / 2},{y0 + ny * w0 / 2} L {x1 + nx * w1 / 2},{y1 + ny * w1 / 2} "
             f"L {x1 - nx * w1 / 2},{y1 - ny * w1 / 2} L {x0 - nx * w0 / 2},{y0 - ny * w0 / 2} Z")


H0 = LENS_R - 2.0                   # the ferrule starts inside the rim
FERRULE = bar(H0, H0 + 12, 11)
COLLAR = bar(H0 + 12, H0 + 15, 13)
HANDLE = bar(H0 + 15, H0 + 50, 11, 13)
KNOB = circle(*along(H0 + 52), 7.5)

# ---- the deerstalker, from the one-gang plate, front on -----------------------
CROWN = P("M -38,-76 C -40,-100 -24,-130 0,-131 C 24,-130 40,-100 38,-76 "
          "C 20,-79 -20,-79 -38,-76 Z")
BRIM = P("M -40,-80 C -50,-74 -57,-64 -59,-55 C -57,-53.5 -54,-53.5 -51,-55 "
         "C -44,-60 -30,-66 0,-67 C 30,-66 44,-60 51,-55 C 54,-53.5 57,-53.5 59,-55 "
         "C 57,-64 50,-74 40,-80 C 20,-77 -20,-77 -40,-80 Z")
FLAP = P("M -36.5,-80 C -38.5,-96 -33.5,-110 -24.5,-121 L -18.5,-117.5 "
         "C -25.5,-108 -29.5,-95 -29.5,-80 Z")
BUTTON = circle(0, -130.6, 2.6)
BOW = P("M 0,-132.5 C -3,-138 -9,-139.5 -10,-136 C -9.5,-133 -4,-132 0,-132.5 "
        "C 4,-132 9.5,-133 10,-136 C 9,-139.5 3,-138 0,-132.5 Z")
# Resting on the rim: the brim's center (0, -67) sinks SINK into the rim, and
# the hat is tipped TILT degrees toward the viewer's left, about that point.
HAT_K, TILT, SINK, HAT_X = 0.74, -6.0, 2.0, -4.0


def ht(g):
    g = affinity.scale(g, HAT_K, HAT_K, origin=(0, -67))
    g = affinity.translate(g, HAT_X, -LENS_R + SINK + 67)
    return affinity.rotate(g, TILT, origin=(HAT_X, -LENS_R + SINK))


CROWN, BRIM, FLAP, FLAP_R, BUTTON, BOW = (ht(g) for g in (CROWN, BRIM, FLAP, mirror(FLAP, 0), BUTTON, BOW))
HAT = unary_union([CROWN, BRIM, FLAP, FLAP_R, BUTTON, BOW])

# The BX mark: on the hat's crown, low and right of center, where the body
# color is dark. In the bone glass the silver B would barely show.
MARK = (6.0, -98.0)


def draw():
    lens = circle(*LENS_C, LENS_R)
    outline = unary_union([lens, HAT, FERRULE, HANDLE, COLLAR, KNOB])
    outline = outline.buffer(1.5, join_style=1).buffer(-1.5, join_style=1)
    outline = outline.buffer(-0.8, join_style=1).buffer(0.8, join_style=1)

    c = Canvas(outline, outline.buffer(-1.0))

    # ---- the glass: light, inside a dark rim with one bone line in it ----
    c.paint(circle(*LENS_C, GLASS_R), "bone")
    c.paint(circle(*LENS_C, LENS_R - 1.6).difference(circle(*LENS_C, LENS_R - 2.6)), "bone")
    # the glass's shine: two dark streaks, top left
    cx, cy = LENS_C
    for r, a0, w in [(GLASS_R - 7, 0, 1.6), (GLASS_R - 12, 6, 0.9)]:
        c.paint(S(f"M {cx - r * 0.97},{cy - r * 0.26 + a0 * 0.1} "
                  f"C {cx - r * 0.9},{cy - r * 0.6} {cx - r * 0.65},{cy - r * 0.85} {cx - r * 0.3},{cy - r * 0.96}", w),
                "purple")
    # frames round the rockers, dark lines in the glass
    c.paint(rockers().buffer(3.0, join_style=2).difference(rockers().buffer(2.0, join_style=2)), "purple")

    # ---- the hat: dark, with the sparse red windowpane check ----
    # a bone line round it where it lies over the lens, so the brim reads
    # apart from the rim it rests on
    c.paint(HAT.buffer(1.0).intersection(circle(*LENS_C, LENS_R - 0.8)), "bone")
    c.paint(HAT, "purple", clip=False)
    inner = HAT.buffer(-1.8)
    hat_tx = lambda g: ht(affinity.translate(g, 0, 0))  # noqa: E731
    for x in range(-54, 55, 9):
        c.paint(hat_tx(S(f"M {x},-140 L {x * 0.9},-50", 0.6)).intersection(inner), "red")
    for y in range(-128, -50, 9):
        c.paint(hat_tx(S(f"M -62,{y} C -20,{y - 2.5} 20,{y - 2.5} 62,{y}", 0.6)).intersection(inner), "red")

    # ---- the handle: wood in red, bone ferrule and collar ----
    c.paint(HANDLE, "red")
    c.paint(KNOB, "red")
    c.paint(FERRULE, "bone")
    c.paint(COLLAR, "bone")
    for t in (H0 + 12, H0 + 15):                      # dark lines either side of the collar
        c.paint(bar(t - 0.4, t + 0.4, 14), "purple")

    # keep room for the BX mark (switchplate.scad: mark_at)
    c.paint(box(MARK[0] - 10.5, MARK[1] - 5, MARK[0] + 10.5, MARK[1] + 5), "purple")
    c.paint(rockers(), "purple")
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
    x0, y0, x1, y1 = outline.bounds
    print(f"lens {2 * LENS_R:.1f} mm across; outline {x1 - x0:.1f} x {y1 - y0:.1f} mm, "
          f"reaches {-x0:.1f} left / {x1:.1f} right / {-y0:.1f} up / {y1:.1f} down")
    assert HAT.buffer(-1.5).contains(box(MARK[0] - 10.5, MARK[1] - 5, MARK[0] + 10.5, MARK[1] + 5)), \
        "the BX mark runs off the hat's crown"
    std = box(-PLATE_W / 2, -PLATE_H / 2, PLATE_W / 2, PLATE_H / 2)
    assert std.difference(circle(*LENS_C, LENS_R - 1.0)).area < 0.5, "the lens doesn't cover a standard plate"
    render(outline.difference(rockers()), layers, str(HERE / "view_art.png"), scale=6)
    if "--scad" in sys.argv:
        write_scad(outline, layers, HERE / "art.scad")
