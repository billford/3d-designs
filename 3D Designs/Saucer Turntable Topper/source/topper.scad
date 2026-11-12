// Saucer topper - a printed platter that drops onto a bought turntable.
//
// THIS IS TWO PRINTS, PLUS A GAUGE YOU PRINT FIRST:
//
//   gauge    <- print this ONE first. A 60-degree arc of the ring, ~10 minutes.
//   ring     <- the locator, once the gauge fits
//   platter  <- the disc the saucer sits in
//
//   openscad --render -D 'part="gauge"' -o tt_gauge.stl topper.scad
//
// view_assembly is a PICTURE, not a part.
//
// WHY THIS REPLACED A WHOLE MOTORISED TURNTABLE
//
// The DIY version - ball race, GT2 belt, NEMA17, TMC2209, an ESP32 and an
// evening of wiring - was retired. A ComXim
// does the motor half better than we would and costs less than the parts, and
// the build was going to hurt to assemble. What a bought turntable CANNOT do is
// be shaped for this saucer and these hands. So print only that part.
//
// FOR UNSTEADY HANDS. The requirement, not a nicety:
//
//   Everything DROPS ON and finds its own centre. The ring funnels onto the
//   turntable, the saucer funnels into the recess. Nothing needs aiming, and
//   nothing needs holding steady while something else is tightened.
//
//   A 6mm OVERHANG the whole way round, so the platter lifts off with fingers
//   under the edge anywhere at all - better than scallops, which still have to
//   be found.
//
//   No fasteners. One glued face, done once, on a bench.
//
// WHY A SEPARATE RING INSTEAD OF A SKIRT ON THE PLATTER
//
// A one-piece topper with a skirt has a 200mm void under it, and that void has
// a ceiling. Right way up it is an impossible bridge; upside down the rim
// starts in mid-air as an island ring. There is no orientation that prints it -
// the same wall the saucer hit before it was split at the equator.
//
// Split, both parts are trivial: the platter is a flat disc with a valley
// milled in the top, the ring is a ring. Neither has an overhang anywhere. The
// glue joint is 3600mm2 of flat annulus you can see and reach - which is the
// lesson the saucer's own rim taught.

part = "gauge";  // gauge | ring | platter | view_assembly

$fn = 240;

// ------------------------------------------------- THE BOUGHT TURNTABLE
// MEASURED, NOT SPEC'D. "20cm / 7.9in" is a marketing round number, and this
// ring has to fit the actual disc. Print part=gauge and correct these two
// before committing three hours to the platter: published dimensions vary
// between sources.
comxim_d   = 200.0;         // <- MEASURE. Calipers across the real platter.
comxim_lip = 8.0;           // <- MEASURE. How far the platter's edge stands
                            //    proud of the body below it. The ring must be
                            //    SHORTER than this or it bottoms out on the
                            //    housing and the topper rocks.

ring_clear = 0.8;           // Deliberately loose. 0.22 is this shop's LOCATING
                            // clearance, and it is the wrong number here: a
                            // close fit has to be aimed. This one is meant to
                            // fall on.
lead_in    = 1.6;           // chamfer on the ring's inner bottom edge, so it
                            // funnels rather than catches

// -------------------------------------------------------------- the saucer
// The saucer does NOT rest on its 138mm rim - it rests on the bottom of the
// bell, an annulus 60..73.8mm across, measured off ufo_lens_lower.stl. Sizing
// the recess to the widest diameter would have located precisely nothing.
saucer_foot_d = 73.8;
saucer_fit    = 1.7;        // drops in without aiming, same reasoning as above
recess_d      = saucer_foot_d + saucer_fit;
recess_h      = 2.5;        // enough to locate. Deliberately NOT deeper: the
                            // rim is the glowing band and burying it would
                            // throw away the reason the saucer looks good.

// --------------------------------------------------------------- the parts
overhang   = 6.0;           // finger access, the whole way round
topper_d   = comxim_d + 2 * overhang;
plate_t    = 5.0;           // 4 flexed visibly at 212mm; infill does the rest
ring_h     = 5.0;           // must stay under comxim_lip
ring_id    = comxim_d + ring_clear;

gauge_deg  = 60;            // enough arc to feel the diameter, ~10 min to print

// ------------------------------------------------------------- assertions
assert(ring_h < comxim_lip,
       str("ring is ", ring_h, "mm but the turntable's lip is only ",
           comxim_lip, "mm - it will bottom out on the housing and rock"));
assert((topper_d - ring_id) / 2 >= 2.4,
       str("ring wall would be ", (topper_d - ring_id) / 2,
           "mm - under 6 perimeters"));
assert(recess_d < comxim_d - 20, "recess is too close to the platter edge");
assert(topper_d < 230,
       str(topper_d, "mm - P1S practical bed is ~230, not the nominal 256"));

glue_area = PI * (pow(topper_d / 2, 2) - pow(ring_id / 2, 2));
echo(str("glue face: ", round(glue_area), " mm2 of flat annulus"));

// ==========================================================================

// ------------------------------------------------------------- the platter
// Prints RIGHT WAY UP. The recess is a valley, not an overhang, and the first
// layer is the whole disc - which is the best first layer available, though a
// big flat one, so: brim 5mm, brim-object gap 0.
module platter() {
    difference() {
        cylinder(h = plate_t, d = topper_d);
        // saucer seat, with a funnel so it does not have to be aimed
        translate([0, 0, plate_t - recess_h]) {
            cylinder(h = recess_h + 1, d = recess_d);
            translate([0, 0, recess_h - 1.2])
                cylinder(h = 1.2 + 1, d1 = recess_d, d2 = recess_d + 2.4);
        }
    }
}

// ---------------------------------------------------------------- the ring
// Prints flat, first layer is the full annulus. The lead-in chamfer is on the
// BOTTOM inner edge, which prints as a 45-degree flare off the plate and is
// self-supporting.
module ring_2d_profile() {
    // r-z profile, revolved: outer wall vertical, inner wall vertical above a
    // chamfered mouth.
    polygon([
        [ring_id / 2,            0],
        [topper_d / 2,           0],
        [topper_d / 2,           ring_h],
        [ring_id / 2,            ring_h],
        [ring_id / 2,            lead_in],
        [ring_id / 2 - lead_in,  0],
    ]);
}

module ring() {
    // Pushed through a boolean: a bare rotate_extrude exports non-manifold.
    intersection() {
        rotate_extrude() ring_2d_profile();
        cylinder(h = ring_h, d = topper_d + 1);
    }
}

// --------------------------------------------------------------- the gauge
// Print this FIRST. It tells you whether comxim_d is right for about ten
// minutes of plate time instead of three hours. A tab makes it easy to hold
// and to pull off - it is a throwaway.
module gauge() {
    intersection() {
        ring();
        rotate([0, 0, -gauge_deg / 2])
            linear_extrude(ring_h)
                polygon([[0, 0],
                         [topper_d, 0],
                         [topper_d * cos(gauge_deg), topper_d * sin(gauge_deg)]]);
    }
    // grip tab, outboard so it cannot foul the fit being tested
    rotate([0, 0, gauge_deg / 2])
        translate([topper_d / 2 - 1, -6, 0]) cube([10, 12, 2.4]);
}

// ------------------------------------------------------------------ views
module view_assembly() {
    color("gainsboro") translate([0, 0, ring_h]) platter();
    color("steelblue") ring();
    // the bought turntable, for scale only
    %translate([0, 0, -comxim_lip]) cylinder(h = comxim_lip, d = comxim_d);
}

if      (part == "platter")       platter();
else if (part == "ring")          ring();
else if (part == "gauge")         gauge();
else if (part == "view_assembly") view_assembly();
else assert(false, str("unknown part: ", part));
