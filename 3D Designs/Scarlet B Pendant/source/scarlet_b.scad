// Scarlet B: a pendant in the manner of the cover A on The Scarlet Letter.
//
// The letter is drawn, not set in a font: each stroke is a broad-nib pen
// dragged along a curve, so the thick-thin contrast comes from the pen angle
// the way it does in hand lettering. From the cover's A it takes the cupped,
// sweeping serifs and the slanted break through a thin stroke.
//
// ONE PRINT, ONE COLOUR, no supports. PRINT ORIENTATION: flat, as modelled,
// bevelled face up. The chain hole then runs vertically and prints round.
//
//     part = "pendant"   the print
//     part = "outline"   the pendant's 2D outline, straight from the pen
//
// The pendant is extruded from pendant_shape.scad, which shape.py writes from
// `outline`: run it after changing anything above the pen section. The pen's
// offset(r=) passes put an arc at every vertex of these finely sampled curves,
// leaving 1114 edges under 0.002mm; a slicer's rounding merges their ends and
// the extruded mesh linted as 2060 non-manifold edges (2026-11-05). shape.py
// simplifies the outline to 0.005mm, which nobody can see at this size.

part = "pendant";   // pendant | outline

// ---- the letter -------------------------------------------------------------
letter_h = 30;      // cap height, mm, not counting the loop
nib_a    = 6;       // pen angle from horizontal: low = thin horizontals, thick verticals
// Half the nib's thickness, mm: a hairline is 1.4. At exactly the 1.2 minimum
// the minimum-feature pass below nearly cut the foot in two (2026-11-05).
nib_t    = 0.7;
break_w  = 1.4;     // the break's slit: over the 1.2mm minimum gap
steps    = 40;      // segments per stroke

// ---- the pendant ------------------------------------------------------------
thick    = 2.4;     // 12 layers at 0.2
bevel    = 0.4;     // the top edge stepped in, kinder to skin
hole_d   = 3.5;     // a fine chain's end ring or a 2mm cord passes
loop_w   = 1.6;     // four perimeters
// The letter's balance point, mm from its stem side: the loop sits over it, so
// the B hangs level. Measured off view_flat (area centroid, 2026-11-05);
// re-measure if any stroke changes.
hang_x   = 12.7;

min_feat = 1.2;

include <pendant_shape.scad>   // pendant_outline(), from shape.py

// ---- derived ------------------------------------------------------------------
s = letter_h / 100;            // the strokes are drawn on a 100-unit cap height
loop_r = hole_d / 2 + loop_w;
loop_y = letter_h + loop_r - 0.9;   // 0.9 down into the top stroke, so they fuse

assert(2 * nib_t > min_feat, str("hairline ", 2 * nib_t, "mm is not over the ", min_feat, "mm minimum"));
assert(break_w >= min_feat, str("break ", break_w, "mm under the ", min_feat, "mm minimum gap"));
assert(loop_w >= min_feat, str("loop wall ", loop_w, "mm under the minimum"));
assert(thick - bevel >= 4 * 0.2, "bevel leaves under four layers at the edge");

// ---- the pen ------------------------------------------------------------------

function bez(p, t) = pow(1-t, 3)*p[0] + 3*pow(1-t, 2)*t*p[1] + 3*(1-t)*t*t*p[2] + pow(t, 3)*p[3];

// w = [start, middle, end] pen width in units, eased along the stroke
function width(w, t) = t < 0.5 ? w[0] + (w[1]-w[0]) * sin(180*t) : w[2] + (w[1]-w[2]) * sin(180*t);

function dbez(p, t) = 3*pow(1-t, 2)*(p[1]-p[0]) + 6*(1-t)*t*(p[2]-p[1]) + 3*t*t*(p[3]-p[2]);

// The nib: an ellipse a = w/2 long at nib_a, b = t thick (half-axes, mm).
function nib_ab(w, t) = [max(w * s / 2, t), t];
module nib(ab) rotate(nib_a) scale(ab) circle(1, $fn = 24);

// How far the nib reaches either side of its path, moving in direction d:
// the ellipse's extent along the path's normal.
function reach(ab, d) = let(phi = atan2(d[0], -d[1]) - nib_a)
    sqrt(pow(ab[0] * cos(phi), 2) + pow(ab[1] * sin(phi), 2));

// One pen stroke along a cubic Bezier, as ONE outline: the path offset each
// side by the nib's reach, capped with the nib itself. t is the nib's
// half-thickness, start to end: a thicker nib makes a heavier horizontal.
// Hulling the nib at each step looked the same, but left pairs of vertices
// 0.00006mm apart wherever consecutive hulls met - 11398 edges under 0.002mm,
// which the linter's (and a slicer's) rounding merged into 2277 "not manifold"
// edges (2026-11-05).
module stroke(p, w, t = [nib_t, nib_t]) {
    function ab(u) = nib_ab(width(w, u), t[0] + (t[1] - t[0]) * u);
    function side(u, k) = let(d = dbez(p, u) / norm(dbez(p, u)), n = [-d[1], d[0]])
        bez(p, u) * s + k * reach(ab(u), d) * n;
    polygon(concat([for (i = [0 : steps]) side(i / steps, 1)],
                   [for (i = [steps : -1 : 0]) side(i / steps, -1)]));
    translate(bez(p, 0) * s) nib(ab(0));
    translate(bez(p, 1) * s) nib(ab(1));
}

// The stem, waisted: the nib narrows toward the middle.
module stem_2d() stroke([[22, 97], [22, 65], [22, 35], [22, 3]], [19, 14, 19]);

// Like the cover A's thin stroke: a slanted break across the upper bowl's hairline.
module break_2d() translate([62, 96] * s) rotate(62) square([7, break_w], center = true);

module b_2d() {
    offset(r = min_feat / 2) offset(r = -min_feat / 2)   // nothing under 1.2mm survives
    difference() {
        offset(r = -1.2) offset(r = 1.2)                  // brackets: every inside corner filleted
        union() {
            stem_2d();
            stroke([[-9, 86], [-2, 99], [26, 100.5], [50, 99.5]], [2, 8, 12], [0.7, 0.8]);  // top serif: a cupped sweep in from the left
            stroke([[48, 99.6], [80, 98.5], [82, 57], [40, 54.5]], [12, 16, 8]);            // upper bowl
            stroke([[44, 54.5], [36, 54], [28, 53.5], [20, 53]], [8, 8, 8], [1.3, 1.1]);    // waist: the bowls join inside the stem
            stroke([[26, 53], [92, 57.5], [96, 2], [48, 1.2]], [10, 19, 12]);               // lower bowl
            stroke([[48, 1.2], [30, 0.9], [2, 0], [-10, 9]], [12, 8, 2], [0.7, 0.75]);      // foot, curling up at the tip
        }
        break_2d();
    }
}

module pendant_2d() {
    offset(r = min_feat / 2) offset(r = -min_feat / 2)   // the break's cut ends obey the minimum too
    difference() {
        offset(r = -1) offset(r = 1) union() {           // fillets where the loop meets the letter
            b_2d();
            translate([hang_x, loop_y]) circle(loop_r, $fn = 64);
        }
        translate([hang_x, loop_y]) circle(hole_d / 2, $fn = 64);
        break_2d();   // again: the fillet pass closes it otherwise
    }
}

// The bevel layer overlaps the body by 1mm. Sharing its bottom face at z = 0
// was the first suspect for the non-manifold export; it was not the cause
// (the count barely moved, 2309 -> 2277), but the overlap stays.
// offset(delta=) mitres and adds no arcs, so the bevel stays clean.
module pendant() {
    linear_extrude(thick - bevel) pendant_outline();
    translate([0, 0, thick - bevel - 1]) linear_extrude(bevel + 1) offset(delta = -bevel) pendant_outline();
}

if (part == "pendant") pendant();
else if (part == "outline") pendant_2d();
else assert(false, str("unknown part ", part));
