// Standing grey, for photography. Roughly 85mm tall on an integral plinth.
//
//   openscad --render -D 'part="figure"' -o alien_figure.stl alien.scad
//
// PRINTS STANDING, ONE PIECE, NO SUPPORTS. Everything that flares does so
// inside the lean limit for the layer height it is sliced at - see LAYER
// HEIGHT below, because on this model that is not a slicer preference, it is a
// geometry constraint.

// ONE PRINT: part="figure". Everything else is a view or a bisecting aid -
//   VIEWS/DEBUG  head  headsolid  plinth  torso  arms  legs  shadow  section
// Slicing any of those gives you a body part on its own.
part   = "figure";

// ---- size and pose ------------------------------------------------------
// Everything below is authored at 85mm and scaled. Set H and nothing else.
H        = 90;          // finished height above the plinth, mm
k        = H / 85;

// POSE IS A PARAMETER, NOT A MECHANISM. A print-in-place joint needs a ball of
// 6-8mm plus clearance; at H=60 the shoulders are about 2mm across, so real
// articulation is not available at this size and adding it would mean going
// bigger and accepting a joint that can seize or snap. Posing in the model
// costs nothing, cannot break, and still needs no assembly - print the stance
// you want.
//
// POSING LIFTS THE HANDS OFF THE THIGHS, AND THEN THEY NEED SUPPORT.
// The neutral figure prints support-free because the hands rest on the thighs.
// Any arm_spread or arm_swing swings them into open air - at spread 8 / swing 6
// the hands sat 4mm clear of the legs and started 25mm above anything solid.
// So: pose freely for renders and for the porthole shadow, but for a PRINT
// either leave the arms neutral or paint supports under the hands.
//
// POSE ANGLES: measured, not assumed. Sweeping arm_spread through an overhang check at
// H=60 and 0.2mm layers, 20/40/55 all pass and 70 raises overhang_severe
// (49mm2, steepest 80 deg). A round limb always has SOME downward-facing
// surface, so what matters is how much, not the lean alone - which is why the
// figure survives further than the flat-plate 46.4 limit would suggest.
// Keep under 45 for margin, go to 55 if a shot needs it, and check the
// slicer's overhang preview.
arm_swing  = 0;         // arms forward(+) / back(-)  -- see POSING below
arm_spread = 0;         // arms out from the body    -- see POSING below
leg_spread = 5;         // stance width
head_tilt  = -4;        // chin down(-) / up(+)

// The thinnest reliable feature is ~1.2mm (below about three
// nozzle widths the slicer's rounding decides whether a feature gets a full
// perimeter, and a symmetric pair can come out different). Anything at risk is
// held above that AFTER scaling, so shrinking H fattens the hands rather than
// quietly printing them as smudges.
min_feat = 1.2;
function fmin(v) = max(v, min_feat / k);

// ---- the skull flare ----------------------------------------------------
// The concave flare is what makes this read as a grey rather than a lightbulb,
// and concavity is bought with overhang:
//
//      r(z) = chin_r + (head_r - chin_r) * (z / temple_z)^flare_p
//      max lean = atan(flare_p * (head_r - chin_r) / temple_z)
//
// which is scale-invariant - shrinking the figure does not buy margin. Against
// the limit atan(0.42 / (2 * layer)) = 46.4 deg at 0.2mm, 60.3 at 0.12mm:
//
//      flare_p 1.0 -> 22.2 deg (a straight cone: what hull() gives)
//      flare_p 2.0 -> 39.2 deg   <- used here, 7 deg of margin even at 0.2mm
//      flare_p 2.5 -> 45.5 deg   (0.9 deg at 0.2mm - too close)
//      flare_p 3.0 -> 50.7 deg   (needs 0.16mm or finer)
//
// NOTE the flare runs from chin_r, not from zero. An earlier version clamped a
// curve that started at r=0 with max(low_r(z), chin_r), which put SIXTEEN
// sample points at exactly r=chin_r - fifteen zero-length edges, and 12
// non-manifold edges in the export. It also made the flare span the full radius
// rather than head_r-chin_r, which overstated the lean as 46.4 deg and had this
// file recommending 0.12mm layers it does not actually need.
flare_p = 2.0;

// ---- head ---------------------------------------------------------------
head_h   = 20;
head_r   = 7.2;         // half-width at the temples
head_yd  = 0.82;        // shallower front-to-back than side-to-side
temple_z = 13;          // height of the widest point above the chin
crown_h  = 7;
crown_n  = 2.5;
chin_r   = 1.9;         // NOT thinner: the chin carries the whole head, and a
                        // narrowed chin is what snapped the hot shoe alien off
                        // the plate. Concavity above it, mass at the joint.

eye_x    = 3.4;
eye_z    = 11.4;
eye_y    = -5.0;
eye_len  = 2.3;
eye_dep  = 2.1;         // drives how deep the recess cuts
eye_tal  = 1.15;
eye_tilt = 24;

// The eyes MUST NOT MERGE. At H=60 with eye_x 2.8 and eye_len 2.6 their inner
// ends sat 0.28mm apart and printed as one continuous slot across the face -
// the model was right, the gap was simply below anything a nozzle can resolve.
// Nothing warned about it: it is not an overhang, not a thin wall the slicer
// checks, and the mesh was perfectly valid. So assert it here, where it is
// cheap, rather than discovering it on the plate.
//
// The bridge is also why this figure has a minimum size. The skull is only
// 2*head_r wide, and two almonds plus a readable bridge do not fit inside it
// much below H=85 without the eyes running off the silhouette instead.
eye_bridge = 2 * (eye_x - eye_len) * k;
eye_tip_x  = eye_x + eye_len * cos(eye_tilt);
eye_tip_z  = eye_z + eye_len * sin(eye_tilt);
eye_margin = (low_r(eye_tip_z) - eye_tip_x) * k;

assert(eye_bridge >= min_feat,
       str("eyes would merge: bridge ", eye_bridge, "mm is under min_feat ",
           min_feat, "mm. Raise eye_x, lower eye_len, or raise H."));
assert(eye_margin > 0.5,
       str("eye runs off the side of the skull: margin ", eye_margin,
           "mm. Lower eye_x or eye_len."));

// ---- body ---------------------------------------------------------------
neck_r   = fmin(1.75);
neck_z   = 65;          // top of the neck / underside of the chin
neck_h   = 6.5;         // reaches down INTO the shoulder mass

sho_z    = 59;          // shoulder height
sho_x    = 5.0;
chest_r  = 4.6;
waist_z  = 40;
waist_r  = 2.9;
hip_z    = 33;
hip_r    = 3.8;

// Limbs. The reference's fingers come to about 1mm at this scale, under the
// 1.2mm where a feature prints inconsistently, so the hands are paddles. That
// is a caricature rule rather than a compromise: detail
// competes with layer lines and loses.
arm_r1   = 1.9;         // shoulder
arm_r2   = fmin(1.35);        // wrist
elbow_z  = 43;
wrist_z  = 28;
arm_out  = 0.4;         // NOT cosmetic - this is what keeps the hands off the
                        // support list. At 1.9 they hung clear of the body and
                        // each hand's lowest point was a disc starting 24mm up
                        // in MID-AIR with nothing beneath it. They printed as
                        // loose spaghetti. At 0.4 the hands rest against the
                        // thighs, so every layer grows from material below it.
                        // Sweep: 1.9 -> 144 island vertices, 0.5 -> zero.
hand_l   = 3.4;
hand_w   = fmin(2.2);
hand_t   = fmin(1.45);   // MUST NOT equal arm_r2: when both clamp to
                        // the same floor the hand is tangent to the wrist
                        // sphere instead of crossing it. Cost 24 edges.

leg_r1   = 2.7;         // thigh
leg_r2   = fmin(1.9);         // ankle
knee_z   = 17;
ank_z    = 2.6;
leg_x    = 2.5;
foot_l   = 7.0;
foot_w   = 3.6;

// ---- plinth -------------------------------------------------------------
base_h   = 3;
base_r   = 20;

// MICRO FEATURES. Cuts narrower than the nozzle can fill, so the slicer has to
// route PERIMETERS around them - which puts solid wall where it would otherwise
// have laid 10% infill. A modifier that lives in the geometry, so it survives
// being handed to another machine, material or slicer.
//
// It matters at exactly two places on this figure, and they are the two that
// carry it:
//
//   neck   4.15mm across -> 2 walls take 1.68mm, leaving a 2.47mm core
//   ankle  4.02mm across -> 2 walls take 1.68mm, leaving a 2.34mm core
//
// Those cores are mostly air, at the joints that snapped on the hot shoe alien
// and that hold up a 90mm figure. Thickening them is the usual fix and is not
// available here - being spindly is the whole subject - so induce walls instead.
//
// UNVERIFIED: whether a given slicer routes walls around a 0.2mm hole rather
// than closing it up is a slicer behaviour, not a geometry fact. CHECK THE
// LAYER PREVIEW before trusting it. If the holes vanish, widen micro_w toward
// 0.3mm until they show.
micro     = true;
micro_w   = 0.2;        // narrower than a 0.4mm nozzle can fill
micro_n   = 4;
micro_r   = 0.75;       // ring radius - inside the core, not through a wall

jnt      = 0.08;        // joint interpenetration. Kept SMALL: at 0.25
                        // each joint sphere was visibly fatter than the limb
                        // it joined and the figure read as segmented tubing.
                        // weld.py is what guarantees watertightness now, so
                        // this only has to stop surfaces kissing exactly.
$fn      = 72;

// ------------------------------------------------------------------- head
// Lower branch r = R*(z/zt)^p. p>1 starts narrow and accelerates outward,
// which is the concave cheek. A hull() of two spheres CANNOT do this: a hull is
// convex by definition, so its chin-to-temple line is always straight or
// bulging. That is the whole reason the shape reads wrong otherwise.
// SMOOTHSTEP, not a power curve. Both matter about this shape:
//
//   the derivative is ZERO at the chin, so the skull leaves the neck cleanly
//   the derivative is ZERO at the temple, so it MEETS THE CROWN WITHOUT A CORNER
//
// The first version used r = chin + (head-chin)*u^2, which is still climbing at
// slope 0.82 when it reaches the widest point while the crown leaves it at
// slope 0. That step is a hard rim right around the skull, and printed it reads
// unmistakably as a bowl cut. A render in flat colour hides it; the part does
// not.
//
// The S also happens to be the right shape: concave through the cheek, convex
// rounding over at the temple, which is how a grey's skull actually goes.
// Max lean drops to 31.4 degrees at mid-cheek, comfortably inside 46.4.
function smoothstep(u) = u * u * (3 - 2 * u);
function low_r(z)   = chin_r + (head_r - chin_r) * smoothstep(z / temple_z);
function crown_r(z) = head_r *
    pow(1 - pow((z - temple_z) / crown_h, crown_n), 1 / crown_n);

// The neck is part of THIS profile, not a separate capsule. Two coaxial solids
// of revolution meet along a circle where their radii cross, and that junction
// alone shed 8 unshared edges. One profile has no junction to shed them.
function head_pts() = concat(
    [[0, -neck_h], [neck_r * 1.12, -neck_h], [chin_r, 0]],
    [for (i = [1 : 40]) let (z = temple_z * i / 40) [low_r(z), z]],
    [for (i = [1 : 40]) let (z = temple_z + crown_h * i / 40) [crown_r(z), z]]
);

// The intersection with a big cube is NOT decorative. A bare rotate_extrude()
// whose profile touches the axis exports NON-MANIFOLD: OpenSCAD fans the axis
// vertex into $fn degenerate triangles. A plain cone does it too - 147 unshared
// edges and 288 degenerate facets at $fn=72, scaling with $fn. Forcing the
// result through any CGAL boolean rebuilds it cleanly (0 and 0).
//
module head_solid() {
    scale([1, head_yd, 1])
        intersection() {
            rotate_extrude() polygon(head_pts());
            cube([4 * head_r, 4 * head_r, 8 * head_h], center = true);
        }
}

// Ellipsoid cutters placed OUTSIDE the surface and driven inward, never at a
// guessed depth - a cutter that does not breach leaves an invisible internal
// void and a second shell. Tilted about Y: the almond's long axis runs along X,
// so tilting about Z would swing the cutter sideways across the skull.
module eyes() {
    for (s = [-1, 1])
        translate([s * eye_x, eye_y, eye_z])
            rotate([0, s * -eye_tilt, 0])
                scale([eye_len, eye_dep, eye_tal]) sphere(r = 1);
}

module micro_ring(z0, z1, ring_r = micro_r, n = micro_n) {
    if (micro)
        for (i = [0 : n - 1])
            rotate([0, 0, i * 360 / n])
                translate([ring_r, 0, z0])
                    cylinder(h = z1 - z0, d = micro_w, $fn = 8);
}

module head() {
    difference() {
        head_solid();
        eyes();
        // the neck, in the head's own coordinates: it runs -neck_h to 0
        micro_ring(-neck_h + 0.6, 3.0);
    }
}

// ------------------------------------------------------------------- body
module capsule(p1, r1, p2, r2) {
    hull() {
        translate(p1) sphere(r = r1);
        translate(p2) sphere(r = r2);
    }
}

module torso() {
    // shoulders -> chest -> waist -> hips, each section overlapping the next by
    // more than 0.4mm so the whole figure is ONE shell. Sections that merely
    // touch at a plane are separate solids to the slicer.
    hull() {
        for (s = [-1, 1]) translate([s * sho_x, 0, sho_z]) sphere(r = arm_r1 + 0.6);
        scale([1, 0.72, 1]) translate([0, 0, sho_z - 6]) sphere(r = chest_r);
    }
    // Each chained hull uses a slightly LARGER, slightly LOWER copy of the
    // sphere it shares with the one above. Sharing it exactly makes the two
    // hulls tangent along its silhouette circle - the same fault as the elbow.
    hull() {
        scale([1, 0.72, 1]) translate([0, 0, sho_z - 6 - jnt]) sphere(r = chest_r + jnt);
        scale([1, 0.78, 1]) translate([0, 0, waist_z]) sphere(r = waist_r);
    }
    hull() {
        scale([1, 0.78, 1]) translate([0, 0, waist_z - jnt]) sphere(r = waist_r + jnt);
        scale([1, 0.82, 1]) translate([0, 0, hip_z]) sphere(r = hip_r);
    }
}

module arms() {
    for (s = [-1, 1]) translate([s * sho_x, 0, sho_z])
        rotate([arm_swing, 0, 0]) rotate([0, s * -arm_spread, 0])
        translate([-s * sho_x, 0, -sho_z]) {
        // The joint spheres of the two capsules are deliberately NOT identical.
        // Sharing one exactly makes the two hulls tangent along its silhouette
        // circle - surfaces that kiss rather than cross, which is degenerate.
        // It cost 4 unshared edges per arm. Offset by jnt so they interpenetrate.
        capsule([s * sho_x, 0, sho_z], arm_r1,
                [s * (sho_x + arm_out * 0.45), 0, elbow_z], arm_r1 * 0.78);
        capsule([s * (sho_x + arm_out * 0.45), 0, elbow_z + jnt], arm_r1 * 0.78 + jnt,
                [s * (sho_x + arm_out), 0, wrist_z], arm_r2);
        // Paddle hand as a HULL off an oversized wrist sphere, not a free
        // ellipsoid overlapping one. An ellipsoid sitting on the wrist has to
        // be sized to either contain it or clear it; land near tangency and
        // you get slivers. A hull cannot graze - it is one convex solid - and
        // the oversized sphere guarantees it joins the forearm.
        hull() {
            translate([s * (sho_x + arm_out), 0, wrist_z - jnt])
                sphere(r = arm_r2 + jnt);
            translate([s * (sho_x + arm_out), 0, wrist_z - hand_l])
                scale([hand_w, hand_t, hand_l * 0.55]) sphere(r = 1);
        }
    }
}

module legs() {
    for (s = [-1, 1]) translate([s * leg_x, 0, hip_z])
        rotate([0, s * -leg_spread, 0])
        translate([-s * leg_x, 0, -hip_z])
        difference() {
        union() {
        capsule([s * leg_x, 0, hip_z + 1.8], leg_r1 + jnt,
                [s * (leg_x + 0.5), 0, knee_z], leg_r1 * 0.72);
        capsule([s * (leg_x + 0.5), 0, knee_z + jnt], leg_r1 * 0.72 + jnt,
                [s * (leg_x + 0.5), 0, ank_z], leg_r2);
        // foot: a flat sole, because a leg ending in a sphere meets the plinth
        // at a point and peels
        hull() {
            translate([s * (leg_x + 0.5), 0, ank_z]) sphere(r = leg_r2);
            translate([s * (leg_x + 0.5), -foot_l * 0.42, 0.9])
                scale([foot_w, foot_l * 0.5, 1.8]) sphere(r = 1);
        }
        }
        // ankle and lower shin, where the leg is thinnest
        translate([s * (leg_x + 0.5), 0, 0]) micro_ring(ank_z - 1.0, knee_z - 2);
    }
}

module plinth() {
    translate([0, 0, -base_h])
        cylinder(h = base_h + 0.6, r1 = base_r, r2 = base_r - 1.2);
}

// The intersection is the same CGAL rebuild used on the skull, applied to the
// whole assembly. Chained hulls and coaxial solids of revolution meet along
// circles where their radii momentarily match, and each near-tangency sheds a
// few unshared edges; at H=60 the union came out with 84. Forcing the finished
// union through one more boolean rebuilds it watertight instead of chasing
// every junction by hand.
// The figure without its plinth. Used for the shadow: a projection that
// included the plinth would put a 28mm disc across the alien's feet.
module figure_bare() {
    intersection() {
    union() {
        translate([0, 0, neck_z]) rotate([head_tilt, 0, 0]) head();
        torso();
        arms();
        legs();
    }
    translate([-3 * base_r, -3 * base_r, -base_h - 1])
        cube([6 * base_r, 6 * base_r, 3 * (neck_z + head_h)]);
    }
}

// Front-elevation outline. rotate([90,0,0]) first: projection() flattens along
// Z, so without it you get the plan view - a shadow of the top of its head.
module shadow() {
    projection() rotate([-90, 0, 0]) figure_bare();
}

module figure() {
    scale(k) intersection() {
    union() {
        translate([0, 0, neck_z]) rotate([head_tilt, 0, 0]) head();
        torso();
        arms();
        legs();
        plinth();
    }
    translate([-3 * base_r, -3 * base_r, -base_h - 1])
        cube([6 * base_r, 6 * base_r, 3 * (neck_z + head_h)]);
    }
}

// ----------------------------------------------------------------- output
xs_z = 0;   // height for part="xsection", a horizontal cut used to CHECK that
            // the micro features actually exist at a given layer

if      (part == "xsection") projection(cut = true) translate([0, 0, -xs_z]) figure();
else if (part == "shadow")  shadow();
else if (part == "torso")   torso();
else if (part == "arms")    arms();
else if (part == "legs")    legs();
else if (part == "headsolid") head_solid();
else if (part == "head")    head();
else if (part == "plinth")  plinth();
else if (part == "section")
    difference() { figure(); translate([-60, -60, -20]) cube([60, 120, 160]); }
else                        figure();
