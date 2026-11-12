// Dracula's head: a second shell for the self-watering planter, black and
// white, after the Halloween Bookmarks Dracula. Started 2026-10-28.
//
// The pot, dipstick and reservoir are planter.scad's, unchanged: this is only
// a different outside. The pot's lip sits flush with the top of his head and
// the plant is his hair.
//
// SEPARATE PRINTS: 1 object of 4 parts, loaded together as one multi-color
// print (no supports, no brim, PLA in every color so the colors fuse):
//   dracula_black        - the head, cape and collar
//   dracula_white        - face and ears; load as a PART of the same object
//   dracula_mark_silver  - BX mark inlays, under the base
//   dracula_mark_red
// view_dracula is a picture. Never slice it.
//
// Geometry comes from dracula.py (dracula_shapes.scad): re-run it after
// changing anything there. Built by build.sh.

include <planter.scad>
include <dracula_shapes.scad>

part = "view_dracula";  // dracula_black | dracula_white | dracula_mark_silver | dracula_mark_red | view_dracula

white_grow = 0.1;       // the white overlaps the black so the slicer sees one object, not a floating skin

assert(abs(dracula_for_h - shell_h) < 0.01, str("dracula.py made the head for a ", dracula_for_h, " rim; the shell is ", shell_h));
assert(dracula_for_r_res == r_res && abs(dracula_for_bore - (lip_r + seat_fit)) < 0.01,
       "the reservoir or the pot's lip changed: update dracula.py and re-run it");

module ear(t = dracula_ear_t, g = 0) {
    for (m = [0, 1]) mirror([m, 0, 0])
        translate([dracula_ear_at[0], dracula_ear_at[1], 0])
            rotate(dracula_ear_sweep - 40)
                rotate([90, 0, 0]) linear_extrude(t + 2 * g, center = true) offset(delta = g) polygon(dracula_ear);
}

// The face artwork, pushed straight back through the front half only
module face_prism(g) {
    rotate([90, 0, 0]) linear_extrude(200) offset(delta = g) dracula_white_2d();
}

// What is white: everything in front of the core inside the artwork, and the
// ears. The cutters reach PAST the outside, so the outside always comes from
// the body: a cutter whose face was the head's own surface left
// zero-thickness slivers along the face outline (27 four-way edges).
module white_zone(g) {
    difference() {
        union() { face_prism(g); ear(g = 0.5 + g); }
        dracula_core();
    }
}

module dracula_body() {
    difference() {
        union() { dracula_head(); dracula_collar(); ear(); }
        shell_cavity();
        // vents through the seat, under the lip where they can't be seen
        for (i = [0:vents - 1]) rotate(i * 360 / vents + 60)
            translate([r_res - 1, -vent_w / 2, z_seat - 1]) cube([lip_r - r_res + 1, vent_w, shell_h]);
        if (mark) bx_mark_pocket(mark_w, face = "bottom");
    }
}

if (part == "dracula_black") difference() { dracula_body(); white_zone(0); }
else if (part == "dracula_white") intersection() { dracula_body(); white_zone(white_grow); }
else if (part == "dracula_mark_silver") bx_mark_inlay(mark_w, "B", face = "bottom");
else if (part == "dracula_mark_red") bx_mark_inlay(mark_w, "x", face = "bottom");
else if (part == "view_dracula") {
    color("#202020") difference() { dracula_body(); white_zone(0); }
    color("white") intersection() { dracula_body(); white_zone(white_grow); }
}
