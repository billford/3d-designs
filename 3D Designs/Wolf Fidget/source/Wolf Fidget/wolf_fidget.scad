// Wolf Fidget: a silent clicking twist fidget for a classroom. A wolf-head cap
// over three discs that twist on a hidden post with a SOFT click: felt in the
// fingers, not heard across a room (2026-11-11).
//
// WHY A SOFT CLICK IS A SHAPE, NOT A MATERIAL. The sound of a click is an
// impact: something springs over a steep edge and slams into the next face.
// Here each disc carries a curved flexure tongue whose rounded nub rides on a
// post with eight smooth, cosine-shaped flutes. There is no steep face to
// fall off, so the nub rolls into each valley instead of dropping into it.
// The nub (r 0.9) is also blunter than the valley (r ~0.7), so it never
// bottoms out with a tap. You feel eight notches a turn; nothing slams.
//
// THE CLICK STRENGTH WAS PICKED BY HAND. How strong a click feels depends on
// the printer and the plastic, not on a number we can compute, so the first
// print was a gauge: three discs, lightest to firmest (gauge = true marks them
// with one, two and three dots underneath). The middle one won, and every
// disc is now built at that setting (engage, below).
//
// Assembly, no glue: the cap carries the post. Drop the three discs over it,
// then press the base on until it clicks. The base has two tongues, like a
// disc's, whose nubs spring into a groove round the post's solid end.
// The discs and the base turn; hold the cap.
//
// WHY THE SNAP SPRINGS IN THE BASE. The first two posts ended in a split
// barb. Printed upright, its prongs bend ACROSS the layer lines: the 9mm pair
// broke on assembly, the 12mm pair snapped off the plate at a touch. Every
// flexure here now prints FLAT and bends along the layers, as the disc
// tongues do, and the post is a solid rod.
//
// SEPARATE PRINTS: 2 plates, both PLA, 0.2mm layers.
//   the head (4 colors): cap, cream, black, amber - load together as ONE
//     object with several parts. Shown in brown, white, black and orange.
//   the rest (1 color, + 2 for the mark): discs, base, and optionally
//     wolf_mark_silver + wolf_mark_red loaded with the base as one object.
// cap_plain is the cap in one color with no inlay pockets.
// view_assembly is a picture. Never slice it.
//
// Print orientation: everything flat. The cap prints FACE DOWN, so the wolf's
// colors are the first layers, on the bed, and the post stands straight
// up from its back. Discs either way up. The base prints UPSIDE DOWN, top face on the bed:
// its tongues are then the first layers, and the hollow above them closes
// with a 45 degree cone instead of a bridge. Its mark ends up on top.

use <../Makers Mark/mark.scad>
include <wolf_art.scad>

part = "view_assembly";   // cap | cream | black | amber | cap_plain | test_plate | snap_plate | plate_body | plate_parts | plate_cream | plate_black | plate_amber | discs | base
                          // | wolf_mark_silver | wolf_mark_red | view_assembly

/* [Wolf cap] */
cap_w = 40;             // head width. 40 puts the irises at ~4mm and every
                        // color line above the 0.55mm the bookmarks proved
cap_t = 3.0;            // 15 layers: stiff enough to hold the post's root
inlay = 0.6;            // 3 layers of color on the face, as the BX mark
// The amber irises go deeper (hidden inside the cap) for one reason: Bambu
// Studio treats any part under 9 mm3 as "probably inches" and silently scales
// it 25.4x. At 0.6mm the irises were 4.2 mm3 and loaded 356mm wide
// (2026-11-11). build.sh checks every STL against that threshold.
amber_t = 1.6;
axis_px = [595, 760];   // where the post sits under the drawing, in reference
                        // pixels (y down): the middle of the face, between
                        // the eyes and the nose, so the discs center under it

/* [Discs] */
discs = 3;
disc_d = 32;            // hidden under the cap from above: at 34 a sliver showed between the ears
disc_t = 5.0;           // 25 layers; also the tongue's height
edge_c = 0.8;           // chamfer on the disc edges, top and bottom
ribs = 30;              // finger grip round the edge
rib_d = 0.5;            // felt, not seen

/* [Click] */
post_r = 4;             // mean radius of the fluted post
flutes = 8;             // 45 degrees per click
flute_a = 0.35;         // flute amplitude: 0.7mm crest to valley
spin_fit = 0.3;         // ROTATING fit, as Twisty Cookies
tongue_t = 1.2;         // tongue's radial thickness (minimum feature)
tongue_l = 14;          // tongue length along its arc
slot = 1.2;             // the gap that frees the tongue (minimum gap)
nub_r = 0.9;            // blunter than the flute's valley: rolls, never taps
// crest deflection per disc, lightest first. At 0.45 the nub floats 0.25mm in
// each valley: a whisper of a click with a little free play. At 0.85 it is
// preloaded 0.15mm even in the valley: no play, a firm notch.
// THE PICK: two dots, 0.65mm. A PRINTED-dimension number from the gauge
// (PLA, Bambu P1S, 0.2mm layers), not a spec number: print the gauge
// (gauge = true) again if your plastic or printer differs.
gauge = false;
engage = gauge ? [0.45, 0.65, 0.85] : [0.65, 0.65, 0.65];

/* [Post end and base latch] */
// The post's end is a plain rod (pe_r) with a groove; the base's tongue nub
// drops into it. pe_r stays under the flute crest, so the discs' nubs slide
// over it on the way on. Groove core r 3.1: a 6.2mm solid rod at its thinnest,
// where the split neck was two 1.9mm prongs.
// Second latch (2026-11-11): one disc-style tongue (1.2 x 14mm, 2.4 tall)
// pushed ~1N, so the base fell off at a touch; and with 0.1mm of axial slack
// the discs' real thickness kept the nub out of the groove altogether. Now two
// short thick tongues (~14 N/mm each, ~40N to pull off), and each nub sits on
// the 45 deg holding wall under preload, so it pulls the base snug against the
// stack and takes up -0.2..+0.6mm of stack error.
pe_r = 4.0;
lt_t = 1.6;             // latch tongue: radial thickness
lt_l = 10;              // latch tongue: arc length
latch_e = 0.8;          // nub's reach inside pe_r: the deflection to pass it
latch_p = 0.2;          // deflection already on the wall with a nominal stack
latch_free = 0.1;       // nub to groove floor
// 2.8 and 0.1 above, and r_end below, keep the post EXACTLY the one printed
// 2026-11-11 (groove floor r 3.1, holding wall from 2.5mm deep): the cap that
// came off that plate is sound, so only the base is reprinted.
band_h = 2.8;           // the base's tongue layer
latch_lead = 30;        // the post tip's lead-in, degrees from the axis
play = 0.1;
floor_t = 2.0;          // under the hollow; the BX mark takes 0.6 of it

/* [Makers mark] */
mark = true;            // on the base's underside
mark_w = 19;            // 18 left the red x at 9.0 mm3: Studio scales parts under 9 by 25.4 ("inches"); 20 hits the theta-delta
therian = true;         // the therian theta-delta engraved under the mark; false leaves it off

layer_h = 0.2;
gap = 8;                // between parts on the plate

$fn = 96;

// ---- derived ----
R = disc_d / 2;
s = cap_w / (wolf_box[1][0] - wolf_box[0][0]);     // mm per reference pixel
axis = [axis_px[0], wolf_px_h - axis_px[1]];       // potrace's frame is y up
crest = post_r + flute_a;
valley = post_r - flute_a;
bore = crest + spin_fit;
tongue_mid = bore + tongue_t / 2;
tongue_arc = tongue_l / tongue_mid * 180 / PI;     // degrees
tip_gap = slot / tongue_mid * 180 / PI;
stack = discs * disc_t;
function lay(h) = ceil(h / layer_h - 1e-6) * layer_h;
zb = stack + play;                                  // base's top face, from the cap's back
b_bore = pe_r + spin_fit;                           // the base's hole
r_n = pe_r - latch_e;                               // base nub's tip
r_g = r_n - latch_free;                             // groove floor
d_core = pe_r - r_g;                                // groove's lead-in ramp ends this deep into the band
d_hold = band_h - (r_n + latch_p - r_g);            // 45 deg holding wall begins: the nub's corner sits on it
d_tip0 = d_hold + (pe_r - r_g);                     // back to pe_r
r_end = r_n - 0.3;                                  // tip end: the nub meets the lead-in, not a corner
d_tip = d_tip0 + (pe_r - r_end) / tan(latch_lead);
post_len = zb + d_tip;                              // from the cap's back
cav_r = b_bore + lt_t + slot + 0.4;             // hollow under the tongue and slot
base_t = lay(band_h + 0.4 + cav_r + floor_t);
function r_tip(e) = crest - e;

overhang_limit = atan(0.42 / (2 * layer_h));
// a cantilever: strain = 1.5 t y / L^2. A fidget is flexed thousands of times,
// so the tongue is held to 1%, half the 2% the one-time snap is allowed.
tongue_strain = 1.5 * tongue_t * max(engage) / (tongue_l * tongue_l);
latch_strain = 1.5 * lt_t * latch_e / (lt_l * lt_l);
assert(tongue_strain <= 0.01, str("tongue strain ", tongue_strain * 100, "%: over 1% it will fatigue. Lengthen tongue_l"));
// flat-printed, flexed once per assembly: the 2% one-time limit applies
assert(latch_strain <= 0.02, str("base latch strain ", latch_strain * 100, "%"));
assert(tongue_arc + 2 * tip_gap <= 200, "tongue wraps over half the bore: the disc loses its grip on the post");
assert(pe_r <= crest - 0.2 && max([for (e = engage) pe_r - r_tip(e)]) <= max(engage),
       "the post's end is fatter than a crest: a disc would jam going on");
assert(r_g >= 3.0, str("groove floor r ", r_g, ": the rod there is too thin"));
assert(d_hold >= d_core + 0.6, "no groove floor left between the ramp and the holding wall");
assert(2 * (arc_of(b_bore, lt_t, lt_l) + 2 * gap_of(b_bore, lt_t)) <= 300, "the two latch tongues overlap");
assert(min([for (e = engage) r_tip(e)]) > valley - 0.3, "a nub is preloaded so hard it would fight in the valleys");
assert(max(engage) <= 2 * flute_a + 0.3, "engage over the flute's depth: it would grind, not click");
// the flute's valley is concave with radius r^2 / (a N^2 - r) (polar curvature at r = valley)
valley_rc = valley * valley / (flute_a * flutes * flutes - valley);
assert(nub_r >= valley_rc, str("nub r ", nub_r, " is sharper than the valley's ", valley_rc, ": it would tap the bottom"));
assert(latch_e >= 0.5, "the base's nub barely reaches into the groove: it would pull off");
assert(tongue_t >= 1.2 && slot >= 1.2, "a feature or gap under 1.2mm");
// the hollow's 45 deg cone must clear the tip: at depth d it has radius cav_r - (d - band_h - 0.4)
assert(cav_r - (d_tip0 - band_h - 0.4) >= pe_r + 0.3, "the post's tip hits the base's hollow");
assert(band_h + 0.4 + cav_r >= d_tip + 0.3, "the post's tip hits the hollow's top");
assert(bore + tongue_t + slot + 3 <= R - edge_c - rib_d, "tongue slot runs too close to the disc edge");
assert(45 <= overhang_limit, "the groove's holding wall and the base's hollow are 45 deg: they won't print");
assert(norm([mark_w / 2, bx_mark_h(mark_w) / 2 + (therian ? 3 : 0)]) <= R - edge_c - 1.2,
       "mark runs into the base's chamfer");
assert(amber_t <= cap_t - 1.2, "the amber pocket leaves under 1.2mm of cap behind it");
for (h = [cap_t, inlay, amber_t, disc_t, base_t]) assert(abs(h / layer_h - round(h / layer_h)) < 1e-6,
    str(h, "mm is not a whole number of layers"));

// ---- the art, centered on the post, face up, in mm ----

min_feat = 1.2;
// The head outline is the cap's 3mm wall, so it is RELIEF and held to 1.2mm:
// opened by half of that, which rounds off the traced fur tufts' hair-thin
// tips. delta, not r: offset(r=) self-intersects on a traced outline.
module head_mm() offset(delta = min_feat / 2) offset(delta = -min_feat / 2) scale(s) translate(-axis) wolf_head2d();
module art_raw(which) scale(s) translate(-axis) {
    if (which == "cream") difference() { wolf_cream2d(); offset(delta = 0.5) { wolf_black2d(); wolf_amber2d(); } }
    if (which == "black") difference() { wolf_black2d(); offset(delta = 0.5) wolf_amber2d(); }
    if (which == "amber") wolf_amber2d();
}
// colors are flat inlays, so the bookmarks' 0.55mm applies, not 1.2; they
// are clipped to the opened outline so none hangs off the rounded tufts
module art(which) if (which == "head") head_mm(); else intersection() { art_raw(which); head_mm(); }
// grown 0.02mm (in mm: art() has already scaled), as the BX mark library
// The cutter runs 1mm PAST the outline: clipped to the outline exactly, it left
// 0.02mm slivers of wall wherever a color reached the edge.
module art_pocket() offset(delta = 0.02) intersection() {
    union() { art_raw("cream"); art_raw("black"); art_raw("amber"); }
    offset(delta = 1) head_mm();
}

// ---- the cap: wolf face on the bed, post standing up from its back ----

module flute2d(r0 = post_r) polygon([for (i = [0 : flutes * 24 - 1]) let(t = 360 * i / (flutes * 24))
    (r0 + flute_a * cos(flutes * t)) * [cos(t), sin(t)]]);

// z = 0 at the cap's back. Flutes down to the base's top face (zb), then the
// solid end: a 45 deg ramp into the groove (discs' nubs climb back out over
// it), the groove floor under the base's nub, a 45 deg holding wall, and a
// lead-in. In print the post stands up, so the holding wall is a 45 deg
// overhang and everything else faces up.
module post() {
    translate([0, 0, -0.6]) linear_extrude(zb + 0.6) flute2d();
    translate([0, 0, zb - 0.01]) cylinder(r1 = pe_r, r2 = r_g, h = d_core + 0.01);
    translate([0, 0, zb + d_core - 0.01]) cylinder(r = r_g, h = d_hold - d_core + 0.02);
    translate([0, 0, zb + d_hold]) cylinder(r1 = r_g, r2 = pe_r, h = d_tip0 - d_hold);
    translate([0, 0, zb + d_tip0 - 0.01]) cylinder(r1 = pe_r, r2 = r_end, h = d_tip - d_tip0 + 0.01);
}

// pockets = false: one plain single-color cap. Never print the
// pocketed cap without its inlays: face down, every pocket's ceiling is a
// bridge over nothing (Studio calls it a floating cantilever).
module cap(pockets = true) {
    difference() {
        linear_extrude(cap_t) mirror([1, 0]) art("head");
        if (pockets) translate([0, 0, -1]) linear_extrude(inlay + 1) mirror([1, 0]) art_pocket();
        if (pockets) translate([0, 0, -1]) linear_extrude(amber_t + 1) mirror([1, 0]) offset(delta = 0.02) art("amber");
    }
    translate([0, 0, cap_t]) post();
}
module cap_inlay(which) linear_extrude(which == "amber" ? amber_t : inlay) mirror([1, 0]) art(which);

// ---- a disc ----

// Ribbed edge with chamfers, built ring by ring as one polyhedron (Twisty
// Cookies: intersecting a chamfer cone with the ribbed prism left thousands of
// non-manifold slivers where the two surfaces run nearly tangent).
function rib_r(a) = R - rib_d * (0.5 - 0.5 * cos(ribs * a));
module ribbed(t, c_lo, c_hi) {
    na = ribs * 8;
    // ring heights by integer count: a float range [4.2 : 0.05 : 5] stops a
    // hair short of 5, and the sliver ring left 254 unshared edges
    nl = max(1, round(c_lo / 0.05));
    nh = max(1, round(c_hi / 0.05));
    zs = concat([for (i = [0 : nl]) c_lo * i / nl], [for (i = [0 : nh]) t - c_hi + c_hi * i / nh]);
    pts = concat([for (z = zs) for (i = [0 : na - 1]) let(a = 360 * i / na,
                      r = min(rib_r(a), R - c_lo + z, R - c_hi + (t - z))) [r * cos(a), r * sin(a), z]],
                 [[0, 0, 0], [0, 0, t]]);
    nz = len(zs);
    P = function(i, j) i * na + (j % na);
    c = nz * na;
    polyhedron(pts, concat(
        [for (i = [0 : nz - 2]) for (j = [0 : na - 1]) each [
            [P(i, j), P(i + 1, j), P(i + 1, j + 1)], [P(i, j), P(i + 1, j + 1), P(i, j + 1)]]],
        [for (j = [0 : na - 1]) [c, P(0, j), P(0, j + 1)]],
        [for (j = [0 : na - 1]) [c + 1, P(nz - 1, j + 1), P(nz - 1, j)]]), convexity = 4);
}

module sector(r1, r2, a1, a2) polygon(concat(
    [for (i = [0 : 32]) r2 * [cos(a1 + (a2 - a1) * i / 32), sin(a1 + (a2 - a1) * i / 32)]],
    [for (i = [32 : -1 : 0]) r1 * [cos(a1 + (a2 - a1) * i / 32), sin(a1 + (a2 - a1) * i / 32)]]));

// The tongue runs from its free tip at 0 degrees to its root at tongue_arc.
// b: the hole the tongue wraps (a disc's bore, or the base's)
function arc_of(b, t = tongue_t, l = tongue_l) = l / (b + t / 2) * 180 / PI;
function gap_of(b, t = tongue_t) = slot / (b + t / 2) * 180 / PI;
module tongue_cut(b = bore, t = tongue_t, l = tongue_l) {
    circle(r = b);
    sector(b + t, b + t + slot, -gap_of(b, t), arc_of(b, t, l));
    // ends half way into the slot: sharing the slot's outer arc left vertex
    // pairs under 0.001mm apart that the lint counted as unshared edges
    sector(b - 1, b + t + slot / 2, -gap_of(b, t), 0);
    // round the slot's end: a square end is where a flexure cracks
    rotate(arc_of(b, t, l)) translate([b + t + slot / 2, 0]) circle(d = slot);
}
// tip: the nub's innermost radius
module nub_at_r(tip, b = bore) rotate((nub_r + 0.3) / (b - nub_r) * 180 / PI)
    translate([tip + nub_r, 0]) circle(r = nub_r, $fn = 48);
module nub(e) nub_at_r(r_tip(e));

module disc(k) {
    e = engage[k];
    difference() {
        ribbed(disc_t, edge_c, edge_c);
        // the nub is subtracted from the cutter, not added after: a nub
        // extruded flush with the disc's faces left 256 unshared edges
        translate([0, 0, -1]) linear_extrude(disc_t + 2) difference() { tongue_cut(); nub(e); }
        // k+1 dots on the underside say which click this is
        if (gauge) for (j = [0 : k]) rotate(200 + 14 * j) translate([R - 5, 0, -1]) cylinder(d = 1.6, h = 1.4, $fn = 24);
    }
}

// ---- the base: latch tongue at the top, hollow under it, mark underneath ----

// Modeled the way up it sits under the stack; base_printed() turns it over.
module base() difference() {
    ribbed(base_t, edge_c, edge_c);
    // the latch: two short thick tongues, opposite, cut through the top band only
    translate([0, 0, base_t - band_h]) linear_extrude(band_h + 1) difference() {
        for (a = [0, 180]) rotate(a) tongue_cut(b_bore, lt_t, lt_l);
        for (a = [0, 180]) rotate(a) nub_at_r(r_n, b_bore);
    }
    // the nub's top is cut back at 45 deg to lie along the groove's ramp
    // (0.3 clear of it), and the hole gets a lead-in at the same time
    translate([0, 0, base_t - band_h]) cylinder(r1 = b_bore - band_h, r2 = b_bore + 0.01, h = band_h + 0.01);
    translate([0, 0, base_t - 0.4]) cylinder(r1 = b_bore, r2 = b_bore + 0.4 + 0.01, h = 0.41);
    // hollow under the band so the tongue can move; printed upside down its
    // roof is this 45 deg cone, so nothing bridges
    translate([0, 0, base_t - band_h - 0.4]) cylinder(r = cav_r, h = 0.41);
    translate([0, 0, base_t - band_h - 0.4 - cav_r]) cylinder(r1 = 0, r2 = cav_r, h = cav_r + 0.01);
    if (mark) translate([0, mark_y, 0]) bx_mark_pocket(mark_w, face = "bottom");
    if (therian) translate([0, td_y, -1]) linear_extrude(1.6) mirror([1, 0]) theta_delta2d();
}
module base_printed() translate([0, 0, base_t]) rotate([180, 0, 0]) children();

// theta-delta, engraved 0.6mm, 15 x 7mm. It is RELIEF (an empty pocket, no
// inlay), so every stroke and every island of base left inside a letter is
// held to 1.2mm. The first draft's 0.9mm bar and the delta's 0.4mm-inradius
// middle would have printed as smudges.
td_h = 7;                       // both letters this tall
td_rx = 2.8;                    // theta's outer half-width
td_gap = 1.3;                   // between the letters
td_tri = 7;                     // delta's base
module theta_delta2d() {
    translate([-(td_rx + td_gap / 2), 0]) {
        difference() {
            scale([td_rx, td_h / 2]) circle(r = 1, $fn = 64);
            scale([td_rx - min_feat, td_h / 2 - min_feat]) circle(r = 1, $fn = 64);
        }
        square([2 * td_rx, min_feat], center = true);
    }
    translate([td_gap / 2 + td_tri / 2, -td_h / 2]) difference() {
        polygon([[-td_tri / 2, 0], [td_tri / 2, 0], [0, td_h]]);
        offset(delta = -min_feat) polygon([[-td_tri / 2, 0], [td_tri / 2, 0], [0, td_h]]);
    }
}
td_y = -6;                      // below the mark, which moves up to make room
mark_y = therian ? 3 : 0;
td_w = 2 * td_rx + td_gap + td_tri;
// islands left inside the letters: theta's two half-ovals, delta's middle
td_theta_island = td_h / 2 - min_feat - min_feat / 2;
td_delta_inr = td_tri * td_h / (td_tri + 2 * sqrt(td_tri * td_tri / 4 + td_h * td_h)) - min_feat;
assert(!therian || td_theta_island >= min_feat, str("theta's counters are ", td_theta_island, "mm: they'd fill in"));
assert(!therian || 2 * td_delta_inr >= min_feat, str("delta's middle is ", 2 * td_delta_inr, "mm across: it'd fill in"));
assert(!therian || (mark_y - bx_mark_h(mark_w) / 2) - (td_y + td_h / 2) >= min_feat, "theta-delta runs into the mark");
assert(!therian || norm([td_w / 2, td_y - td_h / 2]) <= R - edge_c - 1.2, "theta-delta runs into the base's chamfer");

// ---- plates ----

module plate1(which) {
    if (which == "discs") for (k = [0 : discs - 1]) translate([(k - 1) * (disc_d + gap), disc_d + gap, 0]) disc(k);
    if (which == "base") base_printed() base();
    if (which == "silver" && mark) base_printed() translate([0, mark_y, 0]) bx_mark_inlay(mark_w, "B", face = "bottom");
    if (which == "red" && mark) base_printed() translate([0, mark_y, 0]) bx_mark_inlay(mark_w, "x", face = "bottom");
}

module view_assembly() {
    // cap face up on top, discs below it, base at the bottom
    z_cap = base_t + play + stack;
    translate([0, 0, z_cap + cap_t]) rotate([0, 180, 0]) {
        color("#6B5638") cap();
        color("#F0E4CD") cap_inlay("cream");
        color("#111111") cap_inlay("black");
        color("#F98C36") cap_inlay("amber");
    }
    for (k = [0 : discs - 1]) translate([0, 0, base_t + play + k * disc_t]) color("#161616") disc(k);
    color("#161616") base();
}

module plate_at_cap() translate([22, -10, 0]) children();

if (part == "cap") cap();
else if (part == "cap_plain") cap(false);
// the click test as ONE file, already laid out: plain cap, three discs, base.
// The cap and base both sit on the origin, so loading their STLs as one
// object would print them inside each other.
// reprint after the split-barb posts broke: the gauge's discs are fine
else if (part == "snap_plate") {
    translate([22, 0, 0]) cap(false);
    translate([-30, 0, 0]) plate1("base");
}
else if (part == "test_plate") {
    translate([22, -10, 0]) cap(false);
    translate([-30, -10, 0]) plate1("base");
    // discs high enough to clear the ear tips by ~3mm (at y 30 it was 0.5mm)
    translate([0, 36 - (disc_d + gap), 0]) plate1("discs");
}
// The color plate, as TWO imports (the cap, discs and base are not one
// object). 1) plate_body + plate_cream + plate_black + plate_amber together,
// "Yes" to one object: the cap and its inlays, which must stay registered.
// 2) plate_parts on its own: discs + base. Then Arrange: it moves whole
// objects, so the inlays stay in the cap.
else if (part == "plate_body") plate_at_cap() cap();
else if (part == "plate_parts") {
    // discs in a row at y = +(disc_d + gap) / 2, the base centered under them
    translate([0, -(disc_d + gap) / 2, 0]) plate1("discs");
    translate([0, -(disc_d + gap) / 2, 0]) plate1("base");
}
else if (part == "plate_cream") plate_at_cap() cap_inlay("cream");
else if (part == "plate_black") plate_at_cap() cap_inlay("black");
else if (part == "plate_amber") plate_at_cap() cap_inlay("amber");
else if (part == "view_plate_filled") {   // slice_check only
    plate_at_cap() { cap(); cap_inlay("cream"); cap_inlay("black"); cap_inlay("amber"); }
    translate([-30, -10, 0]) plate1("base");
    translate([0, 36 - (disc_d + gap), 0]) plate1("discs");
}
// the cap with its inlays as one solid: for slice_check only, never printed
else if (part == "view_cap_filled") { cap(); cap_inlay("cream"); cap_inlay("black"); cap_inlay("amber"); }
else if (part == "cream") cap_inlay("cream");
else if (part == "black") cap_inlay("black");
else if (part == "amber") cap_inlay("amber");
else if (part == "discs") plate1("discs");
else if (part == "base") plate1("base");
else if (part == "wolf_mark_silver") plate1("silver");
else if (part == "wolf_mark_red") plate1("red");
else if (part == "view_assembly") view_assembly();
