// Lens saucer - opaque panelled hull, split at the equator, glowing rim band.
//
// This is NOT an evolution of ufo_sleek.scad. That part is one piece printed
// open-side-down, and that constraint forbids all three features that make a
// saucer read as a saucer: a convex underside, a rim flange that sticks out,
// and crisp stepped tiers. Splitting at the equator removes the constraint
// instead of working around it.
//
//   openscad --render -D 'part="upper"' -o ufo_lens_upper.stl ufo_lens.scad
//   ... and again for part=lower, rim, porthole_lens, porthole_shade
//
// EVERY PART IS MODELLED IN ITS PRINT ORIENTATION, including the lower half,
// which is emitted already flipped.
//
//   upper     apex up.    First layer: the annulus r=20..69, 13700mm2.
//   lower     bell up.    First layer: the annulus r=30..69, 12100mm2.
//   rim       flat washer. porthole: flat disc.
//
// Printed this way BOTH HALVES NARROW MONOTONICALLY AS THEY RISE. Every layer
// sits wholly on the one beneath it. There is no overhang and no support on
// either part.

// FIVE SEPARATE PRINTS. There is no single-part version of this saucer.
//
//   PRINTABLE   upper  lower  rim  porthole_lens  porthole_shade
//   VIEWS ONLY  view_assembly  view_exploded  view_section
//
// The view_* parts are pictures. They show the parts in their assembled
// positions, stacked in mid-air, and slicing one puts a 126mm saucer on a 34mm
// disc with everything above it hanging over nothing. That is exactly what
// happened: the first layer came out as a small round base and the extruder
// spat filament into open air until there was a blob round the nozzle.
// They are prefixed view_ so they cannot be picked by accident.
part = "upper";

// ------------------------------------------------------------------ sizes
dia       = 150;            // widest point, across the rim flange
rim_r     = dia / 2;        // 75
hull_r    = 63;             // hull radius at the parting plane
pz        = 2;              // z of the parting plane

// The joint is a BUTT FACE plus a slip-over collar, not a tongue. Both halves
// print with their parting face on the plate, so neither can carry anything
// protruding from that face - a tongue would be printing into thin air. A
// collar solves it from outside: it constrains concentricity, which is the only
// thing the fit depends on, and it hides the seam.
band      = 1.5;              // vertical band at hull_r for the collar to grip
rim_t     = band * 2;       // collar height, centred on the parting plane
clear     = 0.22;           // the clearance that already works on the dome

// WHY BOTH HALVES ARE SOLID, HOLLOWED ONLY BY A BORE
//
// The first attempt shelled them with offset(r=-wall), the technique that works
// on the sleek saucer. It cannot work here, and the reason is worth keeping:
//
// A shell's INNER face overhangs the cavity by the same angle its outer face
// leans. For the lens curve, |dz/dr| never exceeds 0.97 until r > 300mm - so on
// a 150mm saucer the interior is nowhere steeper than the 46-degree limit. A
// shallow saucer simply cannot carry a hull-following cavity: the geometry that
// makes it read as a saucer is the geometry that makes its interior undercut.
//
// So the cavities are shapes chosen for printing, not offsets of the hull:
//   upper   a cone leaning 40 degrees, apex up, open at the parting face
//   lower   a straight cylinder, open at BOTH ends
// Neither has a ceiling, so neither needs a bridge or a support. Everything
// else is left solid and the slicer's infill hollows it - far cheaper than
// geometry, and it cannot droop.
bore_r    = 12;             // upper cone bore at the parting face
bore_lean = 35;             // degrees from vertical

// THE BORE IS THE ONLY OVERHANG IN THE UPPER HALF'S FIRST 20mm, and it is the
// one number that a layer-height change can invalidate. The cone narrows going
// up, so material grows INWARD over the hole at bore_lean:
//
//     0.12mm layers -> limit 60.3 deg      0.20mm -> 46.4 deg
//     0.16mm layers -> limit 52.7 deg      0.24mm -> 41.2 deg
//                                          0.28mm -> 36.9 deg  <- 40 FAILS
//
// This is exactly the shape of the failure that cost three UFO bodies: geometry
// certified against a constant, then sliced at a layer height nobody re-checked.
// So state the layer height here and let it fail at render rather than at z5.
layer_h   = 0.28;           // the COARSEST layer height this may be sliced at.
                            // Deliberately pessimistic: at 35 deg the bore is
                            // legal all the way down to 0.28, so the part no
                            // longer cares what profile it lands in. That is
                            // worth more than the 3mm of bore it costs.
assert(bore_lean <= atan(0.42 / (2 * layer_h)),
       str("bore_lean ", bore_lean, " deg exceeds the ",
           atan(0.42 / (2 * layer_h)), " deg limit at ", layer_h,
           "mm layers. Lower bore_lean or slice finer."));

// Top: a shallow lens, then three tiers, then a low crown. Tiers step INWARD
// going up, so every riser is a vertical band and every ledge faces UP.
lens_h    = 10;
lens_n    = 2.2;

tier1_r   = 40;  tier1_z = 14.5;
tier2_r   = 29;  tier2_z = 17.5;
tier3_r   = 19;  tier3_z = 20.0;
crown_h   = 4.5;

// Underside: a convex bell down to the porthole. bot_r is deliberately wider
// than light_r, so the bore emerges inside a 4mm flat ring rather than exactly
// at the outer edge, which would leave a knife edge.
lower_h   = 20;
lower_n   = 2.3;
bot_r     = 34;
light_r   = 30;             // the glowing disc under the ship, and the LED bore

panels    = 16;
groove_d  = 2.0;            // 2mm+ reads as shadow; under 1.5mm is invisible
groove_w  = 2.2;

steps     = 60;
$fn       = 160;

top_z0    = pz + band;
bot_z0    = pz - band;

// ------------------------------------------------------------------ curves
function lens_z(r) = top_z0 + lens_h * pow(1 - pow(r / hull_r, lens_n), 1 / lens_n);

function low_z(r)  = bot_z0 - lower_h *
    pow(1 - pow((r - bot_r) / (hull_r - bot_r), lower_n), 1 / lower_n);

function crown_z(r) = tier3_z + crown_h * sqrt(1 - pow(r / tier3_r, 2));

// ------------------------------------------------------------------ profiles
function lens_pts() = [
    for (i = [0 : steps])
        let (r = hull_r + (tier1_r - hull_r) * i / steps) [r, lens_z(r)]
];

function crown_pts() = [
    for (i = [0 : steps])
        let (r = tier3_r * (1 - i / steps)) [r, crown_z(r)]
];

function low_pts() = [
    for (i = [0 : steps])
        let (r = hull_r + (bot_r - hull_r) * i / steps) [r, low_z(r)]
];

module upper_profile_2d() {
    polygon(concat(
        [[0, pz], [hull_r, pz], [hull_r, top_z0]],
        lens_pts(),
        [[tier1_r, tier1_z], [tier2_r, tier1_z],
         [tier2_r, tier2_z], [tier3_r, tier2_z],
         [tier3_r, tier3_z]],
        crown_pts()
    ));
}

module lower_profile_2d() {
    polygon(concat(
        [[0, pz], [hull_r, pz], [hull_r, bot_z0]],
        low_pts(),
        [[bot_r, bot_z0 - lower_h], [0, bot_z0 - lower_h]]
    ));
}

// ------------------------------------------------------------------ panels
// A groove that follows a curved surface is the surface skin intersected with a
// radial slab; a straight slot cut into a dome runs out of wall at the ends and
// breaches it.
//
// The skin is taken from a profile grown 0.6mm OUTWARD, so the cutter starts
// outside the hull and cuts inward. Taking it from the hull surface itself
// leaves the cutter's outer face exactly coincident with the part's - tangency,
// which yields degenerate facets. That produced 54 unshared edges on the first
// version, and it is the same trap as drilling a feature from a guessed depth.
module radial_slabs(r0, z0, z1) {
    for (i = [0 : panels - 1])
        rotate([0, 0, i * 360 / panels])
            translate([r0, -groove_w / 2, z0])
                cube([300, groove_w, z1 - z0]);
}

// offset(r=+g) grows the profile across the Y axis, and rotate_extrude REFUSES
// any child with negative X. It fails loudly on its own but SILENTLY inside a
// difference(): an empty subtrahend simply subtracts nothing, so the part still
// renders, still lints clean, and has no panel lines on it. Clip to X >= 0.
module skin_2d(grow) {
    difference() {
        intersection() {
            offset(r = grow) children();
            translate([0, -400]) square([800, 800]);
        }
        offset(r = -groove_d) children();
    }
}

module upper_grooves() {
    intersection() {
        rotate_extrude() skin_2d(0.6) upper_profile_2d();
        // stops above the collar band: a groove crossing the parting face would
        // notch the first layer
        radial_slabs(tier1_r + 2, top_z0, 200);
    }
}

module lower_grooves() {
    intersection() {
        rotate_extrude() skin_2d(0.6) lower_profile_2d();
        radial_slabs(bot_r + 4, -200, bot_z0);
    }
}

// ------------------------------------------------------------------ parts
module upper() {
    difference() {
        rotate_extrude() upper_profile_2d();
        // conical bore, apex up, open at the parting face. Leaning 40 degrees
        // it is inside the 46-degree limit with margin, and having no ceiling
        // there is nothing to bridge.
        translate([0, 0, pz - 1])
            cylinder(h = bore_r / tan(bore_lean) + 1,
                     r1 = bore_r, r2 = 0);
        upper_grooves();
    }
}

// In assembly orientation. part="lower" emits it flipped, for printing.
module lower_asm() {
    difference() {
        rotate_extrude() lower_profile_2d();
        // straight bore, open at both ends: the porthole aperture below and the
        // parting face above. No ceiling anywhere in it.
        translate([0, 0, bot_z0 - lower_h - 1])
            cylinder(h = lower_h + band + 2, r = light_r);
        lower_grooves();
    }
}

module lower_printed() {
    translate([0, 0, pz]) rotate([180, 0, 0]) lower_asm();
}

// Slip-over collar, v2. Registers both halves concentrically, covers the seam,
// and - unlike v1 - can actually be glued. Print in translucent filament: lit
// from outside by the studio RGBs it reads as the light strip, with no wiring
// inside the hull to route.
//
// WHY V1 COULD NOT BE GLUED, measured off the printed parts:
//
//   The only contact was the bore against the 3mm vertical band - a 0.22mm
//   annular gap, 1187mm2, hidden the instant the ring was on. You cannot reach
//   it to glue it, and glue applied first scrapes off during the slide. Worse,
//   nothing stopped it AXIALLY: a ring balanced on a smooth 63mm cylinder with
//   0.22mm clearance has no seat, so it drifts off the seam it is covering.
//
// THE FIX IS RIM-ONLY. Only hull_r is a fixed mating dimension and it is
// untouched, so the halves - which took three attempts - are not reprinted.
//
// An inner CONICAL SEAT cut to the upper half's own lens curve, offset by the
// clearance that already works. Derived from the existing profile rather than
// approximated, so it cannot drift out of agreement with the hull. It drops on
// from above, self-centres, and stops on the cone:
//
//   seat_h   contact area   vs v1
//     3mm       1418mm2     1.19x
//     5mm       3120mm2     2.63x   <- chosen
//     6mm       4335mm2     3.65x
//
// And it is a face you can WET before dropping the rim on, which the 0.22mm
// gap never was.
rim_proj  = 6;              // flange past the hull. v1 was 11.78 and read as a
                            // dinner plate; this halves it. Cosmetic, free.
rim_out   = hull_r + rim_proj;
seat_h    = 5;              // 2.6x the glue area, and a positive axial stop
rim_cham  = 1.2;            // softens the outer top edge; >= min feature

// Radius of the lens curve seat_h above the band top - closed form, so the
// seat and the hull cannot disagree.
function seat_r(h) = hull_r * pow(1 - pow(h / lens_h, lens_n), 1 / lens_n);

seat_top_r = seat_r(seat_h);
rim_h      = band + band + seat_h;      // bot_z0 .. top_z0 + seat_h

// Profile in assembly orientation, r-z, anticlockwise from the bottom bore.
function rim_pts() = concat(
    [[hull_r + clear, bot_z0], [hull_r + clear, top_z0]],
    // the seat: the hull's own curve, pushed out by the working clearance
    [for (i = [0 : steps])
        let (r = hull_r + (seat_top_r - hull_r) * i / steps)
            [r + clear, lens_z(r)]],
    [[rim_out - rim_cham, top_z0 + seat_h],
     [rim_out,            top_z0 + seat_h - rim_cham],
     [rim_out,            bot_z0]]
);

module rim_asm() {
    // Pushed through a boolean: a bare rotate_extrude exports non-manifold.
    intersection() {
        rotate_extrude() polygon(rim_pts());
        translate([0, 0, bot_z0]) cylinder(h = rim_h, r = rim_out + 1);
    }
}

// PRINT ORIENTATION: FLIPPED. In assembly the seat is a 53-degree inward
// overhang - past the 46.4 limit at 0.2mm - and the outer wall is vertical.
// Upside down the seat becomes a self-supporting funnel, the outer wall is
// still vertical, and the first layer is the full 4900mm2 annulus instead of
// a narrow ring. Same trick as lower_printed().
module rim() {
    translate([0, 0, rim_h]) rotate([180, 0, 0])
        translate([0, 0, -bot_z0]) rim_asm();
}

porthole_t  = 3;

// ---- the alien's shadow in the porthole ---------------------------------
// The 60mm grey cannot fit inside a 44mm saucer, but its SHADOW can. The
// outline is a projection() of the standing alien figure (alien.scad,
// part="shadow"), exported to DXF. Change the alien's pose, re-export
// alien_shadow.dxf, and the shadow follows it.
//
// It projects as ONE contour, so the silhouette is a single connected piece
// rather than a scatter of islands. That matters: an inlay in several pieces
// is several things to place.
//
// Lit from inside the hull bore, the translucent disc glows and the opaque
// figure reads black against it.
shadow_h    = 50;       // silhouette height on a 59.6mm disc
shadow_gap  = 0.15;     // clearance for gluing. Set to 0 if you are printing
                        // lens and shade as ONE object with two filaments,
                        // as a two-colour inlay - there the
                        // two parts must be exactly complementary.
shadow_file = "alien_shadow.dxf";

// shadow_close performs a morphological CLOSE - dilate then erode - which
// fills holes narrower than 2*shadow_close while leaving the outline where it
// was. It is not cosmetic.
//
// The silhouette used to project as ONE contour. Then the alien's arms were
// tucked against its thighs to stop the hands printing in mid-air, and the gaps
// between arm and torso became enclosed HOLES: three contours, not one. Cut
// into the lens those holes leave slivers of disc standing loose inside the
// alien-shaped cavity, held by nothing - two mesh.internal_void errors, and in
// the real part, bits that fall out.
//
// At 50mm tall those gaps are about a millimetre. They would not read anyway.
// Closing them costs nothing visually and puts the silhouette back to one piece.
//
// Delta, not r: this outline came from projection() and has hundreds of short
// segments, and a rounded offset builds an arc on every one of them.
shadow_close = 1.0;

module alien_shadow_2d() {
    offset(delta = -shadow_close) offset(delta = shadow_close)
        translate([0, -shadow_h / 2])
            resize([0, shadow_h, 0], auto = true)
                import(shadow_file);
}

module porthole() {                     // plain disc, no shadow
    cylinder(h = porthole_t, r = light_r - clear);
}

module porthole_lens() {                // translucent, alien removed
    difference() {
        porthole();
        translate([0, 0, -1])
            linear_extrude(porthole_t + 2)
                offset(delta = shadow_gap) alien_shadow_2d();
    }
}

module porthole_shade() {               // opaque, drops into the lens
    linear_extrude(porthole_t) alien_shadow_2d();
}

// ------------------------------------------------------------------ output
module assembly() {
    upper();
    lower_asm();
    #rim_asm();
    #translate([0, 0, bot_z0 - lower_h]) porthole_lens();
    translate([0, 0, bot_z0 - lower_h]) porthole_shade();
}

module exploded() {
    translate([0, 0, 46]) upper();
    translate([0, 0, 22]) rim_asm();
    lower_asm();
    translate([0, 0, -26]) translate([0, 0, bot_z0 - lower_h]) porthole_lens();
    translate([0, 0, -40]) translate([0, 0, bot_z0 - lower_h]) porthole_shade();
}

if      (part == "view_exploded") exploded();
else if (part == "upper")    upper();
else if (part == "lower")    lower_printed();
else if (part == "rim")      rim();
else if (part == "porthole") porthole();
else if (part == "porthole_lens")  porthole_lens();
else if (part == "porthole_shade") porthole_shade();
else if (part == "grooves")  { upper_grooves(); lower_grooves(); }
else if (part == "view_assembly") assembly();
else if (part == "view_section")
    difference() {
        assembly();
        translate([0, -dia, -dia]) cube([dia, dia * 2, dia * 2]);
    }
