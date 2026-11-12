"""Edgar Allan Poe as a rocker (Decora) switch plate: the 2D artwork.

The plate IS the figure. His coat covers the standard single-gang plate, his
white shirt front frames the rocker, the top screw is a shirt stud and the
bottom one a coat button. A raven sits on his shoulder; his left hand holds
out a human heart (The Tell-Tale Heart).

Coordinates are millimetres, y DOWN (like SVG), origin at the switch centre.
The face, hair and raven are the Halloween Bookmarks Poe, scaled up, so the
two match. That drawing kit is imported from ../Halloween Bookmarks/lib.py.

    python3 art.py            # view_art.png
    python3 art.py --scad     # also art.scad, read by switchplate.scad
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "Halloween Bookmarks"))

from shapely import affinity  # noqa: E402
from shapely.geometry import Polygon, box  # noqa: E402
from shapely.ops import unary_union  # noqa: E402

from lib import P, S, Canvas, circle, ellipse, mirror  # noqa: E402

# ---- the switch: Decora (rocker) single gang, standard plate size --------
# Fitted by gauge on the owner's switch (2026-10-16); switchplate.scad carries the same
# values and asserts this outline covers the plate.
PLATE_W, PLATE_H = 69.85, 114.3     # 2.75" x 4.5": what a standard plate covers
OPEN_W, OPEN_H = 33.3, 66.7         # the Decora opening, 1.31" x 2.63"
SCREW_Y = 96.8 / 2                  # plate screws 3-13/16" apart (Decora), on the centreline
SCREW_DROP = 1.0                    # the bottom one 1mm lower: switchplate.scad screw_drop
BTN_Y = SCREW_Y + SCREW_DROP        # the bottom screw, ringed as a coat button
MARK = (31.0, 54.0)                 # BX mark centre, lower right of the coat
RIM = 3.0                           # coat beyond the standard plate, all round

# ---- the head: bookmark coordinates mapped onto this frame ---------------
K = 1.75                            # bookmark head scale: a caricature's big head
BCX, BCY = 24, 63.5                 # bookmark face centre
FACE_Y = -101.5                     # face centre here
# moustache, mouth and chin line, raised toward the nose: on the first print
# they sat low (owner, 2026-10-15). The nose-to-moustache gap was 2.37mm.
MOUTH_UP = 1.0
# The arm and heart are drawn on the viewer's left and mirrored to the right,
# the raven the other way. On the left, the heart reached 89mm out and sat on
# the door casing, holding the plate off the wall (first print, 2026-10-15).


def head(g):
    """Bookmark geometry -> this frame."""
    g = affinity.translate(g, -BCX, -BCY)
    g = affinity.scale(g, K, K, origin=(0, 0))
    return affinity.translate(g, 0, FACE_Y)


def H(d):
    return head(P(d))


def HS(d, w):
    return head(S(d, w / K))  # stroke widths are given at THIS scale


def rocker():
    return box(-OPEN_W / 2, -OPEN_H / 2, OPEN_W / 2, OPEN_H / 2)


# ---- shapes ----------------------------------------------------------------

COAT = P("M -13,-75 C -22,-71 -34,-68 -40,-63 C -44,-59 -44,-50 -44.5,-40 "
         "L -45.5,58 C -46,62 -44,64 -40,64 L 40,64 C 44,64 46,62 45.5,58 "
         "L 44.5,-40 C 44,-50 44,-59 40,-63 C 34,-68 22,-71 13,-75 Z")

def side(g):
    """Drawn on the viewer's left -> the viewer's right."""
    return mirror(g, 0)


def up(g):
    return affinity.translate(g, 0, -MOUTH_UP)


# his left arm, drawn on the viewer's left and mirrored: sleeve down the coat
# side to the elbow, then the forearm out and up, holding the heart at chest height
# one outline, so its edge line is clean: two overlapping shapes left slivers
ARM = P("M -40,-61 C -48,-55 -52,-40 -53.5,-18 C -56,-21 -59,-25 -62,-27 "
        "L -69,-21 C -65,-12 -61,-1 -57,6 C -54,11 -48,12 -44.6,9 L -44.6,-40 "
        "C -44.6,-50 -43,-57 -40,-61 Z")
CUFF = P("M -70.5,-21.5 L -63.5,-24.5 L -62.2,-21.2 L -69.2,-18.2 Z")
HAND = P("M -71,-22 C -75,-24 -78,-28 -77,-33 L -74,-34 C -73,-30 -70,-28 -66,-27 "
         "L -63,-28 C -61,-26 -62,-23 -65,-22 Z")
THUMB = P("M -66,-27 C -65,-31 -63,-34 -60.5,-34.5 C -59,-34 -59.5,-32 -61,-30.5 "
          "C -62,-29 -63,-27.5 -63,-26 Z")


def heart(cx, cy, s, rot):
    """A human heart, caricatured: lumpy body, aortic arch, vessel stubs."""
    parts = {
        "body": P("M -2,-6 C -9,-9.5 -14,-3 -12,5 C -10.5,11 -4,15.5 2.5,19.5 "
                  "C 7.5,14 12.5,8 11.5,0 C 10.8,-6 5.5,-8.5 -2,-6 Z"),
        "aorta": S("M -1.5,-5 C -3,-11 1,-15.5 5.5,-14 C 9,-12.8 9.5,-9 8.5,-5.5", 5.2),
        "vena": S("M -6.5,-6 L -9,-13.5", 3.6),
        "stub": S("M 1.5,-14.5 L 1.8,-19", 2.6),
        "stub2": S("M 5.5,-15 L 7,-19.5", 2.4),
    }
    lines = {
        "septum": S("M -0.5,-3 C 1,3 1,10 2.5,17", 0.8),
        "artery": S("M 0.6,4 C 4,5.5 7.5,4.8 10.2,2.6", 0.65),
        "artery2": S("M -3.5,-2.5 C -7,0 -9,4 -9.5,8", 0.65),
        "arch": S("M 0.5,-6 C 0,-9.5 2.5,-11.2 5,-10.6 C 6.6,-10.1 7,-8.4 6.6,-6.4", 0.65),
    }
    out = {}
    for k, g in {**parts, **lines}.items():
        g = affinity.scale(g, s, s, origin=(0, 0))
        g = affinity.rotate(g, rot, origin=(0, 0))
        out[k] = affinity.translate(g, cx, cy)
    return out


ARM, CUFF, HAND, THUMB = (side(g) for g in (ARM, CUFF, HAND, THUMB))
HEART = {k: side(g) for k, g in heart(-75, -48, 1.05, -12).items()}

# the bookmark raven, which already faces out on this side, on his right shoulder
RAVEN_D = ("M 12.4,30.0 C 14.4,28.4 16.6,27.4 18.6,27.2 C 19.6,25.2 22.4,24.4 24.2,25.6 "
           "C 25.6,26.6 26.0,28.4 26.4,30.0 C 29.6,31.0 33.4,34.0 36.0,37.4 L 38.8,40.2 "
           "L 35.2,39.8 L 36.0,41.2 L 32.0,40.0 C 29.4,40.6 26.6,40.6 24.6,39.6 "
           "C 22.0,38.2 20.4,35.4 20.0,32.6 L 18.8,32.6 L 19.6,31.4 L 18.4,31.2 "
           "C 16.6,30.9 14.6,30.6 12.4,30.0 Z")
RK, RX, RY = 1.7, -40.0, -61.5      # raven scale; where its feet land


def raven(g):
    g = affinity.translate(g, -26.4, -41.8)
    g = affinity.scale(g, RK, RK, origin=(0, 0))
    return affinity.translate(g, RX, RY)


def draw():
    # hair, face, neck: the silhouette parts of the head
    hair = H("M 12.4,74 Q 8.6,70 10.4,66 Q 8.2,61.6 10.2,58 Q 8.8,53 12,49.4 "
             "Q 12.6,44 17.2,42.2 Q 20.4,40 24,40.6 Q 28.6,40 31.4,42.6 Q 36,44 36.4,49 "
             "Q 39.6,53 38,58 Q 40,62 37.6,66 Q 39.4,70.4 35.6,74 Z")
    below = H("M 15.0,64 C 14.8,58 15.4,52.6 17.4,50.2 C 19.4,47.6 21.6,46.8 24,46.8 "
              "C 26.4,46.8 28.6,47.6 30.6,50.2 C 32.6,52.6 33.2,58 33.0,64 L 36,95 L 12,95 Z")
    face = head(ellipse(BCX, BCY, 9.4, 15.6)).intersection(below)
    neck = box(-8, -76, 8, -64)
    raven_body = raven(P(RAVEN_D))
    heart_solid = unary_union([HEART[k] for k in ("body", "aorta", "vena", "stub", "stub2")])
    heart_solid = Polygon(heart_solid.exterior)   # the arch would leave a hole: a handbag

    outline = unary_union([COAT, ARM, CUFF, HAND, THUMB, hair, face, neck,
                           raven_body, heart_solid])
    # close slivers between touching pieces, then soften every corner a little
    outline = outline.buffer(1.0, join_style=1).buffer(-1.0, join_style=1)
    outline = outline.buffer(-0.8, join_style=1).buffer(0.8, join_style=1)

    c = Canvas(outline, outline.buffer(-1.0))

    # ---- coat ----
    c.outlined(COAT, "purple", w=0.9)
    # shirt front: collar down to the rocker, and a border round it
    bib = P("M -9,-71 L 9,-71 L 21,-36 L 21,36 L -21,36 L -21,-36 Z")
    c.paint(bib, "bone")
    # lapels: coat colour folded back over the shirt, edged in bone
    for flip in (False, True):
        lap = P("M -13,-74 L -9,-71 L -21.6,-36 L -21.6,40 L -27,40 L -27,-38 "
                "C -27,-50 -22,-62 -13,-74 Z")
        lap = mirror(lap, 0) if flip else lap
        c.outlined(lap, "purple", w=0.8)
    # the coat closes below the rocker; a button round the bottom screw
    c.paint(S(f"M -22,40 C -14,42 -8,44 -7,{BTN_Y}", 0.8), "bone")   # into the button, not through it
    c.paint(S(f"M 22,40 C 14,42 8,44 7,{BTN_Y}", 0.8), "bone")
    c.paint(S(f"M 0,{BTN_Y + 6.2} L 0,62", 0.8), "bone")
    c.paint(circle(0, BTN_Y, 5.0).difference(circle(0, BTN_Y, 4.1)), "bone")
    # pockets and seams
    for flip in (False, True):
        for d in ("M -38,22 L -28,22", "M -36,-28 C -35.5,-10 -35.8,10 -36.4,28"):
            g = S(d, 0.7)
            c.paint(mirror(g, 0) if flip else g, "bone")
    # cravat: a black bow with the stud (top screw) below it
    bow = P("M -10,-68 C -6,-70 -2,-66 0,-65 C 2,-66 6,-70 10,-68 "
            "C 11,-64 10,-60 8,-58.5 C 5,-59.5 2,-62 0,-62 C -2,-62 -5,-59.5 -8,-58.5 "
            "C -10,-60 -11,-64 -10,-68 Z")
    c.outlined(bow, "purple", w=0.7)
    c.paint(circle(0, -63.5, 2.0), "purple")
    c.paint(S("M -3,-61 C -5,-56 -7,-52 -8,-48", 1.6), "purple")   # cravat tails
    c.paint(S("M 3,-61 C 5,-56 7,-52 8,-48", 1.6), "purple")
    c.paint(circle(0, -SCREW_Y, 4.6).difference(circle(0, -SCREW_Y, 3.8)), "purple")

    # ---- arm, hand, heart ----
    c.outlined(ARM, "purple", w=0.9)
    c.paint(side(S("M -53.6,-16 C -53.8,-8 -52.5,0 -49.5,4.5", 0.7)), "bone")   # the bend
    c.paint(CUFF, "bone")
    c.haloed(HAND.union(THUMB), "bone", 0.5)
    c.paint(side(S("M -73,-30 C -71,-29 -69,-28.5 -67,-28.5", 0.5)), "purple")   # finger line
    c.haloed(heart_solid, "red", 0.5)
    for k in ("septum", "artery", "artery2", "arch"):
        c.paint(HEART[k], "bone")

    # ---- head (the bookmark's lines) ----
    c.outlined(hair, "purple", w=1.2)
    for d in ("M 11.6,61 Q 12.6,59 12.2,56.4", "M 12.2,68 Q 13.4,66 12.8,63.6",
              "M 36.4,61 Q 35.4,59 35.8,56.4", "M 35.8,68 Q 34.6,66 35.2,63.6",
              "M 20.4,43.6 Q 17,44.8 15.2,48.6", "M 27.4,43.4 Q 31,44.6 32.8,48.2"):
        c.paint(HS(d, 0.8), "bone")
    c.paint(face, "bone")
    c.paint(neck.difference(face).intersection(box(-8, -78, 8, -70)), "bone")
    c.paint(H("M 26.6,47 C 29.8,47.6 31.2,50 30.6,52.6 C 29.8,51 28.4,50.2 26.8,50.4 "
              "C 27.8,49.4 27.6,48 26.6,47 Z"), "purple")
    c.paint(HS("M 19.6,53.4 C 21.4,52.8 23.2,52.9 24.6,53.5", 0.6), "purple")
    c.paint(HS("M 23.4,55.2 C 25,54.8 26.6,54.9 28,55.4", 0.6), "purple")
    c.paint(H("M 16.0,60.4 C 17.6,58.4 20.4,57.2 22.6,57.6 L 22.6,58.8 C 20.4,58.6 18.2,59.6 16.6,61.2 Z"), "purple")
    c.paint(H("M 32.0,59.8 C 30.4,57.8 27.6,56.6 25.4,57.0 L 25.4,58.2 C 27.6,58.0 29.8,59.0 31.4,60.6 Z"), "purple")
    for ex, ey in ((19.6, 63.6), (28.4, 63.2)):
        c.paint(HS(f"M {ex - 3},{ey + 0.4} C {ex - 1.6},{ey - 1.4} {ex + 1.6},{ey - 1.4} {ex + 2.8},{ey + 0.2}", 1.3), "purple")
        c.paint(HS(f"M {ex - 2.2},{ey + 1.2} C {ex - 0.8},{ey + 2.0} {ex + 1.0},{ey + 2.0} {ex + 2.2},{ey + 1.0}", 0.6), "purple")
        c.paint(HS(f"M {ex - 1.8},{ey + 3.0} C {ex - 0.4},{ey + 3.7} {ex + 1.0},{ey + 3.6} {ex + 2.0},{ey + 2.8}", 0.6), "purple")
        c.paint(head(circle(ex - 0.1, ey + 0.4, 1.05)), "purple")
    # new: nose, the moustache, a downturned mouth, chin
    nose = HS("M 24.8,64.5 C 25.4,67 25.9,69.2 25.6,70.4 C 24.9,71.1 23.6,71.1 22.8,70.6", 0.6)
    tache = up(H("M 24,72.6 C 22,72.0 19.4,72.4 17.8,74.6 C 19.8,74.0 21.8,74.2 24,74.8 "
                 "C 26.2,74.2 28.2,74.0 30.2,74.6 C 28.6,72.4 26,72.0 24,72.6 Z"))
    # the bone between them is a printed feature too
    assert nose.distance(tache) >= 1.2, f"nose to moustache {nose.distance(tache):.2f}mm, under 1.2"
    c.paint(nose, "purple")
    c.paint(tache, "purple")
    c.paint(up(HS("M 20.6,76.9 C 22.4,76.2 25.6,76.2 27.4,76.9", 0.6)), "purple")
    c.paint(up(HS("M 22.4,78.6 C 23.4,79.0 24.6,79.0 25.6,78.6", 0.5)), "purple")

    # ---- raven ----
    c.outlined(raven_body, "purple", w=0.9)
    c.paint(raven(P("M 12.4,30.0 C 14.4,28.4 16.6,27.4 18.6,27.2 L 19.0,30.9 "
                    "C 16.8,30.7 14.6,30.5 12.4,30.0 Z")), "bone")
    c.paint(raven(S("M 14.6,29.6 L 18.2,29.6", 0.5 / RK)), "purple")
    c.paint(raven(circle(21.8, 27.9, 0.9)), "red")
    for d in ("M 24.4,31.8 C 28.4,32.8 32.4,35.6 35.4,38.8", "M 25.4,34.6 C 28.2,35.6 30.6,37.4 32.4,39.4"):
        c.paint(raven(S(d, 0.6 / RK)), "bone")

    # keep the corner clear for the BX mark (switchplate.scad: mark_at)
    c.paint(box(MARK[0] - 11, MARK[1] - 6, MARK[0] + 11, MARK[1] + 6), "purple")
    # the rocker comes through here; nothing printed in it
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
    print(f"outline {outline.bounds}, misses {miss:.1f} mm2 of the plate+rim area")
    render(outline.difference(rocker()), layers, str(HERE / "view_art.png"), scale=6)
    if "--scad" in sys.argv:
        write_scad(outline, layers, HERE / "art.scad")
