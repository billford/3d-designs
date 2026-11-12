// Stick figure photography props - happy, sad, shocked, scared, stoic,
// half, and poe (Edgar Allan Poe)
// Flat cutouts, printed lying flat. No supports.
//   figure: openscad -D 'mood="sad"'   -o stick_sad.stl   stick_figures.scad
//   stand:  openscad -D 'part="stand"' -o stick_stand.stl stick_figures.scad

part       = "figure"; // "figure" | "stand" | "raven"
base       = "tang";   // "tang" = plugs into the separate stand
                       // "block" = cast into a solid plinth, prints standalone
mood       = "happy";  // happy | sad | shocked | scared | stoic | half | poe
render_all = false;    // true = lay out all seven moods side by side (preview only)
                       // (poe's hair, collar and longer neck follow `mood`, so
                       // they only appear when mood = "poe")

$fn = 64;

thickness = 6;   // extrusion depth; also the stand slot thickness
limb_w    = 8;
head_r    = 16;

hip_y      = 54;  // height of the pelvis above the feet
torso_len  = 46;  // pelvis -> shoulder line
shoulder_w = 44;  // full width of the shoulder bar (this is what was missing)
hip_w      = 18;  // full width of the pelvis bar
arm_len    = 40;
leg_len    = 54;
// poe needs a longer neck than the rest of the family: a wing collar has to be
// visible BETWEEN the chin and the shoulder bar, and 7mm of neck leaves it
// looking like a slightly fat neck instead of a collar.
neck_len   = (mood == "poe") ? 14 : 7;

tang_w = 40;  // plug under the feet that drops into the stand
tang_h = 12;

// For OTHER files that plug into this stand: `use` this file and call
// tang_dims() for [width, height, thickness] rather than retyping them.
function tang_dims() = [tang_w, tang_h, thickness];

// base = "block": cast the legs into a solid plinth instead. Prints as one
// piece, stands unaided, no separate stand needed.
block_w = 58;
block_h = 28;
block_d = 22;  // front-to-back depth; this is what keeps it upright
block_over = 1;  // how far the plinth rises past the tang - see figure()

fit_clearance = 0.5;  // slot is this much wider than `thickness`
                      // verified on the P1S in PLA: snug, correct fit
stand_l = 76;
stand_w = 34;
stand_h = 16;
slot_d  = 13;

spacing = 130;  // preview layout only

shoulder_y = hip_y + torso_len;
head_cy    = shoulder_y + neck_len + head_r;

// unit vector pointing "down and out", angle measured from straight down
function vdown(a, s) = [s*sin(a), -cos(a)];
function foot(a, s)  = [s*hip_w/2, hip_y] + leg_len*vdown(a, s);

module rod(p1, p2, w) {
    hull() {
        translate(p1) circle(d = w);
        translate(p2) circle(d = w);
    }
}

// ---------------------------------------------------------------- body

// POE, ADDITIVE. Everything in face() is a HOLE; these are silhouette, so they
// belong here. A caricature at 32mm across has room for about four ideas, and
// Poe's are: the moustache (does most of the work), the high domed forehead
// with hair swept back off it, heavy low brows, and the 1840s wing collar.
//
// Hair is added rather than cut because it has to change the OUTLINE - a
// receding hairline only reads if the head silhouette is no longer a circle.
module poe_hair() {
    // The head is r=16. Hair placed at radius 13 with r=8 circles only breaks
    // the outline by 3-5mm, which reads as a MISSHAPEN SKULL rather than hair -
    // that was the first attempt. It has to clear the head decisively and be
    // obviously asymmetric, or the eye reads it as a bad circle.
    hull() { translate([-4, 13]) circle(r = 9.5);
             translate([ 6, 12]) circle(r = 8.0); }
    // the sweep: a defined point out to one side, which is the single feature
    // that says "parted and combed across" instead of "hat"
    hull() { translate([-4, 13]) circle(r = 9.5);
             translate([-19, 7]) circle(r = 3.2); }
    // fills the back of the crown so the sweep does not look stuck on
    hull() { translate([ 6, 12]) circle(r = 8.0);
             translate([13,  3]) circle(r = 5.0); }
}

// 1840s wing collar and cravat, filling the 7mm of neck between the shoulder
// bar and the chin. Small, but it is the difference between a moustache on a
// stick figure and a Victorian one.
module poe_collar() {
    // wing collar: points UP and OUT from the cravat, which is the shape that
    // says 1840s. Kept wider than the shoulder bar is thick so it is not just
    // read as more neck.
    for (s = [-1, 1])
        hull() { translate([s*2,  2]) circle(r = 3.0);
                 translate([s*11, 10]) circle(r = 1.6); }
    translate([0, 3]) circle(r = 4.2);          // cravat knot
}

module body(arm_l, arm_r, leg_a) {
    sh_x = shoulder_w/2;
    hp_x = hip_w/2;

    rod([-sh_x, shoulder_y], [sh_x, shoulder_y], limb_w);  // shoulder bar
    rod([-hp_x, hip_y],      [hp_x, hip_y],      limb_w);  // pelvis bar
    rod([0, hip_y],          [0, shoulder_y],    limb_w);  // spine
    rod([0, shoulder_y],     [0, head_cy],       limb_w);  // neck

    for (s = [-1, 1]) {
        shoulder = [s*sh_x, shoulder_y];
        arm_a    = (s == -1) ? arm_l : arm_r;
        rod(shoulder, shoulder + arm_len*vdown(arm_a, s), limb_w*0.9);
        rod([s*hp_x, hip_y], foot(leg_a, s), limb_w);
    }

    translate([0, head_cy]) circle(r = head_r);
    if (mood == "poe") {
        translate([0, head_cy]) poe_hair();
        translate([0, shoulder_y]) poe_collar();
    }

    // plinth the feet sink into; also the plug that drops into the stand
    fy = foot(leg_a, 1)[1];
    translate([-tang_w/2, fy - tang_h]) square([tang_w, tang_h + limb_w/2]);
}

// ---------------------------------------------------------------- face

module brow(s, tilt, y) {
    translate([s*6.5, y])
        rotate([0, 0, s*-tilt])
            square([9, 2], center = true);
}

module smile(open_up) {
    // crescent: subtract an offset copy of the same circle
    difference() {
        circle(r = 9);
        translate([0, open_up ? 3.4 : -3.4]) circle(r = 9);
    }
}

module wavy_mouth() {
    pts = [for (i = [0:6]) [-7.5 + i*2.5, (i % 2 == 0) ? 1.4 : -1.4]];
    for (i = [0:len(pts)-2]) rod(pts[i], pts[i+1], 2);
}

// The moustache. Blunt tips on purpose: tapering them to points would put the
// ends under the 1.2mm where a feature prints inconsistently, and a moustache
// with one thin side and one fat side is worse than a slightly blunt one.
module poe_moustache() {
    circle(r = 2.6);
    for (s = [-1, 1])
        hull() { translate([s*3, 0])  circle(r = 2.6);
                 translate([s*8.5, -2.4]) circle(r = 1.8); }
}

module face(m) {
    wide  = (m == "shocked" || m == "scared");
    eye_r = (m == "poe") ? 2.2 : wide ? 3.6 : 2.4;
    eye_y = (m == "poe") ? 3 : 4;

    // poe: heavy brows sitting LOW and level - deep-set and unamused, not sad.
    // Angling them would read as a mood; Poe reads as a face.
    tilt = (m == "sad") ? 18 : (m == "scared") ? 24 : (m == "poe") ? -6 : 0;
    brow_y = (m == "poe") ? 8.5 : eye_y + (wide ? 8 : 6.5);

    // 1.2mm is the smallest feature this printer resolves, and the same limit
    // applies to the GAP between two features - the alien's eyes were 0.28mm
    // apart and printed as one slot. Check it rather than eyeballing it.
    assert(m != "poe" || (brow_y - 1.5) - (eye_y + eye_r) >= 1.2,
           "poe: brow and eye are too close and will merge into one hole");

    translate([0, head_cy]) {
        for (s = [-1, 1]) {
            translate([s*6.5, eye_y]) circle(r = eye_r);
            // happy reads better browless; "half" raises one brow only
            if (m == "half") { if (s == -1) brow(s, 0, brow_y + 1); }
            else if (m == "poe") translate([s*6.5, brow_y])
                                     rotate([0, 0, s*-tilt])
                                         square([11, 3], center = true);
            else if (m != "happy") brow(s, tilt, brow_y);
        }

        translate([0, -6.5]) {
            if (m == "happy")        smile(true);
            else if (m == "sad")     smile(false);
            else if (m == "shocked") circle(r = 4);
            else if (m == "stoic")   rod([-6, 0], [6, 0], 2.4);
            else if (m == "half")    rotate([0, 0, 20]) smile(true); // lopsided
            else if (m == "poe")     { translate([0, 1.5]) poe_moustache();
                                       translate([0, -5.5]) rod([-3.5, 0], [3.5, 0], 2); }
            else                     wavy_mouth();   // scared
        }

        if (m == "sad") translate([-6.5, -3]) circle(r = 2.1); // tear
    }
}

// ---------------------------------------------------------------- parts

module figure(m) {
    // arms are per-side so a figure can be asymmetric (see "half")
    // poe: arms DOWN. Folded arms were tried and abandoned - swung inward they
    // merge with the torso into one solid triangle, and a stick figure whose
    // limbs have fused is no longer a stick figure. The head carries this one.
    arm_l = (m == "poe")     ? 14 :
            (m == "happy")   ? 150 :
            (m == "sad")     ?  16 :
            (m == "shocked") ? 112 :
            (m == "stoic")   ?  90 :
            (m == "half")    ? 150 : 168;  // scared: hands up by the head
    arm_r = (m == "half")    ?  18 : arm_l;

    // legs stay near-vertical: splayed legs + the plinth read as a skirt
    leg_a = (m == "poe")     ? 3 :
            (m == "happy")   ? 7 :
            (m == "shocked") ? 7 :
            (m == "scared")  ? 2 : 4;

    blocked = (base == "block");
    // Figure stays flush with the bed (z=0) and the block grows behind it.
    // Centring the figure in the block would float it 8mm up and force
    // supports under every limb; the block's depth alone keeps it upright.
    linear_extrude(height = thickness)
        difference() {
            body(arm_l, arm_r, leg_a);
            face(m);
        }

    if (blocked) {
        fy = foot(leg_a, 1)[1];
        // +block_over on the height, NOT on the origin: the plinth has to rise
        // PAST the tang's top edge rather than meet it. Both were landing on
        // exactly y = fy + limb_w/2, and two solids sharing a plane are two
        // solids - every mood reported exactly 8 unshared edges along that line,
        // deterministically, since long before poe existed. Overlap 0.4mm or
        // more; 1mm here, and the tang ends up entirely inside the plinth.
        translate([-block_w/2, fy + limb_w/2 - block_h, 0])
            cube([block_w, block_h + block_over, block_d]);
    }
}

// ---------------------------------------------------------------- raven
//
// A companion piece, not a mood - so it is a `part`, not a `mood`. It lives in
// THIS file rather than its own because it shares the tang and therefore the
// stand: duplicating tang_w and thickness into a second file is how two parts
// that are supposed to fit the same socket quietly stop fitting it.
//
// Perched, hunched, side profile, facing left. About 90mm tall against the
// figure's 193, which is the proportion that reads as "bird beside a man"
// rather than "small man".

raven_leg_w = 6;
raven_foot_y = 0;    // feet sit here; the tang hangs below

module raven_body() {
    // torso: two hulls sharing the big chest circle, so the back tapers up to
    // the neck and the belly tapers down to the legs
    hull() { translate([ 4, 40]) circle(r = 21);
             translate([-2, 63]) circle(r = 15); }
    hull() { translate([ 4, 40]) circle(r = 21);
             translate([11, 21]) circle(r = 12); }

    // neck into head, HUNCHED - head forward of the shoulders and set low. An
    // upright neck reads as a songbird; a raven broods.
    hull() { translate([ -2, 63]) circle(r = 15);
             translate([-15, 74]) circle(r = 12); }

    // THE BEAK IS THE TELL. A raven's is long, deep at the base and hooks down
    // at the tip; the first attempt was a short wedge and the whole bird read
    // as a kingfisher. Blunt tip on purpose - a true point tapers below 1.2mm
    // and prints as a ragged whisker.
    hull() { translate([-21, 73]) circle(r = 7.5);
             translate([-41, 69]) circle(r = 3.4); }
    hull() { translate([-41, 69]) circle(r = 3.4);
             translate([-50, 64]) circle(r = 1.8); }   // the hook

    // HACKLES - the shaggy throat. This is what separates a raven from a crow,
    // and it is the second thing after the beak that makes the silhouette read.
    // Three angular points down the throat rather than a smooth curve.
    hull() { translate([-13, 63]) circle(r = 6); translate([-20, 55]) circle(r = 2.2); }
    hull() { translate([ -9, 58]) circle(r = 7); translate([-17, 48]) circle(r = 2.4); }
    hull() { translate([ -5, 52]) circle(r = 8); translate([-13, 41]) circle(r = 2.6); }

    // wedge tail - ravens carry a diamond-tipped wedge where a crow's fans out
    hull() { translate([11, 25]) circle(r = 12);
             translate([46,  6]) circle(r = 4.5); }
    hull() { translate([46,  6]) circle(r = 4.5);
             translate([56,  1]) circle(r = 1.8); }

    // legs down to the tang
    for (x = [-2, 9])
        rod([x, 24], [x, raven_foot_y + 2], raven_leg_w);

    // tang: same width and thickness as the figure's, so one stand takes either
    translate([-tang_w/2, raven_foot_y - tang_h]) square([tang_w, tang_h + 4]);
}

module raven_cuts() {
    translate([-19, 77]) circle(r = 2.4);              // eye, set forward

    // folded wing, as a swept line of rods. Cut rather than raised: a raised
    // band on a flat plate is just a taller plate, but a cut reads as shadow.
    // STOPS SHORT OF THE TAIL. Run down to [28,21] it met the first feather
    // split, and the two cuts together fenced a 19x15mm sliver of tail off from
    // the rest of the bird - a second shell, and in the real part a loose piece
    // that falls out. Same fault as the WiFi sign, where the wire crossing the
    // grin pinched off a 2.5mm island.
    wing = [[-2, 58], [8, 51], [17, 41], [24, 30]];
    for (i = [0 : len(wing)-2]) rod(wing[i], wing[i+1], 3);

    // three feather splits in the tail
    // kept SHORT and inboard: at 16mm they ran off the tail's edge and
    // serrated the outline instead of reading as feather splits
    for (i = [0 : 2])
        translate([31 + i*7, 19 - i*4]) rotate([0, 0, -29])
            square([11, 2.6], center = true);
}

module raven() {
    blocked = (base == "block");
    linear_extrude(height = thickness)
        difference() { raven_body(); raven_cuts(); }

    if (blocked)
        translate([-block_w/2, raven_foot_y + 4 - block_h, 0])
            cube([block_w, block_h + block_over, block_d]);
}

module stand() {
    // Square-cornered pocket: the tang is a plain rectangle, so a hulled
    // (round-ended) slot binds on its corners no matter how wide it is.
    slot_w = thickness + fit_clearance;
    slot_l = tang_w   + fit_clearance*2;
    difference() {
        hull()
            for (x = [-1, 1], y = [-1, 1])
                translate([x*(stand_l/2 - 5), y*(stand_w/2 - 5), 0])
                    cylinder(h = stand_h, r = 5);

        translate([0, 0, stand_h - slot_d])
            translate([-slot_l/2, -slot_w/2, 0])
                cube([slot_l, slot_w, slot_d + 1]);
    }
}

// ---------------------------------------------------------------- output

if (render_all) {
    moods = ["happy", "sad", "shocked", "scared", "stoic", "half", "poe"];
    for (i = [0:len(moods)-1])
        translate([(i - (len(moods)-1)/2)*spacing, 0]) figure(moods[i]);
} else if (part == "stand") {
    stand();
} else if (part == "raven") {
    raven();
} else {
    figure(mood);
}
