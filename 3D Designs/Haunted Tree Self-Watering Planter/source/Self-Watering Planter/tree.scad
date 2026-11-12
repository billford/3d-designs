// The haunted tree: a third shell for the self-watering planter. A dead
// trunk with a face in its bark, broken off at the top in splinters; the
// plant grows out of the break. One color. Started 2026-10-28.
//
// The pot, dipstick and reservoir are planter.scad's, unchanged: this is only
// a different outside. The pot's lip sits flush with the rim, inside the
// splinters.
//
// SEPARATE PRINTS: 1 object (no supports, no brim, 5 wall loops):
//   tree                - the trunk, upright
//   tree_mark_silver    - optional BX mark inlays, under the base, as parts of
//   tree_mark_red         the same object; PLA only
// view_tree is a picture. Never slice it.
//
// Geometry comes from tree.py (tree_shapes.scad): re-run it after changing
// anything there. Built by build.sh.

include <planter.scad>
include <tree_shapes.scad>

part = "view_tree";  // tree | tree_mark_silver | tree_mark_red | view_tree

assert(abs(tree_for_h - shell_h) < 0.01, str("tree.py made the trunk for a ", tree_for_h, " rim; the shell is ", shell_h));
assert(tree_for_r_res == r_res && abs(tree_for_bore - (lip_r + seat_fit)) < 0.01,
       "the reservoir or the pot's lip changed: update tree.py and re-run it");

// A 2D outline pushed straight back into the trunk, from y0 out to y1
module from_front(y0, y1) {
    translate([0, -y0, 0]) rotate([90, 0, 0]) linear_extrude(y1 - y0) children();
}

module tree() {
    union() {
        difference() {
            intersection() { tree_trunk(); tree_top_cutter(); }
            shell_cavity();
            // above the rim, the splinters stand clear of the pot's lip. Turned
            // off the cutter's columns: at 255 deg a cylinder vertex landed on
            // one, and the 3-decimal lint merged them (10 bad edges)
            translate([0, 0, shell_h]) rotate(0.37) cylinder(r = tree_splinter_in, h = tree_top);
            // vents through the seat, under the lip where they can't be seen
            for (i = [0:vents - 1]) rotate(i * 360 / vents + 60)
                translate([r_res - 1, -vent_w / 2, z_seat - 1]) cube([lip_r - r_res + 1, vent_w, shell_h]);
            if (mark) bx_mark_pocket(mark_w, face = "bottom");
            // the eyes, back to a plane min_wall outside the reservoir
            from_front(tree_hole_back, 120) { tree_eye_l_2d(); tree_eye_r_2d(); }
            // the gaps between the grin's teeth
            from_front(tree_slit_back, 120) tree_slits_2d();
        }
    }
}

if (part == "tree") tree();
else if (part == "tree_mark_silver") bx_mark_inlay(mark_w, "B", face = "bottom");
else if (part == "tree_mark_red") bx_mark_inlay(mark_w, "x", face = "bottom");
else if (part == "view_tree") {
    color("saddlebrown") tree();
    color("dimgray") translate([0, 0, dz]) pot();
}
