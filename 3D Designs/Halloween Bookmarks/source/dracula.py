"""Bookmark 1: Dracula peering over a dentistry book, wilted roses below."""
from shapely.ops import unary_union

from lib import P, S, Canvas, circle, ellipse, mirror, place, plate, sym, text

CX = 24
BAT = sym(P("M 0,-0.10 L 0.07,-0.30 L 0.12,-0.12 C 0.35,-0.30 0.70,-0.34 1.0,-0.12 "
            "C 0.86,-0.02 0.82,0.08 0.84,0.22 C 0.72,0.10 0.60,0.10 0.52,0.20 "
            "C 0.44,0.08 0.32,0.08 0.24,0.18 C 0.20,0.08 0.14,0.06 0.10,0.10 "
            "C 0.08,0.20 0.04,0.28 0 0.30 Z"), 0)


def wilted_rose(c, x, y, s, rot, petals=True):
    """A drooping, dried rose head hanging down from its stem end (x, y)."""
    head = [
        ("red", P("M -1.2,0 C -1.6,1.4 -1.0,2.8 0,3.2 C 1.0,2.8 1.6,1.4 1.2,0 C 0.5,0.6 -0.5,0.6 -1.2,0 Z")),
        ("red", P("M -1.2,0.2 C -2.3,0.8 -2.6,2.2 -2.0,3.4 C -1.5,2.6 -1.0,1.8 -0.5,1.4 Z")),
        ("red", P("M 1.2,0.2 C 2.3,0.9 2.4,2.4 1.6,3.6 C 1.3,2.6 0.9,1.8 0.5,1.4 Z")),
    ]
    sepal = P("M -1.3,-0.2 C -0.8,0.6 0.8,0.6 1.3,-0.2 L 0.6,0.3 L 0,-0.4 L -0.6,0.3 Z")
    for colour, g in head:
        c.haloed(place(g, x, y, s, rot), colour, 0.35)
    c.paint(place(sepal, x, y, s, rot), "bone")


def draw():
    outline = plate()
    hole = circle(CX, 11.5, 2.6)
    inner = outline.buffer(-3.0)
    c = Canvas(outline, inner)

    # frame + hole ring
    c.paint(outline.buffer(-2.0).difference(outline.buffer(-3.0)), "bone", clip=False)
    c.paint(circle(CX, 11.5, 4.0).difference(hole), "bone", clip=False)

    # blood moon behind his head, bats
    c.outlined(circle(CX, 41, 11), "red", w=0.8)
    for bx, by, s, flip in [(11.5, 26, 6.5, False), (37, 23, 5.2, True), (40.5, 33, 3.6, False)]:
        c.haloed(place(BAT, bx, by, s, -8 if flip else 6, flip), "bone", 0.5)

    # cape body and shoulders
    cape = P("M 3,108 C 7,101 12,98 18,97 L 30,97 C 36,98 41,101 45,108 L 45,127 L 3,127 Z")
    c.outlined(cape, "purple", w=0.9)
    for d in ("M 9.5,108 C 11,113 11.5,118 11,124", "M 38.5,108 C 37,113 36.5,118 37,124",
              "M 15,112 C 15.6,116 15.8,120 15.4,124", "M 33,112 C 32.4,116 32.2,120 32.6,124"):
        c.paint(S(d, 0.6), "bone")
    # shirt front + medallion
    c.paint(P("M 18.5,97 L 29.5,97 L 24,118 Z"), "bone")
    c.paint(S("M 20.5,98 L 24,112 L 27.5,98", 0.7), "purple")
    c.outlined(circle(CX, 109.5, 3.2), "red", w=0.8)
    c.paint(S("M 24,109.5 L 24,109.6", 1.2), "bone")

    # stand-up collar, red lining
    for flip in (False, True):
        collar = P("M 10,103 C 6,88 3.6,66 4.4,47 C 8.5,54 12.5,62 16,74 L 18,98 Z")
        rib = S("M 16.4,95 C 12,80 8.4,64 6.6,53", 0.6)
        if flip:
            collar, rib = mirror(collar, CX), mirror(rib, CX)
        c.outlined(collar, "red", w=0.9)
        c.paint(rib, "bone")

    # head: hair mass (outlined dome), ears, then the face cut by a widow's peak
    dome = P("M 12.8,72 C 11.6,52 15.6,40.8 24,40.4 C 32.4,40.8 36.4,52 35.2,72 Z")
    c.outlined(dome, "purple", w=0.9)
    for d in ("M 21.6,43.4 C 18.6,44.6 16.6,46.6 15.6,49.4", "M 26.4,43.4 C 29.4,44.6 31.4,46.6 32.4,49.4"):
        c.paint(S(d, 0.55), "bone")  # slicked-back comb lines
    for flip in (False, True):
        ear = P("M 14.6,58 C 12.2,57.2 10.2,55.4 9.0,52.2 C 9.6,57 11,62.6 14.8,66.8 Z")
        ear_line = S("M 13.4,61.4 C 12.0,59.8 11.0,58 10.4,56", 0.55)
        if flip:
            ear, ear_line = mirror(ear, CX), mirror(ear_line, CX)
        c.haloed(ear, "bone", 0.45)
        c.paint(ear_line, "purple")
    below_hairline = P("M 14.2,57.5 L 18.4,50.8 L 24,57 L 29.6,50.8 L 33.8,57.5 L 36,95 L 12,95 Z")
    c.paint(ellipse(CX, 64.5, 9.6, 14.2).intersection(below_hairline), "bone")

    # brows, eyes, scowl lines
    brow = P("M 16.6,58.2 C 19,58.4 21.2,59.4 23.1,61.4 L 22.5,62.5 C 20.6,61.1 18.6,60.4 16.3,60.0 Z")
    eye = P("M 16.9,65.0 C 18.4,63.4 20.9,63.5 22.4,65.1 C 20.9,66.1 18.4,66.3 16.9,65.0 Z")
    c.paint(sym(brow, CX), "purple")
    c.paint(sym(eye, CX), "purple")
    c.paint(circle(19.9, 64.85, 0.85), "red")
    c.paint(circle(28.1, 64.85, 0.85), "red")
    c.paint(S("M 24,61.2 L 24,63.6", 0.5), "purple")

    # the book: DENTISTRY
    book = P("M 8.5,69.5 L 39.5,69.5 L 39.5,104 L 8.5,104 Z")
    c.outlined(book, "red", w=1.0)
    c.paint(book.buffer(-2.0).difference(book.buffer(-2.7)), "bone")
    c.paint(text("DENTISTRY", "Georgia", CX, 76.6, height=4.0, width=23.4), "bone")
    tooth = P("M 19.5,84 C 19.4,81.2 22,81 24,82.4 C 26,81 28.6,81.2 28.5,84 "
              "C 28.4,87 27.5,88 27.2,91 C 27,94 26.5,97 25.5,97 C 24.6,97 24.6,93.2 24,93.2 "
              "C 23.4,93.2 23.4,97 22.5,97 C 21.5,97 21,94 20.8,91 C 20.5,88 19.6,87 19.5,84 Z")
    c.paint(tooth, "bone")
    c.paint(S("M 21.3,84.2 C 21.6,83.2 22.4,82.9 23.0,83.3", 0.55), "red")  # shine

    # clawed fingers gripping the cover edges
    for flip in (False, True):  # shadow behind the hands so the collar lines don't fragment
        hand = P("M 3,81 L 8.6,81 L 8.6,97 L 3,97 Z")
        c.paint(mirror(hand, CX) if flip else hand, "purple")
    for flip in (False, True):
        for i, fy in enumerate((84, 89, 94)):
            reach = 13.6 - abs(i - 1) * 0.8
            finger = S(f"M 6.6,{fy} L {reach},{fy}", 3.0)
            nail = P(f"M {reach - 0.2},{fy - 1.2} C {reach + 1.6},{fy - 1.0} {reach + 2.8},{fy} {reach + 3.4},{fy + 0.9} "
                     f"C {reach + 2.2},{fy + 0.9} {reach + 1.2},{fy + 1.1} {reach - 0.2},{fy + 1.2} Z")
            if flip:
                finger, nail = mirror(finger, CX), mirror(nail, CX)
            c.haloed(finger, "bone", 0.45)
            c.haloed(nail, "red", 0.4)
            kx = 37.7 if flip else 10.3
            c.paint(S(f"M {kx},{fy - 1.6} L {kx},{fy + 1.6}", 0.5), "purple")  # knuckle

    # banner: FLOSS NIGHTLY
    band = P("M 6.5,122 C 15,120.6 33,120.6 41.5,122 L 41.5,131 C 33,129.6 15,129.6 6.5,131 Z")
    tails = P("M 6.5,123.5 L 3.4,124 L 5.0,127.4 L 3.4,131.2 L 6.5,130.5 Z")
    for t in (tails, mirror(tails, CX)):
        c.haloed(t, "bone", 0.45)
    c.haloed(band, "bone", 0.5)
    c.paint(text("FLOSS NIGHTLY", "Georgia", CX, 125.6, height=3.8, width=31), "purple")

    # wilted roses climbing from the bottom, heads hanging
    stems = [
        ("M 10,174 C 6.6,162 6.4,149 10,141 C 12.6,136 17.4,137 17.6,142.4", (17.6, 142.4), 2.0, 8),
        ("M 38,174 C 41.6,162 41.6,150 38,143 C 35.4,138.6 31.2,139.6 30.8,144.6", (30.8, 144.6), 2.0, -8),
        ("M 24,174 C 25,166 23.6,160 20.8,157.6 C 18.8,156 16.6,157.4 16.4,160.4", (16.4, 160.4), 1.6, 18),
    ]
    for d, (hx, hy), s, rot in stems:
        c.paint(S(d, 1.2), "bone")
        wilted_rose(c, hx, hy, s, rot)
    for tx, ty, d in [(7.0, 156, 1), (7.6, 166, 1), (41.0, 154, -1), (40.4, 165, -1)]:
        c.paint(P(f"M {tx},{ty - 1} L {tx - 1.6 * d},{ty - 1.6} L {tx},{ty + 0.6} Z"), "bone")  # thorns
    leaves = [  # shrivelled, curling leaves with a purple midrib
        ("M 7.2,161 C 8.6,156.4 12,154.8 14.4,155.2 C 12.6,156.6 11,159 7.6,162.4 Z", "M 8.2,160.4 C 9.8,158 11.6,156.6 13.2,155.6"),
        ("M 40.9,158 C 39.5,153.4 36.1,151.8 33.7,152.2 C 35.5,153.6 37.1,156 40.5,159.4 Z", "M 39.9,157.4 C 38.3,155 36.5,153.6 34.9,152.6"),
        ("M 23.8,166 C 28,165.6 30.4,162.6 30.2,160 C 28.4,162.6 26,163.2 24,164 Z", "M 24.6,165.2 C 26.6,164.6 28.4,163.2 29.6,161.4"),
    ]
    for d, rib in leaves:
        c.haloed(P(d), "bone", 0.4)
        c.paint(S(rib, 0.45), "purple")
    for x, y, r in [(20, 169, 30), (31, 167, -40), (34.5, 157, 15), (12.5, 170.5, -20), (27, 152, 60)]:
        c.haloed(ellipse(x, y, 1.6, 0.9, r), "red", 0.35)  # fallen petals

    return outline, hole, c


if __name__ == "__main__":
    import sys
    from lib import render, write_scad
    outline, hole, c = draw()
    layers = c.final()
    render(outline.difference(hole), layers, "out/view_dracula.png")
    if "--scad" in sys.argv:
        write_scad(outline, layers, "out/dracula.scad", hole=hole)
