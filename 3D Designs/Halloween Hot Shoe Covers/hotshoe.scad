// Halloween hot shoe covers for Nikon Z5II / Z6III (standard ISO 518 shoe).
// An alien and a robot, each in one or two colours, plus scaled-up display
// busts for product photos.
//
// Copyright (c) 2026 BillfordX. Licensed CC BY-NC-SA 4.0 - see LICENSE.
// SPDX-License-Identifier: CC-BY-NC-SA-4.0
//
// ---- 1. PRINT THE GAUGE FIRST --------------------------------------------
// The foot is a friction fit into a metal channel, published ISO shoe sizes
// disagree, and every printer and filament comes out a little different. The
// gauge is four feet on one plate, marked with 1-4 bars:
//     1 bar 18.50   2 bars 18.75   3 bars 19.00   4 bars 19.25
// Keep the one that slides in with light thumb pressure and does not rattle,
// and set foot_w to its width. 18.75 is what fitted a Nikon Z shoe in PETG on
// a Bambu P1S; treat it as a starting point, not a spec.
//
// ---- 2. PRINT A COVER -----------------------------------------------------
//   openscad -D 'part="gauge"' -o gauge.stl hotshoe.scad
//   openscad -D 'who="alien"' -D 'part="single"' -o alien.stl        hotshoe.scad
//   openscad -D 'who="alien"' -D 'part="body"'   -o alien_body.stl   hotshoe.scad
//   openscad -D 'who="alien"' -D 'part="accent"' -o alien_accent.stl hotshoe.scad
//
//   single        one filament: the face features are cut in, so they read
//                 as shadow
//   body+accent   two filaments. Load both into the slicer as ONE object with
//                 two parts, one filament each; they sit in the right place
//                 already, so do not move either.
//
// Each cover is ONE print, standing on its foot as exported. No supports.
// 0.2mm layers, 5mm brim with a 0 object gap (the default gap lets the brim
// peel off with the corner it was meant to hold).
//
// PETG rather than PLA: this lives on a camera that ends up in hot bags and
// hot cars, and PLA goes soft at around 60 C.
//
// ---- 3. DISPLAY BUSTS (optional) ------------------------------------------
// part = display / display_body / display_accent: the same heads at 4.6x on a
// round plinth, for photographing next to the real thing. 60-90mm tall, one
// print each, same colour scheme as the covers, no supports.
//
// The alien bust is published in TWO colours only: dark blue or black eyes on
// a grey head is the look. In one colour the eyes are recesses, and at 4.6x
// their ceilings are wide enough to sag.

/* [Model] */
who  = "alien";   // [alien, robot]
part = "single";  // [single, body, accent, display, display_body, display_accent, gauge, preview]

/* [Display busts] */
// Display versions: the same head, scaled up for photography, on a plinth
// instead of a shoe foot. Intended as supporting product shots - the real
// cover on a camera is the honest hero image, since a 90mm print shows detail
// a 20mm one cannot.
// One scale factor for the whole set, so they stay proportionate to each
// other; heights then vary a little between characters, which is fine.
display_scale = 4.6;  // 65-90mm tall, depending on the character
display_base  = 5;    // plinth thickness
display_pad   = 5;    // plinth overhang in FINAL mm (not scaled)

/* [Fit - set from the gauge] */
foot_w    = 18.75;  // VERIFIED on a Nikon Z-series shoe, PETG, Bambu P1S:
                    // a perfect friction fit. 18.6 was slightly loose, 19.0
                    // too tight. Re-run the gauge if the material changes -
                    // this is a printed-dimension number, not a spec number.

/* [Hidden] */
// ---- the foot (shared) --------------------------------------------------
foot_d    = 16;     // how far it slides in (shoe channel is ~19.7 deep)
plate_t   = 1.5;    // thickness of the part that sits under the rails
neck_w    = 11.4;   // passes through the gap between the rail tops
neck_h    = 2.4;    // rail height
lip_t     = 2.6;    // back stop, so it cannot slide in too far
chamfer   = 0.6;    // lead-in so it starts easily

// ---- the head -----------------------------------------------------------
// Outer envelope matches a standard shoe cap (e.g. Nikon BS-1): 21 x 19.7mm,
// so it covers the shoe fully rather than perching on it.
head_w    = 21;
head_d    = 19.7;
head_h    = 15;

$fn = 64;

// ------------------------------------------------------------------- foot

module foot(w = foot_w) {
    // plate that slides under the rails, with a chamfered leading edge
    hull() {
        translate([0, chamfer, plate_t / 2])
            cube([w - chamfer * 2, foot_d - chamfer, plate_t], center = true);
        translate([0, 0, plate_t / 2])
            cube([w, foot_d - chamfer * 2, plate_t - chamfer], center = true);
    }
    // Neck through the rail gap. Deliberately sunk 0.5mm INTO the plate:
    // stacked solids that meet exactly at a plane are separate bodies as far
    // as CGAL and the slicer are concerned, and get reported as floating
    // regions even though the mesh is a valid manifold.
    translate([0, 0, plate_t + neck_h / 2 - 0.25])
        cube([neck_w, foot_d, neck_h + 0.5], center = true);
    // back stop
    translate([0, -foot_d / 2 - lip_t / 2, (plate_t + neck_h) / 2])
        cube([w + 2, lip_t, plate_t + neck_h], center = true);
}

module base_plate() {
    // The flat the face sits on. Overlaps the neck below and the head above so
    // the whole cover is one connected body rather than a stack of solids that
    // merely touch. The upper overlap is 1.2mm, not a hair: the head blanks are
    // ellipsoids tangent to z=Z0, and slicing one exactly at its tangent point
    // yields degenerate facets and a non-manifold result.
    z0 = plate_t + neck_h - 0.4;
    z1 = plate_top;
    translate([0, 0, (z0 + z1) / 2])
        cube([head_w, head_d, z1 - z0], center = true);
}

// ------------------------------------------------------------------ heads
// Each character is defined twice over:
//
//   X_solid()  the full head, including every raised feature
//   X_mask()   the region that should print in the accent colour
//
// body   = solid - mask        accent = solid & mask
//
// Splitting this way means the two parts share a clean, well-defined boundary
// and union back to exactly the single-colour model. Cutting one mesh out of
// another instead leaves coincident faces and slivers.

Z0 = plate_t + neck_h + 2;   // top of the plinth: where faces start
plate_top = Z0 + 1.2;        // where base_plate() actually ends

// Scale UNIT spheres, so the scale factors are the actual half-dimensions.
module skull_blank(w = head_w - 3, d = head_d - 3, h = head_h) {
    hull() {
        translate([0, 0, Z0 + 1.5])
            scale([w / 2, d / 2, 1.5]) sphere(r = 1);
        translate([0, 0, Z0 + h - 4.5])
            scale([w / 2.15, d / 2.3, 4.5]) sphere(r = 1);
    }
}

module eye(x, z, r = 1.9) {
    translate([x, -head_d / 2, Z0 + z]) rotate([-90, 0, 0]) cylinder(h = 6, r = r);
}

// --- alien: grey head, black almond eyes
module alien_solid() {
    difference() {
        union() {
        // Narrower chin gives the classic inverted-teardrop skull. The chin
        // width sets the flare angle: 2.2 here is 37.6 deg from vertical,
        // comfortably inside the 45 deg the printer can hold unsupported.
        hull() {
            translate([0, 0, Z0 + 1.2]) scale([2.2, 2.2, 1.2]) sphere(r = 1);
            translate([0, 0, Z0 + 11.2]) scale([9.8, 8.2, 6.0]) sphere(r = 1);
        }
        // Fillet into the plinth. Narrowing the chin for the teardrop shape
        // halved the cross-section at the joint, and the first one snapped off
        // there while being taken off the plate. This puts material back at
        // the break without touching the silhouette above it.
        translate([0, 0, Z0 - 0.6])
            cylinder(h = 3.4, r1 = 6.4, r2 = 2.3);
        }
        // Drilled from OUTSIDE the head inward, rather than placed at a
        // guessed depth. A sphere positioned by eye ended up fully enclosed
        // inside the hull - an invisible internal void, and a separate shell.
        // No nostrils: they do not breathe oxygen, and at 1mm across they
        // printed as inconsistent smudges anyway. The eyes carry this face.
        translate([0, -head_d / 2, Z0 + 6.2])                         // mouth
            rotate([-90, 0, 0])
                scale([1.75, 0.62, 1])
                    cylinder(h = 7, r = 1);
    }
}
// The .02 on this eye's height is deliberate. At
// the round number the cutter passed within 0.0007mm of a vertex of the head,
// leaving two vertices closer than the linter's 3-decimal grid - 4 edges
// counted four times each, per part. A slicer quantizes the same way. 0.02mm
// moves nothing that prints.
module alien_mask() {
    for (s = [-1, 1])
        translate([s * 4.3, -6.15, Z0 + 10.42])
            rotate([0, 0, s * -20]) scale([3.4, 2.65, 1.95]) sphere(r = 1);
}

// --- robot: grey body, bright visor and eyes
module robot_solid() {
    difference() {
        union() {
            hull()
                for (x = [-1, 1], y = [-1, 1], z = [0, 1])
                    translate([x * 7.4, y * 6.0, Z0 + 1.6 + z * 10]) sphere(r = 1.6);
            for (s = [-1, 1])
                translate([s * 8.6, 0, Z0 + 7])
                    rotate([0, s * 90, 0]) cylinder(h = 1.6, r = 2.6, center = true);
            translate([0, 0, Z0 + 13]) cylinder(h = 5.5, r = 0.75);
            translate([0, 0, Z0 + 18.4]) sphere(r = 1.6);
        }
        for (i = [-2 : 2])                                   // grille
            translate([i * 2.2, -6.6, Z0 + 4.4]) cube([1.1, 3, 3.2], center = true);
    }
}

// Two-tone eyes are body-coloured DISCS left flush in the visor, not bumps.
//
// They used to be spheres unioned onto the face at y = -6.2, r = 1.25, which
// stops 0.15mm short of the flat front at -7.6: sealed inside the head, and
// the visor mask then painted over the spot anyway. The two-tone robot printed
// with a plain gold bar and no eyes. Raising them proud instead would put a
// sphere's horizontal underside on a vertical wall - the overhang the mummy
// died of - so the colour does the work, as it does for the alien.
robot_eye_x = 3.0;
robot_eye_z = 9.4;    // on the visor's centre line
robot_eye_r = 1.25;
robot_visor = [12.4, 4.4, 4.0];

assert(2 * (robot_eye_x - robot_eye_r) >= 1.2, "robot eyes would merge");
assert(robot_visor[0] / 2 - robot_eye_x - robot_eye_r >= 1.2,
       "robot eye too close to the visor's end");
// Above and below the eye the visor is only 0.75mm, but that is a band of
// LAYERS (about 4 at 0.2mm), not an extrusion width, so 1.2mm does not apply.

// Drilled from outside the head inward.
module robot_eyes(r) {
    for (s = [-1, 1])
        translate([s * robot_eye_x, -head_d / 2 - 1, Z0 + robot_eye_z])
            rotate([-90, 0, 0]) cylinder(h = 8, r = r);
}

module robot_mask() {
    difference() {
        translate([0, -5.6, Z0 + robot_eye_z]) cube(robot_visor, center = true);
        robot_eyes(robot_eye_r);
    }
}

// ------------------------------------------------------------------ parts

// The foot slides in from the BACK of the camera, so a head built facing -Y
// ends up looking at the photographer. Everything head-related is yawed by
// this, while the foot and its back stop stay put.
face_yaw = 180;

module head_S(w) { rotate([0, 0, face_yaw]) head_solid(w); }
module head_R(w) { rotate([0, 0, face_yaw]) head_recess(w); }
module head_M(w) { rotate([0, 0, face_yaw]) head_mask(w); }
module head_I(w) { rotate([0, 0, face_yaw]) head_inset(w); }

module head_solid(which) {
    if      (which == "alien")   alien_solid();
    else if (which == "robot")   robot_solid();
    else assert(false, str("unknown character: ", which));
}

// Features that must be CUT when printing in one colour. In two-tone these
// are colour regions instead, but a colour region is invisible if both parts
// are the same filament - which is how the first split silently deleted every
// eye on the set.
module head_recess(which) {
    // .02: see alien_mask()
    if      (which == "alien")   alien_mask();
    else if (which == "robot")
        translate([0, -6.6, Z0 + robot_eye_z]) cube([11.6, 3.2, 3.4], center = true);
}

// Eyes that need re-adding after a recess is cut, so they sit inside it.
module head_inset(which) {
    // These sit inside the visor recess, whose back wall is at y = -5.0. They
    // must OVERLAP that wall - at y=-6.4 with r=1.25 the sphere stopped 0.15mm
    // short and the slicer correctly reported a floating region.
    if (which == "robot")
        for (s = [-1, 1])
            translate([s * robot_eye_x, -5.2, Z0 + robot_eye_z]) sphere(r = 1.7);
}

// Regions the GROWN accent must still leave to the body. Growing a mask with a
// hole in it grows the hole too, and shifts it: the robot's eye holes moved
// 0.12mm sideways, leaving a crescent on the face that was neither colour. So
// the hole is cut AFTER growing, 0.1mm smaller than the body's eye, so the two
// overlap rather than touch.
module head_keep(which) {
    if (which == "robot") robot_eyes(robot_eye_r - 0.1);
}
module head_K(w) { rotate([0, 0, face_yaw]) head_keep(w); }

module head_mask(which) {
    if      (which == "alien")   alien_mask();
    else if (which == "robot")   robot_mask();
    else assert(false, str("unknown character: ", which));
}

module cover(which) { union() { foot(); base_plate(); head_S(which); } }

// Single-colour version: the accent features become recesses so they still
// read through shadow.
module cover_single(which) {
    union() {
        difference() { cover(which); head_R(which); }
        head_I(which);
    }
}

module cover_body(which) {
    difference() { cover(which); head_M(which); }
}

// The accent is grown very slightly before intersecting, so it OVERLAPS the
// body instead of sharing an exact boundary with it. Two solids that merely
// touch are separate bodies to the slicer, and it reports the accent as a
// floating region with nothing beneath it.
accent_grow = 1.04;

module cover_accent(which) {
    intersection() {
        cover(which);
        difference() {
            translate([0, 0, Z0 + 8])
                scale(accent_grow)
                    translate([0, 0, -(Z0 + 8)])
                        head_M(which);
            head_K(which);
        }
    }
}

// Four feet at 0.25mm steps. Try each in the shoe, keep the one that slides in
// with light thumb pressure and does not rattle.
//
// Centred on the verified foot_w, so the known-good width is the SECOND foot
// and there is a step either side of it. The first gauge in this file ran
// 18.0..18.6 and topped out below the width that turned out to fit.
// Overridable so a second, finer pass can home in:
//   openscad -D 'gauge_widths=[18.65,18.75,18.85,18.95]' ...
gauge_widths = [18.5, 18.75, 19.0, 19.25];

// 4 separate pieces, one per width - the linter's "separate body" errors on
// this part are expected, not a fault.
module gauge() {
    widths = gauge_widths;
    bar_h = 1.6;
    for (i = [0 : len(widths) - 1])
        translate([i * 26, 0, 0]) {
            foot(widths[i]);
            base_plate();
            // Bar count marks the width: 1 bar = widths[0], 4 bars = widths[3].
            // Stood ON the plate top and sunk 0.4mm into it. They were once
            // placed at a fixed height, then the plate was thickened by 1.2mm
            // and swallowed them - the gauge printed as four unmarked feet.
            for (b = [0 : i])
                translate([-6 + b * 3, 0, plate_top - 0.4 + bar_h / 2])
                    cube([1.4, 8, bar_h], center = true);
        }
}
assert(foot_w >= min(gauge_widths) && foot_w <= max(gauge_widths),
       str("gauge ", gauge_widths, " does not bracket foot_w ", foot_w));

// ------------------------------------------------------------ display

// Head only, sat on a round plinth, scaled so the whole thing is display_h.
module display(which, mode = "single") {
    k = display_scale;
    // sized off the HEAD, not the base plate, or the plinth becomes a saucer
    r = ((head_w - 3) / 2) * k + display_pad;
    union() {
        // The plinth belongs to the BODY only. Including it in the accent gave
        // a second copy of the whole base in the contrast colour.
        if (mode != "accent") cylinder(h = display_base, r = r);
        // Sunk into the plinth exactly as deep as the cover's base plate buries
        // it, so the bust is the cover's head scaled and nothing more. It used
        // to sit only 1mm in, which left the flat underside of each head
        // flaring out over the plinth - up to 2500mm2 of severe overhang on a
        // bust, all gone at this depth. (Resting exactly on
        // top would be worse: two solids that touch print as two objects.)
        //
        // Clipped at z = 0, so no head can hang below the plinth.
        intersection() {
            cylinder(h = 1000, r = r + 1);
            translate([0, 0, display_base - (plate_top - Z0) * k])
                scale(k)
                    translate([0, 0, -Z0]) {
                        if (mode == "accent") {
                            intersection() {
                                head_S(which);
                                difference() {
                                    translate([0, 0, Z0 + 8]) scale(accent_grow)
                                        translate([0, 0, -(Z0 + 8)]) head_M(which);
                                    head_K(which);
                                }
                            }
                        } else if (mode == "body") {
                            difference() { head_S(which); head_M(which); }
                        } else {
                            union() {
                                difference() { head_S(which); head_R(which); }
                                head_I(which);
                            }
                        }
                    }
        }
    }
}

if (part == "display")        display(who, "single");
else if (part == "display_body")   display(who, "body");
else if (part == "display_accent") display(who, "accent");
else if (part == "gauge") gauge();
else if (part == "body")   cover_body(who);
else if (part == "accent") cover_accent(who);
else if (part == "preview") {
    color("Gainsboro") cover_body(who);
    color("DimGray")   cover_accent(who);
}
else cover_single(who);
