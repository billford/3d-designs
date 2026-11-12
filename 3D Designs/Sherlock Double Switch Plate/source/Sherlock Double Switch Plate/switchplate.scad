// Sherlock Holmes double switch plate: the plate is a magnifying glass with
// both rockers in its lens, and the deerstalker rests on its rim. A cover for
// two US rocker (Decora) switches side by side. The artwork is drawn in
// art.py, which writes art.scad. Each gang's opening, screws, countersinks and
// hollow are the Poe Switch Plate's, fitted by gauge on a single dimmer
// (2026-10-16); the 2-gang spacing is the standard 1.812", which the gauge
// confirmed on the owner's 2-gang box (2026-11-04).
// Started 2026-10-30.
//
// SEPARATE PRINTS: 1 plate, three or four colors, flush inlays.
//   body         - the rim, hat and back (any dark color)
//   bone         - the glass, the rim's line, the handle's ferrule and collar
//   red          - the hat's check, the handle, the mark's x
//   mark_silver  - the mark's B (silver, or give it the bone filament)
// Load all of them together as ONE object with several parts.
//   gauge        - a separate, one-color TEST print: just a plate round the
//                  two switches. It fitted perfectly (2026-11-04).
//   view_plate   - a picture. Never slice it.
//
// Print orientation: FACE DOWN. The artwork is on the bed, so it comes out
// smooth and every colour change happens in the first `inlay` of the print.
// The back faces up: the hollow for the switch opens upward, so nothing
// overhangs, and the countersinks are cones whose ceilings stay inside the
// overhang limit.

use <../Makers Mark/mark.scad>
include <art.scad>

part = "view_plate";    // body | bone | red | mark_silver | gauge | view_plate

/* [The switches: each gang fitted by gauge 2026-10-16, the pair 2026-11-04] */
gang = 46.04;           // 1.812" between the gangs' centers: standard, gauged 2026-11-04
open_w = 33.3;          // Decora opening, 1.31" x 2.63"
open_h = 66.7;
open_fit = 0.15;        // per side: printed holes come out small
screw_c = 96.8;         // plate screws, center to center: 3-13/16", the Decora plate
                        // spacing. 83.3 (3.28") is the BOX screws: the first two
                        // plates went on by the top screw alone (2026-10-15)
screw_drop = 1.0;       // the bottom hole, lower still: on the 96.8 gauge the top
                        // screw went straight in and the bottom one rode the
                        // countersink's lower edge (owner's switch, 2026-10-16)
screw_d = 3.7;          // #6-32 clearance
head_d = 7.0;           // #6-32 oval head, 0.262", plus clearance
cs_angle = 82;          // countersink, included angle, the screw's own
// The head sits this far below the face, in a straight bore above the
// countersink. Stock plate screws were a thread short through a plate this
// thick (owner, 2026-10-16); shaving the boss's back would not help, because
// the head, not the boss, sets how far the screw reaches.
head_recess = 1.2;      // 6 layers: about 1.5 threads of #6-32
// Wall to the face of the rocker's frame. The plate's face sits flush with it.
// Standard plates stand about 1/4" off the wall; 6.0 sat flush on the gauge.
depth = 6.0;
// What the plate's hollow back must clear: each switch's mounting strap and
// its plaster ears, about 1.75" x 4.1", lying on the wall, one per gang.
hollow_w = 58 + gang;
hollow_h = 108;
strap_gap = 1.2;        // the screw bosses stop this short of the wall

/* [Plate] */
face_t = 2.4;           // the face over the hollow: carries the countersinks
inlay = 1.2;            // 6 layers at 0.2. Face down, a thin light color over a
                        // dark one looks tinted (bookmark README), and the glass
                        // is a big bone area: 0.8 is enough for lines, not this
boss_r = 4.5;
layer_h = 0.2;

/* [Makers mark] */
mark_w = 18;            // the library's minimum is ~17.1
mark_at = [6, 98];      // viewer's frame, on the hat's crown; art.py keeps it clear (MARK)

/* [Gauge] */
gauge_w = 121.8;        // the standard 2-gang plate plus 3mm
gauge_h = 120.3;

$fn = 64;

// ---- derived ----
ow = open_w + 2 * open_fit;
oh = open_h + 2 * open_fit;
cs_h = (head_d - screw_d) / 2 / tan(cs_angle / 2);
overhang_limit = atan(0.42 / (2 * layer_h));

assert(cs_angle / 2 <= overhang_limit,
    str("countersink wall is ", cs_angle / 2, " deg from vertical: over the ", overhang_limit, " limit"));
// the countersink is cut in the screw boss, not the thinner face round it
assert(head_recess + cs_h + 1.2 <= depth - strap_gap,
    str("recess plus countersink, ", head_recess + cs_h, "mm deep, leaves under 1.2mm of boss"));
assert(boss_r - head_d / 2 >= 0.8, "the boss's wall round the screw head is too thin");
assert(abs(inlay / layer_h - round(inlay / layer_h)) < 1e-6, "inlay is not whole layers");
assert(screw_c / 2 - boss_r >= oh / 2 + 1.2, "screw bosses run into the opening");
assert(gang - ow >= 1.2 * 4, str("only ", gang - ow, "mm between the two openings"));
assert(hollow_w / 2 >= gang / 2 + ow / 2 + 1.2 && hollow_h / 2 >= screw_c / 2 + screw_drop + boss_r, "hollow too small");
assert(depth - strap_gap > face_t, "plate too shallow for its bosses");

// ---- the plate, in the VIEWER's frame: face at z = 0, back at z = depth ----
// Built facing down already: looking at the face means looking up from under
// the bed, so the art is mirrored in x once, here.

module flipped() mirror([1, 0, 0]) children();

screw_ys = [-(screw_c / 2 + screw_drop), screw_c / 2];   // bottom, top (viewer's frame: y up)
gang_xs = [-gang / 2, gang / 2];

module screw_holes() for (x = gang_xs, y = screw_ys) translate([x, y, 0]) {
    translate([0, 0, -1]) cylinder(d = screw_d, h = depth + 2);
    // the head's recess, straight up from the face (the bed); then the
    // countersink, closing upward from it: no flat ledge to bridge
    translate([0, 0, -0.01]) cylinder(d = head_d + 0.02, h = head_recess + 0.02);
    translate([0, 0, head_recess]) cylinder(d1 = head_d + 0.02, d2 = screw_d, h = cs_h + 0.01);
}

module hollow() difference() {
    translate([-hollow_w / 2, -hollow_h / 2, face_t]) cube([hollow_w, hollow_h, depth]);
    for (x = gang_xs, y = screw_ys) translate([x, y, 0]) cylinder(r = boss_r, h = depth - strap_gap);
}

module opening() for (x = gang_xs) translate([x - ow / 2, -oh / 2, -1]) cube([ow, oh, depth + 2]);

module body() difference() {
    linear_extrude(depth) children();
    hollow();
    opening();
    screw_holes();
}

// mark position in the print frame (mirrored like the art)
module at_mark() translate([-mark_at[0], mark_at[1], 0]) children();

module body_part() difference() {
    body() flipped() outline2d();
    translate([0, 0, -1]) linear_extrude(inlay + 1) flipped() inlay2d();
    at_mark() bx_mark_pocket(mark_w, depth = inlay, face = "bottom");
}

module art(which) intersection() {
    linear_extrude(inlay) flipped() if (which == "bone") bone2d(); else red2d();
    // the holes go through the inlays too
    difference() { translate([-500, -500, -1]) cube([1000, 1000, 10]); opening(); screw_holes(); }
}

module gauge() body() square([gauge_w, gauge_h], center = true);

if (part == "body") body_part();
else if (part == "bone") art("bone");
else if (part == "red") { art("red"); at_mark() bx_mark_inlay(mark_w, "x", depth = inlay, face = "bottom"); }
else if (part == "mark_silver") at_mark() bx_mark_inlay(mark_w, "B", depth = inlay, face = "bottom");
else if (part == "gauge") gauge();
else if (part == "view_plate") rotate([180, 0, 0]) {    // turned over to face you
    color("#2a2a2a") body_part();
    color("#F7F3F0") art("bone");
    color("#C12E1F") { art("red"); at_mark() bx_mark_inlay(mark_w, "x", depth = inlay, face = "bottom"); }
    color("#c0c0c0") at_mark() bx_mark_inlay(mark_w, "B", depth = inlay, face = "bottom");
}
else assert(false, str("unknown part ", part));
