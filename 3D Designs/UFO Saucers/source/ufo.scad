// Flying saucer with lights inside.
//
// Two parts, both printing flat with no supports:
//   body - the saucer, open at the top, hollow for a battery pack
//   dome - lifts off, friction fit
//
// Lit by a pre-made fairy/wire light string: no soldering, no resistors, just
// stuff it in. The rim holes let the points of light out; the string's own
// battery pack lives in the cavity and its cable exits through a USB-C sized
// slot, so a pass-through charger or a USB power lead both fit later.
//
//   openscad --render -D 'part="body"' -o ufo_body.stl ufo.scad
//   openscad --render -D 'part="dome"' -o ufo_dome.stl ufo.scad

part = "body";   // body | dome | preview | section

// ---- overall ------------------------------------------------------------
dia        = 150;
wall       = 2.6;
floor_t    = 4.5;   // thick enough to take the cable groove below

// ---- saucer profile ------------------------------------------------------
// PROFILE ANGLES MATTER. The first version flared from a 44mm base out to the
// rim at 66 degrees from vertical - each layer stepping 0.45mm outward against
// a 0.42mm extrusion, so nothing underneath it. It drooped and eventually
// spaghettied two hours in. Every outward-leaning segment below must stay at
// or under 45 degrees.
rim_z      = 22;    // height of the widest point
body_h     = 34;    // top of the saucer, where the dome sits
base_r     = 56;    // flat bottom radius - wider than looks ideal, but this is
                    // what keeps the underside printable without support

// ---- dome ---------------------------------------------------------------
// Enlarged after the first print: the original 36 x 26 dome had nowhere near
// enough room for a light string and its battery pack.
dome_r     = 52;
dome_h     = 52;   // true hemisphere - taller reads as a canopy AND prints
                   // better: crown overhang 2791mm2 at 36, 1739 at 52
dome_wall  = 2.2;
lip_h      = 7;     // spigot that locates the dome in the body
// The collar lives on the BODY and the dome slips over it. Putting the spigot
// on the dome meant the dome printed standing on a 97mm ring only a few mm
// thick - almost no bed contact for a 43mm-tall part, and it spaghettied. This
// way the dome prints rim-down on its full flange, and the collar is just a
// continuation of the body, which is already printing upward.
collar_h    = 8;
collar_wall = 3.2;
// The dome's SKIRT flares out past the body's deck so the dome reads wider
// than the saucer's top, like a canopy rather than an inset cap. Only the bore
// (dome_r - dome_wall) touches the collar, so the skirt can be any width we
// like WITHOUT reprinting the body - which is the whole point of doing it this
// way. Printed rim-down the skirt is the first layer: a wide flat ring, so
// adhesion is excellent, and the cone narrows going up, which never overhangs.
skirt_out   = 16;   // how far past dome_r the skirt reaches (deck ends at +8)
skirt_h     = 10;   // height of the flare; also the socket depth over the collar
flange_out  = 4.0;  // how far the dome's rim flares OUTWARD. It cannot flare
                    // inward - the collar needs that space - so this is the
                    // only way to give the dome real bed contact. Also reads
                    // as a canopy rim where it meets the saucer.
fit        = 0.22;  // RADIAL clearance -> 0.44mm across the diameter, which
                    // matches the 0.45 that works on the flat joints here.
                    // Applying 0.45 radially made it twice as loose.

// ---- lights -------------------------------------------------------------
light_d    = 3.4;   // fairy light bulbs are ~3mm
light_n    = 24;    // count around the rim
light_z    = 13;

// ---- spindle ------------------------------------------------------------
// Fairy light kits carry far more LEDs than the 24 rim holes can use. Winding
// the surplus onto a central post puts it directly under the dome, so the
// excess lights the canopy instead of tangling in the bottom of the saucer.
spindle      = true;
spindle_d    = 30;
spindle_h    = 34;    // must clear the dome's interior
spindle_wall = 2.4;
spindle_lip  = 3.5;   // flange top and bottom, so the coil cannot slip off
wire_slot_w  = 4.5;   // notch to anchor the free end of the string

// ---- power --------------------------------------------------------------
// Sized for a USB-C plug body, not the bare connector, so a cable can pass
// through rather than only a soldered port.
usb_w      = 10.0;
usb_h      = 5.4;
usb_r      = 24;    // how far off centre the slot sits in the flat bottom
chan_w     = 7.0;   // cable channel, so it can exit without being sat on
chan_d     = 2.8;   // groove depth - MUST stay under floor_t or it
                    // becomes a slot straight through into the cavity

// Keep $fn an exact multiple of light_n. When holes fall on the revolve's
// facet seams rather than between them, the booleans produce coincident
// geometry and degenerate edges - 128 with 24 holes gave 16 bad edges.
$fn = 144;

// -------------------------------------------------------------- profiles

// [radius, height] around the outside of the saucer
outer_pts = [
    [0,          0],
    [base_r,     0],
    [dia/2 - 9,  rim_z - 9],    // 45 deg
    [dia/2,      rim_z],        // 45 deg, widest point
    [dia/2 - 10, rim_z + 7],    // inward from here, so no overhang
    [dome_r + 8, body_h],
    [0,          body_h],
];

// The cavity, pulled in by the wall thickness - and narrowed to the mouth at
// the top. Without that taper the cavity opens the entire top face, leaving
// the collar standing on nothing (a second, floating shell) and no ledge for
// the dome's flange to rest on.
mouth_r = dome_r - dome_wall - fit - collar_wall;

inner_pts = [
    [0,             floor_t],
    [base_r - wall, floor_t],
    [dia/2 - 9 - wall, rim_z - 9],
    [dia/2 - wall,  rim_z],
    [dia/2 - 10 - wall, rim_z + 7],
    [mouth_r,       body_h - 4],
    [mouth_r,       body_h + collar_h + 4],
    [0,             body_h + collar_h + 4],
];

module saucer_outer() { rotate_extrude() polygon(outer_pts); }
module saucer_cavity() { rotate_extrude() polygon(inner_pts); }

// ------------------------------------------------------------------ body

module light_holes() {
    for (i = [0 : light_n - 1])
        rotate([0, 0, i * 360 / light_n])
            translate([0, 0, light_z])
                rotate([-90, 0, 0])
                    cylinder(h = dia, r = light_d / 2);
}

// Through the FLAT BOTTOM rather than the sloped side. On the slope the hole
// comes out as a smeared oval and the cable has to bend immediately; through
// the floor it is a clean rounded slot, hidden from every viewing angle.
module usb_slot() {
    translate([usb_r, 0, -1])
        hull()
            for (x = [-1, 1])
                translate([x * (usb_w - usb_h) / 2, 0, 0])
                    cylinder(h = floor_t + 2, d = usb_h);
    // channel out to the edge, so the saucer does not rest on its own cable
    hull() {
        translate([usb_r, 0, -0.1]) cylinder(h = chan_d, d = chan_w);
        translate([base_r + 6, 0, -0.1]) cylinder(h = chan_d, d = chan_w);
    }
}

// Hollow, so it costs little filament and the wound coil can glow through it.
module spindle_post() {
    difference() {
        union() {
            cylinder(h = spindle_h, d = spindle_d);
            cylinder(h = spindle_lip, d = spindle_d + 7);            // base flare
            // Top flange as a CONE, not a disc. A flat lip here is a 3.5mm
            // ledge cantilevered into open air with a 90-degree underside -
            // it curls, and since it is the last thing on the part it takes
            // the nozzle with it. Flaring 3.5mm out over 3.5mm of rise is
            // exactly 45 degrees, so it self-supports and still stops the
            // coil slipping off.
            translate([0, 0, spindle_h - spindle_lip])
                cylinder(h = spindle_lip, d1 = spindle_d, d2 = spindle_d + 7);
        }
        translate([0, 0, -1])
            cylinder(h = spindle_h + 2, d = spindle_d - spindle_wall * 2);
        // notch to hook the free end of the string
        for (a = [0, 180])
            rotate([0, 0, a])
                translate([-wire_slot_w / 2, 0, spindle_h - spindle_lip - 1])
                    cube([wire_slot_w, spindle_d, spindle_lip + 3]);
    }
}

module body() {
    union() {
        difference() {
            union() {
                saucer_outer();
                // Collar as a SOLID cylinder - the cavity's neck hollows it.
                // Cutting its bore separately at the same radius as the neck
                // put two identical cylindrical surfaces on top of each other
                // and produced a full ring of degenerate edges.
                translate([0, 0, body_h - 2])
                    cylinder(h = collar_h + 2, r = dome_r - dome_wall - fit);
            }
            saucer_cavity();
            light_holes();
            usb_slot();
        }
        if (spindle)
            translate([0, 0, floor_t - 0.6]) spindle_post();
    }
}

// ------------------------------------------------------------------ dome

module dome() {
    union() {
        // shell
        difference() {
            resize([dome_r * 2, dome_r * 2, dome_h * 2])
                sphere(r = 1);
            resize([(dome_r - dome_wall) * 2, (dome_r - dome_wall) * 2,
                    (dome_h - dome_wall) * 2])
                sphere(r = 1);
            translate([0, 0, -dome_h - 1]) cylinder(h = dome_h + 1, r = dome_r + 1);
        }
        // Flared skirt at the rim: stands on the plate while printing, seats
        // over the collar in use, and overhangs the deck so the dome looks
        // wider than the body's top face.
        difference() {
            cylinder(h = skirt_h, r1 = dome_r + skirt_out, r2 = dome_r);
            translate([0, 0, -1])
                cylinder(h = skirt_h + 2, r = dome_r - dome_wall);
        }
    }
}

// ---------------------------------------------------------------- output

if (part == "dome") dome();
else if (part == "preview") {
    color("Gainsboro") body();
    color("SkyBlue") translate([0, 0, body_h]) dome();
}
else if (part == "section")
    intersection() {
        union() {
            body();
            translate([0, 0, body_h]) dome();
        }
        translate([-200, -200, -10]) cube([200, 400, 200]);
    }
else body();
