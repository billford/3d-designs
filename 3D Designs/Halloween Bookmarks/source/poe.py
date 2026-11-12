"""Bookmark 2: Edgar Allan Poe behind a POETRY book, a raven on his head, roses."""
import math

from shapely.geometry import LineString

from lib import P, S, Canvas, circle, ellipse, mirror, place, plate, sym, text

CX = 24
LEAF = P("M 0,0 C 0.3,-0.36 0.72,-0.34 1,0 C 0.72,0.34 0.3,0.36 0,0 Z")


def leaf(c, x, y, length, angle):
    c.haloed(place(LEAF, x, y, length, angle), "bone", 0.35)
    rib = LineString([(0.12, 0), (0.8, 0)])
    c.paint(place(rib, x, y, length, angle).buffer(0.22), "purple")


def rose(c, x, y, r, turn=0.0):
    """Front-facing rose: scalloped red bloom with a purple spiral of petals."""
    lobes = [circle(x + 0.55 * r * math.cos(a), y + 0.55 * r * math.sin(a), 0.5 * r)
             for a in [turn + i * 2 * math.pi / 5 for i in range(5)]]
    bloom = circle(x, y, 0.62 * r).union(lobes[0])
    for l in lobes[1:]:
        bloom = bloom.union(l)
    c.haloed(bloom, "red", 0.45)
    pts = []
    for i in range(0, 161):
        t = i / 160 * 3.2 * math.pi
        rr = 0.06 * r + 0.085 * r * t
        pts.append((x + rr * math.cos(t + turn), y + rr * math.sin(t + turn)))
    c.paint(LineString(pts).buffer(0.26), "purple")


def bud(c, x, y, s, rot):
    g = P("M 0,0 C -0.7,-0.5 -0.7,-1.5 0,-2.2 C 0.7,-1.5 0.7,-0.5 0,0 Z")
    sep = P("M 0,0.2 C -0.9,-0.1 -0.9,-0.8 -0.6,-1.0 L 0,-0.4 L 0.6,-1.0 C 0.9,-0.8 0.9,-0.1 0,0.2 Z")
    c.haloed(place(g, x, y, s, rot), "red", 0.35)
    c.paint(place(sep, x, y, s, rot), "bone")


def draw():
    outline = plate()
    hole = circle(CX, 11.5, 2.6)
    inner = outline.buffer(-3.0)
    c = Canvas(outline, inner)

    c.paint(outline.buffer(-2.0).difference(outline.buffer(-3.0)), "bone", clip=False)
    c.paint(circle(CX, 11.5, 4.0).difference(hole), "bone", clip=False)

    # crescent moon and a few stars
    c.paint(circle(37.5, 25, 5.2).difference(circle(39.6, 23.4, 4.6)), "bone")
    star = P("M 0,-1 C 0.1,-0.2 0.2,-0.1 1,0 C 0.2,0.1 0.1,0.2 0,1 C -0.1,0.2 -0.2,0.1 -1,0 "
             "C -0.2,-0.1 -0.1,-0.2 0,-1 Z")
    for sx, sy, ss in [(10, 22, 1.9), (8.6, 31, 1.2), (29.6, 20.5, 1.3), (40, 36, 1.0)]:
        c.paint(place(star, sx, sy, ss), "bone")

    # coat, shirt, cravat
    coat = P("M 3,112 C 7,105 12,102.5 18,101.5 L 30,101.5 C 36,102.5 41,105 45,112 L 45,127 L 3,127 Z")
    c.outlined(coat, "purple", w=0.9)
    c.paint(P("M 17.5,102 L 30.5,102 L 24,118 Z"), "bone")
    c.paint(P("M 19,103 L 29,103 L 26.4,108.6 L 24,107.4 L 21.6,108.6 Z"), "purple")  # cravat knot
    c.paint(P("M 22.8,107.6 L 25.2,107.6 L 25.8,113 L 24,115 L 22.2,113 Z"), "purple")
    for d in ("M 15.6,103 C 18,108 20,113 21.6,119", "M 32.4,103 C 30,108 28,113 26.4,119"):
        c.paint(S(d, 0.7), "bone")  # lapels
    for d in ("M 9.5,110 C 10.5,115 10.8,119 10.4,124", "M 38.5,110 C 37.5,115 37.2,119 37.6,124"):
        c.paint(S(d, 0.6), "bone")

    # hair: wavy mass bulging over the ears
    hair = P("M 12.4,74 Q 8.6,70 10.4,66 Q 8.2,61.6 10.2,58 Q 8.8,53 12,49.4 "
             "Q 12.6,44 17.2,42.2 Q 20.4,40 24,40.6 Q 28.6,40 31.4,42.6 Q 36,44 36.4,49 "
             "Q 39.6,53 38,58 Q 40,62 37.6,66 Q 39.4,70.4 35.6,74 Z")
    c.outlined(hair, "purple", w=0.9)
    for d in ("M 11.6,61 Q 12.6,59 12.2,56.4", "M 12.2,68 Q 13.4,66 12.8,63.6",
              "M 36.4,61 Q 35.4,59 35.8,56.4", "M 35.8,68 Q 34.6,66 35.2,63.6",
              "M 20.4,43.6 Q 17,44.8 15.2,48.6", "M 27.4,43.4 Q 31,44.6 32.8,48.2"):
        c.paint(S(d, 0.55), "bone")  # wave strands

    # face: high forehead, receding temples
    below = P("M 15.0,64 C 14.8,58 15.4,52.6 17.4,50.2 C 19.4,47.6 21.6,46.8 24,46.8 "
              "C 26.4,46.8 28.6,47.6 30.6,50.2 C 32.6,52.6 33.2,58 33.0,64 L 36,95 L 12,95 Z")
    c.paint(ellipse(CX, 63.5, 9.4, 15.6).intersection(below), "bone")
    # forelock curling onto the forehead
    c.paint(P("M 26.6,47 C 29.8,47.6 31.2,50 30.6,52.6 C 29.8,51 28.4,50.2 26.8,50.4 "
              "C 27.8,49.4 27.6,48 26.6,47 Z"), "purple")
    # worry lines
    c.paint(S("M 19.6,53.4 C 21.4,52.8 23.2,52.9 24.6,53.5", 0.45), "purple")
    c.paint(S("M 23.4,55.2 C 25,54.8 26.6,54.9 28,55.4", 0.45), "purple")

    # brows: heavy, drooping at the outer ends (one a touch higher)
    c.paint(P("M 16.0,60.4 C 17.6,58.4 20.4,57.2 22.6,57.6 L 22.6,58.8 C 20.4,58.6 18.2,59.6 16.6,61.2 Z"), "purple")
    c.paint(P("M 32.0,59.8 C 30.4,57.8 27.6,56.6 25.4,57.0 L 25.4,58.2 C 27.6,58.0 29.8,59.0 31.4,60.6 Z"), "purple")
    # heavy-lidded, melancholy eyes
    for ex, ey in ((19.6, 63.6), (28.4, 63.2)):
        lid = S(f"M {ex - 3},{ey + 0.4} C {ex - 1.6},{ey - 1.4} {ex + 1.6},{ey - 1.4} {ex + 2.8},{ey + 0.2}", 1.0)
        low = S(f"M {ex - 2.2},{ey + 1.2} C {ex - 0.8},{ey + 2.0} {ex + 1.0},{ey + 2.0} {ex + 2.2},{ey + 1.0}", 0.45)
        bag = S(f"M {ex - 1.8},{ey + 3.0} C {ex - 0.4},{ey + 3.7} {ex + 1.0},{ey + 3.6} {ex + 2.0},{ey + 2.8}", 0.45)
        c.paint(lid, "purple")
        c.paint(low, "purple")
        c.paint(bag, "purple")
        c.paint(circle(ex - 0.1, ey + 0.4, 1.05), "purple")

    # the book: POETRY, with a tell-tale heart
    book = P("M 8.5,70.5 L 39.5,70.5 L 39.5,104.5 L 8.5,104.5 Z")
    c.outlined(book, "red", w=1.0)
    c.paint(book.buffer(-2.0).difference(book.buffer(-2.7)), "bone")
    c.paint(text("POETRY", "Georgia", CX, 78.2, height=4.8, width=22), "bone")
    c.paint(S("M 14,82.6 L 34,82.6", 0.6), "bone")
    heart = P("M 24,99.4 C 20,96.4 16.4,93.2 16.4,89.6 C 16.4,86.8 18.4,85.2 20.4,85.2 "
              "C 22,85.2 23.4,86.2 24,87.6 C 24.6,86.2 26,85.2 27.6,85.2 C 29.6,85.2 31.6,86.8 31.6,89.6 "
              "C 31.6,93.2 28,96.4 24,99.4 Z")
    c.paint(heart, "bone")
    c.paint(heart.buffer(-1.6), "red")
    c.paint(S("M 18.6,91 L 21.4,91 L 22.6,88.6 L 24.2,93.8 L 25.6,90 L 26.6,91 L 29.4,91", 0.6), "bone")  # heartbeat

    # the raven, hunched on his head
    raven = P("M 12.4,30.0 C 14.4,28.4 16.6,27.4 18.6,27.2 C 19.6,25.2 22.4,24.4 24.2,25.6 "
              "C 25.6,26.6 26.0,28.4 26.4,30.0 C 29.6,31.0 33.4,34.0 36.0,37.4 L 38.8,40.2 "
              "L 35.2,39.8 L 36.0,41.2 L 32.0,40.0 C 29.4,40.6 26.6,40.6 24.6,39.6 "
              "C 22.0,38.2 20.4,35.4 20.0,32.6 L 18.8,32.6 L 19.6,31.4 L 18.4,31.2 "
              "C 16.6,30.9 14.6,30.6 12.4,30.0 Z")
    for leg in ("M 25.2,39.4 L 25.0,41.8", "M 27.6,40.2 L 27.6,41.8"):
        c.paint(S(leg, 0.7), "bone")
    c.outlined(raven, "purple", w=0.75)
    c.paint(P("M 12.4,30.0 C 14.4,28.4 16.6,27.4 18.6,27.2 L 19.0,30.9 C 16.8,30.7 14.6,30.5 12.4,30.0 Z"), "bone")
    c.paint(S("M 14.6,29.6 L 18.2,29.6", 0.4), "purple")  # beak seam
    c.paint(circle(21.8, 27.9, 0.8), "red")
    for d in ("M 24.4,31.8 C 28.4,32.8 32.4,35.6 35.4,38.8", "M 25.4,34.6 C 28.2,35.6 30.6,37.4 32.4,39.4"):
        c.paint(S(d, 0.5), "bone")  # wing feathers

    # climbing rose vines up both sides
    vine = "M 5.4,120 C 7.0,111 4.4,104 5.6,96 C 6.8,88 4.4,80 5.6,72 C 6.6,64 4.8,58 6.0,50"
    for flip in (False, True):
        v = S(vine, 0.9)
        c.paint(mirror(v, CX) if flip else v, "bone")
        for (lx, ly) in [(5.6, 108), (5.2, 92), (5.4, 76), (5.8, 62)]:
            leaf(c, 48 - lx if flip else lx, ly, 4.0, 240 if flip else -60)
        for (bx, by) in [(5.8, 100), (5.0, 84), (6.0, 50)]:
            if flip:
                bud(c, 48 - bx, by, 1.6, 10)
            else:
                bud(c, bx, by, 1.6, -10)

    # banner: NEVERMORE
    band = P("M 6.5,122 C 15,120.6 33,120.6 41.5,122 L 41.5,131 C 33,129.6 15,129.6 6.5,131 Z")
    tails = P("M 6.5,123.5 L 3.4,124 L 5.0,127.4 L 3.4,131.2 L 6.5,130.5 Z")
    for t in (tails, mirror(tails, CX)):
        c.haloed(t, "bone", 0.45)
    c.haloed(band, "bone", 0.5)
    c.paint(text("NEVERMORE", "Georgia", CX, 125.6, height=4.0, width=30), "purple")

    # rose bouquet at the bottom
    for d in ("M 13,150 C 14,158 16,166 17,174", "M 34,149 C 33,158 31,166 30,174",
              "M 24,161 L 24,174", "M 8,160 C 9.5,166 10.5,170 11,174", "M 40,160 C 38.5,166 37.5,170 37,174"):
        c.paint(S(d, 1.0), "bone")
    for (lx, ly, ln, la) in [(14.6, 160, 5.0, -20), (14.0, 164, 4.6, 200), (32.6, 158, 5.0, 200),
                             (33.0, 163, 4.4, -20), (24, 168, 4.6, -35), (24, 168, 4.6, 215)]:
        leaf(c, lx, ly, ln, la)
    rose(c, 13, 146.5, 4.6, 0.3)
    rose(c, 34.5, 145.5, 4.8, 1.4)
    rose(c, 24, 156.5, 5.4, 2.2)
    bud(c, 8.2, 159.6, 2.2, -25)
    bud(c, 39.8, 159.6, 2.2, 25)
    for (lx, ly, la) in [(13, 146.5, 215), (13, 146.5, 250), (34.5, 145.5, -35), (34.5, 145.5, -70), (24, 156.5, 290)]:
        leaf(c, lx, ly, 10.0, la)
    rose(c, 13, 146.5, 4.6, 0.3)
    rose(c, 34.5, 145.5, 4.8, 1.4)
    rose(c, 24, 156.5, 5.4, 2.2)

    return outline, hole, c


if __name__ == "__main__":
    import sys
    from lib import render, write_scad
    outline, hole, c = draw()
    layers = c.final()
    render(outline.difference(hole), layers, "out/view_poe.png")
    if "--scad" in sys.argv:
        write_scad(outline, layers, "out/poe.scad", hole=hole)
