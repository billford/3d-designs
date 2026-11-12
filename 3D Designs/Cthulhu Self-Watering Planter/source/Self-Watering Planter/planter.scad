// Self-watering planter: a soil pot that sits in a decorative outer shell,
// and the shell is the water reservoir. Started 2026-10-27, for small indoor
// plants (about a 10cm pot), in PETG.
//
// HOW IT WATERS. The pot's floor is a steep cone that funnels down into a
// slotted WELL. Soil packed into the well stands in the reservoir and wicks
// water up into the pot; no cotton wick to rot or dry out. Fill through the
// TUBE at the pot's edge, which drops straight through the cone into the
// reservoir. The dipstick in the tube shows the level.
//
// HOW IT BREATHES. Narrow slots in the pot's upper wall let air reach the
// roots. The gap behind them vents through the fill tube and through notches
// in the shell's seat, hidden under the pot's lip.
//
// WHY THE FLOOR IS A CONE. The pot prints upright, and a flat floor above a
// well would be a 90-degree overhang. A cone at 50 degrees from horizontal
// leaves 40 degrees from vertical, inside the 46.4 limit at 0.2mm layers, so
// the pot prints with no supports. It also drains soil and water to the well.
//
// SEPARATE PRINTS: 3, no supports, no brim.
//   shell    - the reservoir: R'lyeh stone with tentacles, open side up. PLA is
//              fine indoors out of the sun (it softens ~55C), PETG anywhere.
//              PLA takes the BX inlays: shell_mark_silver, shell_mark_red.
//   pot      - the soil pot, open side up, standing on its fins. PETG: it is
//              damp all the time
//   dipstick - lying flat
// view_assembly and view_section are pictures. Never slice them.
//
// Assembly: drop the pot into the shell; its lip settles on the shell's seat.
// The dipstick goes down the fill tube. Nothing to glue, screw or snap.

use <../Makers Mark/mark.scad>
include <tentacles.scad>

part = "view_section";  // shell | shell_mark_silver | shell_mark_red | pot | dipstick | view_assembly | view_section

/* [Print] */
layer_h = 0.2;          // the MAXIMUM layer height it will be sliced at
min_feat = 1.2;         // smallest reliable feature, and gap (CLAUDE.md)
overhang_max = atan(0.42 / (2 * layer_h));   // 46.4 at 0.2mm

/* [Pot] */
pot_r = 46;             // outer radius at the rim, under the lip: 88mm of soil opening
pot_taper = 3;          // degrees; the wall leans out so the root ball slides out
wall = 2;               // pot wall, measured square to the surface
soil_h = 42;            // straight wall above the cone
cone_a = 50;            // floor slope from horizontal; 90 - cone_a is the overhang
well_r = 15;            // the wicking well, outer radius
well_h = 28;            // also sets the full-water line: the top of the well
lip_w = 5;              // how far the lip reaches out over the shell's seat
lip_a = 40;             // lip flare from vertical: under the overhang limit
lip_band = 2;           // vertical band above the flare, the rim you see

// Feet. Upright, the pot is 112mm tall on a 30mm well, heavy at the top: the
// shape the pumpkin stem was knocked over in, twice (DESIGN-NOTES, brim note).
// Radial fins from the well out under the cone widen the first layer to about
// 86mm. They stand in the reservoir, where they cost almost no water.
fins = 4;
fin_t = 2.4;

/* [Slots] */
slot_w = 1.2;           // min_feat: wide enough to print, narrow enough to hold soil
well_slots = 8;
air_slots = 16;
tube_keep = 25;         // degrees each side of the fill tube with no air slots

/* [Fill tube] */
tube_ri = 7;            // 14mm bore: takes a watering can's spout
tube_wall = 1.6;
tube_ang = 0;

/* [Shell] */
shell_wall = 2;         // print with 5 wall loops, so it is all perimeter (README)
// 8 layers at 0.2mm: Studio's default 3 bottom + 5 top shells make it solid,
// with no sparse infill for water to find its way through
shell_floor = 1.6;
gap = 1.5;              // radial gap between pot and shell, for air and water
seat_fit = 0.3;         // radial clearance round the lip's vertical band
well_clear = 2;         // the well's foot stands this far off the shell floor
vents = 3;
vent_w = 4;

/* [Stone] */
// The shell's outside is a block of R'lyeh stone with tentacles climbing it
// (tentacles.py writes tentacles.scad, which sits on stone_ap).
stone_sides = 9;
stone_ap = 56;          // inscribed radius: leaves 2.7mm behind a glyph at the seat
courses = [38, 79];     // heights of the horizontal joints between stone courses
course_d = 2;           // 2mm reads as a shadow line (CLAUDE.md)
glyph_d = 2;
glyph_flank = 1.15;     // cone radius / depth: flanks 41 deg from vertical, under the limit
// spiral glyphs on faces the tentacles leave clear: [face angle, height, turns]
glyphs = [[140, 58, 2.25], [260, 58, 2.25], [340, 97, 2]];   // face centers are 20 + 40k
glyph_r = 12;

/* [Dipstick] */
stick_w = 10;
stick_t = 3;
stick_handle = 14;      // how far it stands above the rim
mark_d = 1.5;           // notch depth for the level marks

/* [Makers mark] */
mark = true;            // under the shell; inlays only if the shell is PLA (they won't fuse to PETG)
mark_w = 18;

$fn = 120;
eps = 0.01;

// --- derived ---------------------------------------------------------------
r_b = pot_r - soil_h * tan(pot_taper);          // pot's outer radius where the cone meets the wall
z_c = well_h + (r_b - well_r) * tan(cone_a);    // top of the cone
z_top = z_c + soil_h;                           // where the lip starts
z_flare = z_top + lip_w / tan(lip_a);
z_rim = z_flare + lip_band;
lip_r = pot_r + lip_w;
dz = shell_floor + well_clear;                  // the pot's z in the shell
r_res = pot_r + gap;                            // reservoir wall radius
shell_r = lip_r + seat_fit + shell_wall;
shell_h = dz + z_rim;
z_seat = dz + z_top + gap / tan(lip_a);         // where the lip meets the seat
tube_r = r_b - wall - tube_ri - tube_wall + 0.5;  // tube's axis, sunk 0.5 into the wall
z_full = dz + well_h;                           // full-water line, shell frame
stick_len = shell_h - shell_floor + stick_handle;
// litres to the full line: the reservoir cylinder, less the well
res_ml = (PI * r_res * r_res * (z_full - shell_floor) - PI * well_r * well_r * well_h) / 1000;

echo(str("pot ", 2 * lip_r, " across lip, ", z_rim, " tall; shell ", 2 * shell_r, " x ", shell_h,
         "; reservoir ~", round(res_ml), " ml to the full line"));

assert(90 - cone_a <= overhang_max - 3, str("cone floor overhangs ", 90 - cone_a, " deg"));
assert(lip_a <= overhang_max - 3, str("lip flare overhangs ", lip_a, " deg"));
assert(slot_w >= min_feat, str("slot ", slot_w, " under min_feat"));
assert(2 * PI * (well_r - wall) / well_slots - slot_w >= 3 * min_feat, "well slots too close");
assert(stick_w + 1 <= 2 * tube_ri, str("dipstick ", stick_w, " won't slide in a ", 2 * tube_ri, " bore"));
// the tube drops through the cone floor: it must miss the well entirely
assert(tube_r - tube_ri - tube_wall > well_r + 2, "fill tube lands on the well");
assert(stone_ap - max(glyph_d, course_d) >= shell_r,
       str("carving leaves ", stone_ap - max(glyph_d, course_d) - (shell_r - shell_wall), "mm of wall at the seat"));
assert(2 * stone_ap / cos(180 / stone_sides) + 30 <= 230, "shell over the P1S's practical bed");

// --- pot -------------------------------------------------------------------
// The outer silhouette, right half, bottom to top. Monotonic in r above the
// well, so the pot can drop into a shell cut from the same profile.
function pot_pts(extra = 0) = [
    [well_r, 0], [well_r, well_h], [r_b, z_c], [pot_r, z_top],
    [lip_r, z_flare], [lip_r, z_rim + extra]];
function mirrored(p) = concat(p, [for (i = [len(p) - 1:-1:0]) [-p[i][0], p[i][1]]]);

module pot_section() {
    // offset(delta) of the whole silhouette gives a wall of constant
    // thickness on the cone as well as the walls; the taller copy keeps the
    // top open
    intersection() {
        difference() {
            polygon(mirrored(pot_pts()));
            offset(delta = -wall) polygon(mirrored(pot_pts(10)));
        }
        translate([0, -1]) square([lip_r + 1, z_rim + 2]);
    }
}

module pot_envelope() {
    rotate_extrude() polygon(concat([[0, 0]], pot_pts(), [[0, z_rim]]));
}

module pot() {
    difference() {
        union() {
            rotate_extrude() pot_section();
            // fins, between the fill tube's path and the next; each grows from
            // the bed and runs up into the cone's underside, 0.5 deep
            for (i = [0:fins - 1]) rotate(tube_ang + (i + 0.5) * 360 / fins)
                intersection() {
                    translate([well_r - 1, -fin_t / 2, 0]) cube([r_b - 1 - well_r, fin_t, z_c]);
                    rotate_extrude() polygon([[0, 0], [r_b, 0],
                        [r_b, well_h + (r_b - well_r) * tan(cone_a) + 0.5 / cos(cone_a)],
                        [well_r, well_h + 0.5 / cos(cone_a)], [0, well_h]]);
                }
            // the fill tube, grown up off the cone and the wall
            intersection() {
                rotate(tube_ang) translate([tube_r, 0, 0]) cylinder(r = tube_ri + tube_wall, h = z_rim);
                pot_envelope();
            }
        }
        rotate(tube_ang) translate([tube_r, 0, -1]) cylinder(r = tube_ri, h = z_rim + 2);
        // wicking slots, from just above the well's floor
        for (i = [0:well_slots - 1]) rotate(i * 360 / well_slots + 180 / well_slots)
            translate([well_r - wall - 1, -slot_w / 2, wall]) cube([wall + 2, slot_w, well_h - wall - 3]);
        // air slots in the upper wall, clear of the fill tube
        for (i = [0:air_slots - 1]) let(a = i * 360 / air_slots + 180 / air_slots)
            if (abs(((a - tube_ang + 540) % 360) - 180) > tube_keep)
                rotate(a) translate([r_b - wall - 2, -slot_w / 2, z_c + 6])
                    cube([pot_r - r_b + wall + 4, slot_w, soil_h - 12]);
    }
}

// --- shell -----------------------------------------------------------------
module shell_cavity() {
    rotate_extrude() polygon([
        [0, shell_floor], [r_res, shell_floor], [r_res, z_seat],
        [lip_r, dz + z_flare], [lip_r + seat_fit, dz + z_flare],
        [lip_r + seat_fit, shell_h + 1], [0, shell_h + 1]]);
}

// The stone block, before carving: a prism with a chamfered foot (an edge
// parallel to the plate gets a chamfer, not a fillet)
module stone_block(ap = stone_ap, h = shell_h) {
    c = 1;
    hull() {
        linear_extrude(c + eps) circle(r = (ap - c) / cos(180 / stone_sides), $fn = stone_sides);
        translate([0, 0, c]) linear_extrude(h - c) circle(r = ap / cos(180 / stone_sides), $fn = stone_sides);
    }
}

// A V-ring round the stone at height z: deepest at z, opening course_d above
// and below, so both flanks are 45 deg and the upper one prints as a slope
// A round V-groove: everything outside a revolved hourglass whose waist is
// the groove's bottom. Round, not nine-sided, so it cuts deeper at the block
// corners like worn stone, and no corner of the cutter lands on a corner of
// the prism (a nine-sided cutter did, and left sliver edges at z77). Earlier
// still, a hull of three rings was convex and cut a square band.
module course_cut(z) {
    o = course_d + 4;                 // flanks rise 1:1 from the waist, out past every corner
    w = stone_ap - course_d;          // the waist's radius
    difference() {
        translate([0, 0, z - o]) cylinder(r = stone_ap + 10, h = 2 * o);
        rotate_extrude($fn = 180) polygon([[0, z - o - 1], [w + o + 1, z - o - 1], [w, z], [w + o + 1, z + o + 1], [0, z + o + 1]]);
    }
}

// A spiral carved into one flat face: a cone (apex inward) swept along the
// spiral by hulling neighbours, so every flank is the same printable slope
module glyph(a, z, turns) {
    n = round(turns * 36);
    pts = [for (i = [0:n]) let(t = i / n, r = glyph_r * (0.12 + 0.88 * t), q = 360 * turns * t)
           [r * cos(q), r * sin(q)]];
    rotate(a) translate([stone_ap, 0, z])
        for (i = [0:n - 1]) hull() for (p = [pts[i], pts[i + 1]])
            translate([0, p[0], p[1]]) rotate([0, -90, 0])
                translate([0, 0, -1]) cylinder(r1 = glyph_flank * (glyph_d + 1), r2 = 0, h = glyph_d + 1, $fn = 16);
}

// The decorated outside. Everything here stays outside the cavity, which
// shell() cuts after the union, so tentacles can never open the reservoir.
module shell_skin() {
    assert(abs(tentacles_for_apothem - stone_ap) < 0.01 && abs(tentacles_for_h - shell_h) < 0.05,
           str("tentacles.scad was made for apothem ", tentacles_for_apothem, ", h ", tentacles_for_h,
               "; the shell is ", stone_ap, ", ", shell_h, ": update tentacles.py and re-run it"));
    // the tentacles bury their undersides below these grooves where they cross
    assert(tentacles_for_courses == courses && tentacles_for_course_d == course_d,
           "courses changed: update COURSES in tentacles.py and re-run it");
    union() {
        difference() {
            stone_block();
            for (z = courses) course_cut(z);
            for (g = glyphs) glyph(g[0], g[1], g[2]);
        }
        intersection() {
            tentacles();
            translate([-200, -200, 0]) cube([400, 400, shell_h + 40]);
        }
    }
}

module shell() {
    difference() {
        shell_skin();
        shell_cavity();
        // vents through the seat, under the lip where they can't be seen
        for (i = [0:vents - 1]) rotate(i * 360 / vents + 60)
            translate([r_res - 1, -vent_w / 2, z_seat - 1]) cube([lip_r - r_res + 1, vent_w, shell_h]);
        if (mark) translate([0, 0, 0]) bx_mark_pocket(mark_w, face = "bottom");
    }
}

// --- dipstick --------------------------------------------------------------
// Lies flat; x runs up the stick from the end that stands on the shell floor.
// Notches mark full, half and refill.
module dipstick() {
    full = z_full - shell_floor;
    difference() {
        union() {
            cube([stick_len, stick_w, stick_t]);
            // a tab wider than the bore, so it can't drop out of reach
            translate([stick_len - 6, -(2 * tube_ri + 4 - stick_w) / 2, 0])
                cube([6, 2 * tube_ri + 4, stick_t]);
        }
        for (f = [1, 0.5, 0.15]) translate([full * f, -1, -1])
            rotate(45) cube([mark_d * sqrt(2), mark_d * sqrt(2), stick_t + 2]);
    }
}

// --- outputs ---------------------------------------------------------------
module view_assembly() {
    color("dimgray") shell();
    color("peru") translate([0, 0, dz]) pot();
    color("gold") translate([tube_r, 0, shell_floor]) rotate([0, -90, 0]) translate([0, -stick_w / 2, -stick_t / 2]) dipstick();
}

if (part == "shell") shell();
else if (part == "shell_mark_silver") bx_mark_inlay(mark_w, "B", face = "bottom");
else if (part == "shell_mark_red") bx_mark_inlay(mark_w, "x", face = "bottom");
else if (part == "pot") pot();
else if (part == "dipstick") dipstick();
else if (part == "view_assembly") view_assembly();
else if (part == "view_section") difference() { view_assembly(); translate([-200, -200, -1]) cube([400, 200, 300]); }
