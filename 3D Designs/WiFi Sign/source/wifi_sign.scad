// WiFi sign - a gremlin biting a wire, with an NFC tag hidden behind it.
//
// Printed FACE DOWN. The front lies on the build plate so it comes out
// glass-smooth, and every coloured feature is an inlay in the first few
// layers rather than a raised relief. Nothing overhangs, nothing needs
// support, and the tap target is the character itself.
//
//   openscad --render -D 'part="plate"'   -o plate.stl    wifi_sign.scad
//   openscad --render -D 'part="ink"'     -o ink.stl      wifi_sign.scad
//   openscad --render -D 'part="dark"'    -o dark.stl     wifi_sign.scad
//   openscad --render -D 'part="skin"'    -o skin.stl     wifi_sign.scad
//   openscad --render -D 'part="ear"'     -o ear.stl      wifi_sign.scad
//   openscad --render -D 'part="stand"'   -o stand.stl    wifi_sign.scad
//   openscad --render -D 'part="preview"' ...             all together
//
// Colours: plate WHITE, "ink" BLUE (text, QR, cable), "dark" BLACK (outlines,
// hoodie), "skin" GREEN (the gremlin himself), "ear" PINK (inner ears).
//
// The QR code comes from qr_example.scad, which encodes a PLACEHOLDER network
// (YourNetwork / YourPassword). Replace it with your own before printing:
//   python3 make_qr.py 'WIFI:S:<ssid>;T:WPA;P:<password>;;' > qr_example.scad

include <gremlin.scad>

part = "preview";   // plate | ink | dark | skin | ear | stand | preview

// Title font. Helvetica ships with macOS; on Linux or Windows use
// "Liberation Sans:style=Bold" (or any bold sans) - OpenSCAD falls back to a
// default font with only a warning if the one named here is missing.
label_font = "Helvetica:style=Bold";

// ------------------------------------------------------------------ plate
plate_w   = 200;    // landscape: the traced gremlin is nearly square, so
plate_h   = 150;    // stacking him under the QR made an unusably tall sign
plate_t   = 4.0;
corner_r  = 6;

inlay_t   = 0.8;    // depth of the coloured layers - 4 layers at 0.2mm

// ------------------------------------------------------------------- NFC
// Pocket in the BACK, so nothing shows from the front. NFC reads through PLA
// without trouble; what it does not tolerate is metal or a thick wall.
tag_d     = 25;     // small round sticker
tag_fit   = 0.6;    // diametral clearance
tag_depth = 0.8;    // sticker thickness plus a little
front_t   = 1.4;    // PLA left over the tag - thin enough to read reliably
grem_at   = [46, 2];    // gremlin centre, right-hand half
grem_w    = 94;        // figure width in mm
tag_at    = [46, 26];   // directly behind the gremlin's head

// -------------------------------------------------------------------- QR
// Usually 29x29 or 33x33 modules, depending on the length of the WiFi
// string. The code is centred on qr_at whatever its size. 2.0mm modules keep every feature well
// above the ~1.2mm floor where small features start printing inconsistently.
// The quiet zone is just white plate - the QR is an inlay, so the margin
// around it is already the right colour.
qr_mod    = 2.0;
qr_at     = [-55, -26];
qr_quiet  = 8;      // clear plate around the code, 4 modules

// ------------------------------------------------------------------ stand
// Separate part with a square-cornered slot, the pattern that worked on the
// stick figures. Rounded slot ends against a square-edged plate leave a gap
// you can see; square corners at 0.5mm clearance do not.
stand_w    = 150;
stand_d    = 72;    // deep enough to matter: the plate is ~57g and 178mm
                    // tall, and leaning 12 degrees puts its centre of mass
                    // 18.5mm behind the slot. At 46mm deep that left 4.5mm of
                    // margin - it would stand, and fall over if knocked.
stand_t    = 9;
lean       = 12;    // degrees off vertical
slot_fit   = 0.5;

$fn = 96;

// ------------------------------------------------------------- 2D helpers

module rrect(w, h, r) {
    offset(r = r) offset(r = -r) square([w, h], center = true);
}

// The gremlin: a wide head, big ears, chunky everything. Caricature beats
// subtlety at this scale - fine features disappear into the layer lines.
module gremlin_head() {
    hull() {
        translate([0, 5])   scale([1.15, 1]) circle(r = 16);
        translate([0, -14]) scale([0.8, 1])  circle(r = 9);    // pointed chin
    }
}

// Small, angled steeply UP, and set high on the head so they read as ears.
// The first version used 24mm triangles at 22 degrees; they hulled into the
// skull and the whole thing came out looking like a helmet.
module gremlin_ears() {
    for (s = [-1, 1]) scale([s, 1])
        translate([12, 12]) rotate(46)
            polygon([[0, -6], [19, 1], [0, 8]]);
}

module gremlin_body() {
    union() { gremlin_head(); gremlin_ears(); }
}

module gremlin_eyes() {
    for (s = [-1, 1]) translate([s * 8, 8]) circle(r = 5.4);
}

// Open grin with a couple of teeth left standing in it.
module gremlin_grin() {
    difference() {
        translate([0, -5]) scale([1, 0.6]) circle(r = 12);
        translate([0, 2]) square([30, 12], center = true);
        // Two teeth, not three. The third sat at x=2.4, exactly where the
        // wire enters the mouth, and the wire subtraction severed it from the
        // head - leaving a 2.5mm island of apricot floating in the grin.
        for (x = [-7, -2.3]) translate([x, -7]) square([2.8, 10], center = true);
    }
}

// The wire: out of the mouth and off to the right edge, with a kink so it
// reads as cable rather than a bar. Frayed copper end at the bite.
// Routed along the BOTTOM of the plate. The first version ran from the mouth
// up and to the right, straight across the QR - which would have corrupted the
// code and been invisible until someone tried to scan it.
// Starts IN the grin and runs out to the right along the bottom of the plate.
// It has to visibly emerge from the mouth or it reads as an unrelated squiggle
// lying next to the gremlin, which is what the first two attempts looked like.
module wire() {
    w = 3.0;
    pts = [[10, -67], [24, -73], [38, -67], [50, -74]];
    for (i = [0 : len(pts) - 2]) hull() {
        translate(pts[i])     circle(d = w);
        translate(pts[i + 1]) circle(d = w);
    }
    // frayed copper at the bite, splaying back into the mouth
    for (a = [-30, 0, 30]) translate([10, -67]) rotate(180 + a)
        hull() { circle(d = w * 0.7); translate([7, 0]) circle(d = 1.2); }
}

// Sizes chosen so the thinnest stroke clears the ~1.2mm floor. The first
// print used 6mm for the subtitle; Helvetica strokes at that size are about
// 0.8mm and the letters bled into each other. Shortening the words was the
// right fix, not shrinking them further.
module label() {
    translate([-55, 48])
        text("WiFi", size = 28, halign = "center", valign = "center",
             font = label_font);
    translate([-55, 27])
        text("scan or tap", size = 10, halign = "center",
             valign = "center", font = label_font);
}

// Loads the QR grid and hands it to its children as $qr_n / $qr. The include
// sits inside a block so its variables stay local to it.
module with_qr() {
    {
        include <qr_example.scad>
        $qr_n = qr_n; $qr = qr; children();
    }
}

// Modules are drawn 0.02mm oversize so neighbours OVERLAP rather than merely
// touch. Squares sharing an exact edge are the same trap as stacked solids
// meeting at a plane - valid geometry that the slicer reads as separate.
module qr_code() {
    s = qr_mod + 0.02;
    with_qr()
        translate([qr_at[0] - $qr_n * qr_mod / 2, qr_at[1] - $qr_n * qr_mod / 2])
            for (r = [0 : $qr_n - 1], c = [0 : $qr_n - 1])
                if ($qr[$qr_n - 1 - r][c] == 1)
                    translate([c * qr_mod, r * qr_mod]) square(s);
}

// --------------------------------------------------------------- 3D parts

module plate_solid() {
    linear_extrude(height = plate_t) rrect(plate_w, plate_h, corner_r);
}

module ink_2d()  { union() { label(); qr_code();
                             translate(grem_at) gremlin("cable", grem_w); } }
module dark_2d() { translate(grem_at) gremlin("dark", grem_w); }
module skin_2d() { translate(grem_at) gremlin("skin", grem_w); }
module ear_2d()  { translate(grem_at) gremlin("ear",  grem_w); }

// EVERYTHING on the face is mirrored in X. The plate prints front-side down,
// so the finished face is viewed from -Z and the X axis reverses. Text would
// read backwards and - the part that actually matters - a mirrored QR code
// does not scan. Mirroring here means the model reads correctly on the object.
module face(children_2d) { }   // (documentation anchor)

module ink()  { linear_extrude(height = inlay_t) mirror([1,0,0]) ink_2d(); }
module dark() { linear_extrude(height = inlay_t) mirror([1,0,0]) dark_2d(); }
module skin() { linear_extrude(height = inlay_t) mirror([1,0,0]) skin_2d(); }
module ear()  { linear_extrude(height = inlay_t) mirror([1,0,0]) ear_2d(); }

module plate() {
    difference() {
        plate_solid();
        // the coloured inlays are cut out of the white plate
        translate([0, 0, -0.01]) linear_extrude(height = inlay_t + 0.01)
            mirror([1,0,0]) union() { ink_2d(); dark_2d(); skin_2d(); ear_2d(); }
        // NFC pocket, opened from the BACK
        translate([tag_at[0], tag_at[1], plate_t - (plate_t - front_t)])
            cylinder(h = plate_t, d = tag_d + tag_fit);
    }
}

module stand() {
    slot_depth = stand_t - 2.5;      // leave a floor so it does not cut in two
    difference() {
        // plain block, front edge chamfered so it does not look like a brick
        hull() {
            translate([0, 1, 0])
                cube([stand_w, stand_d - 2, stand_t], center = true);
            translate([0, -stand_d / 2 + 1, -stand_t / 2 + 1])
                rotate([0, 90, 0]) cylinder(h = stand_w, r = 1, center = true);
        }
        // Slot cut from the TOP face, leaning back. Pivot at the top surface
        // so the lean does not also translate it - rotating a slot about the
        // origin was what put the first attempt outside the block entirely.
        translate([0, 0, stand_t / 2])
            rotate([lean, 0, 0])
                translate([0, 0, (20 - slot_depth) / 2])
                    cube([stand_w + 4, plate_t + slot_fit, slot_depth + 20],
                         center = true);
    }
}

// --------------------------------------------------------------- QR test
// A small two-colour tile carrying ONLY the code, so the mirroring can be
// checked with a phone before committing to the full sign. A mirrored QR
// looks perfect and does not scan; it is the one element on this sign that
// cannot be verified by eye.
//
//   openscad --render -D 'part="qrtest_plate"' -o qrtest_plate.stl wifi_sign.scad
//   openscad --render -D 'part="qrtest_ink"'   -o qrtest_ink.stl   wifi_sign.scad
//
// Print the same way as the real thing: FACE DOWN, ink in the first layers.
qr_tile_t = 2.0;

module qrtest_ink() {
    linear_extrude(height = inlay_t)
        mirror([1,0,0]) translate([-qr_at[0], -qr_at[1]]) qr_code();
}

module qrtest_plate() {
    difference() {
        with_qr() linear_extrude(height = qr_tile_t)
            rrect($qr_n * qr_mod + 2 * qr_quiet, $qr_n * qr_mod + 2 * qr_quiet, 3);
        translate([0, 0, -0.01]) linear_extrude(height = inlay_t + 0.01)
            mirror([1,0,0]) translate([-qr_at[0], -qr_at[1]]) qr_code();
    }
}

// ------------------------------------------------------------------ output
if (part == "qrtest_plate")    qrtest_plate();
else if (part == "qrtest_ink") qrtest_ink();
else if (part == "plate")      plate();
else if (part == "ink")   ink();
else if (part == "dark")  dark();
else if (part == "skin")  skin();
else if (part == "ear")   ear();
else if (part == "stand") stand();
else {
    color("White")      plate();
    color("RoyalBlue")  ink();
    color("DarkSlateGray") dark();
    color("YellowGreen") skin();
    color("LightSalmon") ear();
}
