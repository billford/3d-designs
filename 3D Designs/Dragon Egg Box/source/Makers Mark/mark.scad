// The BX makers mark as a library, for putting the mark on any part.
//
//   use <../Makers Mark/mark.scad>
//
//   difference() { part(); translate(spot) bx_mark_pocket(20, face = "bottom"); }
//   translate(spot) bx_mark_inlay(20, "B", face = "bottom");   // silver
//   translate(spot) bx_mark_inlay(20, "x", face = "bottom");   // red
//
// Everything is centred on the origin, with the part's surface at z = 0.
// `face` is the way that surface faces in the part's own frame:
//   "top"    - pocket and inlay go down from z = 0
//   "bottom" - they go up from z = 0, and the art is mirrored so it reads
//              correctly when you turn the part over to look at it
// Put the mark on a face that prints FLAT, best of all the one on the bed
// (a foot, an underside, a lid printed top down). The colour changes then
// happen in three layers. On a vertical face they happen in every layer the
// mark spans, with a purge for each one.
//
// Colours are the owner's: silver B, red x. The parts must be a material that
// fuses with the part's, so PLA in PLA, and ABS or ASA in ABS. With no inlay
// parts loaded, the pocket prints as an engraved mark.

include <mark_shapes.scad>

bx_mark_depth = 0.6;   // 3 layers at 0.2, proven on the badge (2026-10-08)
bx_mark_grow  = 0.02;  // pocket grown so touching inlays leave no pinch edges

// Proportions from the SVG: the mark is 807 x 354 units, the B's middle bar
// is 26 units (the thinnest stroke), and the B-x gap is 1.2mm at 56mm wide.
function bx_mark_h(w) = w * mark_h_units / mark_w_units;
function bx_mark_bar(w) = 26 * w / mark_w_units;
function bx_mark_gap(w) = 1.2 * w / 56;
// Smallest width that still prints as a flush inlay: a 0.55mm line and a
// 0.35mm gap, both proven on the Halloween bookmarks. About 17.1mm.
bx_mark_min_w = max(0.55 * mark_w_units / 26, 0.35 * 56 / 1.2);

module bx_mark_2d(w, which = "both", face = "top") {
    assert(w >= bx_mark_min_w,
           str("BX mark ", w, "mm wide; under ", bx_mark_min_w, " its B bar or B-x gap will not print"));
    s = w / mark_w_units;
    mirror([face == "bottom" ? 1 : 0, 0, 0]) scale(s) {
        if (which != "x") mark_b2d();
        if (which != "B") mark_x2d();
    }
}

module bx_mark_pocket(w, depth = bx_mark_depth, face = "top") {
    translate([0, 0, face == "bottom" ? -1 : -depth])
        linear_extrude(depth + 1) offset(delta = bx_mark_grow) bx_mark_2d(w, "both", face);
}

// which: "B" (silver) or "x" (red)
module bx_mark_inlay(w, which, depth = bx_mark_depth, face = "top") {
    assert(which == "B" || which == "x", "inlay is the B or the x");
    translate([0, 0, face == "bottom" ? 0 : -depth])
        linear_extrude(depth) bx_mark_2d(w, which, face);
}
