// "Don't Hit My Pumpkins" yard sign: a black board with raised orange
// lettering, a jack-o'-lantern and a border, on two printed ground stakes.
// 600 x 200mm, PLA (it is out for two weeks, not a season).
//
// FIVE prints: three sign pieces and a plate of two stakes (four with the
// stakes on the same printer twice). Each piece is one plate, lying flat, face
// up, with two STLs loaded as ONE object with two parts:
//   part = "sign_1_board" .. "sign_3_board"   black: the board, 10mm
//   part = "sign_1_art"   .. "sign_3_art"     orange: the raised art, 3mm on top
//   part = "sign_3_mark_silver", "sign_3_mark_red"   the BX mark, on piece 3's back
//   part = "stakes"                           two stakes, one plate, one colour
//   part = "view_art", "view_assembly"        pictures; do not slice
// The colours only meet at z = 10, so each plate changes filament ONCE.
//
// The joins between pieces come from split.py, which routes each one between
// the letters (sign_split.scad). Re-run it after changing any art. The pieces
// glue together on two jigsaw knobs per join. The stakes go in pockets in the
// bottom edges of pieces 1 and 3, a quarter of the way in from each end.

use <fonts/Creepster-Regular.ttf>
use <../Makers Mark/mark.scad>
include <sign_split.scad>

part = "view_art";

font    = "Creepster";
line1   = "DON'T HIT";
line2   = "MY PUMPKINS";
cap     = 52;          // cap height, mm; MY PUMPKINS is ~7x this wide
size_k  = 1.03;        // Creepster's caps stand 1.03 x the size passed to text()
lead    = 0.36;        // gap between the lines, as a fraction of cap
track   = 1.04;        // letter spacing: at 1.0 HIT's I and T are 1.1mm apart and would merge

board_w = 600;
board_h = 200;
board_r = 14;          // corner radius
border_in = 8;         // border sits this far in from the board edge
border_w  = 5;

pk_w = 170;            // pumpkin, stem included in pk_h
pk_h = 150;
margin = 24;           // inside the border, to the art
gap    = 18;           // pumpkin to text

text_x0 = border_in + border_w + margin + pk_w + gap;      // left edge of the text block
text_w  = board_w - text_x0 - border_in - border_w - margin;

module board_2d() offset(r = board_r) offset(delta = -board_r) square([board_w, board_h]);

module border_2d() difference() {
    offset(delta = -border_in) board_2d();
    offset(delta = -border_in - border_w) board_2d();
}

// both lines centred in the text block
module words_2d() {
    cx = text_x0 + text_w / 2;
    blk = 2 * cap + lead * cap;
    y0 = (board_h - blk) / 2;
    translate([cx, y0 + cap + lead * cap]) text(line1, size = cap / size_k, font = font, halign = "center", spacing = track);
    translate([cx, y0]) text(line2, size = cap / size_k, font = font, halign = "center", spacing = track);
}

// ---- jack-o'-lantern ----------------------------------------------------------
groove = 1.8;          // lobe lines: relief, so >= 1.2 (DESIGN-RULES 4)

module ell(cx, w, h) translate([cx, 0]) scale([w / 2, h / 2]) circle(1, $fn = 96);

body_h = pk_h * 0.82;
lobes = [   // [centre x, width, height] as fractions of pk_w / body_h
    [ 0.00, 0.46, 1.00],
    [-0.17, 0.46, 0.96], [0.17, 0.46, 0.96],
    [-0.29, 0.42, 0.86], [0.29, 0.42, 0.86],
];
module lobe(i) ell(lobes[i][0] * pk_w, lobes[i][1] * pk_w, lobes[i][2] * body_h);
module ring(i) difference() { lobe(i); offset(delta = -groove) lobe(i); }

module pumpkin_body() union() for (i = [0:4]) lobe(i);

// the face's holes, one module per hole
module face_part(i) {
    if (i < 2) let(s = i == 0 ? -1 : 1)     // eyes: triangles, outer corners lifted
        polygon([[s * 0.07, 0.08], [s * 0.27, 0.05], [s * 0.18, 0.27]] * pk_w);
    else if (i == 2) polygon([[-0.045, -0.02], [0.045, -0.02], [0, 0.07]] * pk_w);   // nose
    else difference() {   // crescent grin between two arcs; one tooth down, two up
        intersection() {
            translate([0, 0.02 * pk_w]) circle(0.33 * pk_w, $fn = 120);
            translate([-pk_w, -pk_w]) square([2 * pk_w, 0.93 * pk_w]);
        }
        translate([0, 0.20 * pk_w]) circle(0.40 * pk_w, $fn = 120);
        translate([-0.025 * pk_w, -0.24 * pk_w]) square([0.05 * pk_w, 0.06 * pk_w]);
        for (s = [-1, 1]) translate([s * 0.13 * pk_w - 0.025 * pk_w, -0.30 * pk_w])
            square([0.05 * pk_w, 0.075 * pk_w]);
    }
}
module face_2d() for (i = [0:3]) face_part(i);

module stem_2d() polygon([[-0.05, 0.36], [0.05, 0.36], [0.07, 0.47], [0.10, 0.52],
                          [0.04, 0.52], [-0.02, 0.47]] * pk_w);

module pumpkin_2d() {
    difference() {
        pumpkin_body();
        difference() {
            // lobe lines: each lobe's outline where it lies over the lobe outside
            // it. Taken 1mm past that lobe, so each line runs out through the
            // silhouette: ending exactly on it left the board's art pinched to
            // a vertical edge (8 non-manifold edges, 2026-10-19)
            union() {
                intersection() { union() { ring(1); ring(2); } offset(delta = 1) union() { lobe(3); lobe(4); } }
                intersection() { ring(0); offset(delta = 1) union() { lobe(1); lobe(2); } }
            }
            // and they stop short of the face, so no sliver is left between the two
            offset(delta = 4) hull() face_2d();
        }
        face_2d();
    }
    difference() { stem_2d(); offset(delta = groove) pumpkin_body(); }
}

// the lettering and the jack-o'-lantern: the joins between pieces must miss these
module pictures_2d() {
    words_2d();
    translate([border_in + border_w + margin + pk_w / 2, board_h / 2 - pk_h * 0.06])
        intersection() { pumpkin_2d(); translate([-pk_w, -body_h / 2]) square([2 * pk_w, 2 * pk_h]); }
}

module art_2d() { border_2d(); pictures_2d(); }

// ---- the pieces ---------------------------------------------------------------
layer_h = 0.2;
board_t = 10;          // thick enough to carry the stake pocket with 2mm skins
relief  = 3;           // raised art: 15 layers, a shadow at any light angle
clear   = 0.22;        // proven per side (CLAUDE.md), every fit here

// stake: a tongue into a pocket in the board's bottom edge, then a shank and a
// spike. The tongue is 5.56 thick: in a 30mph wind it bends at ~12 MPa, a
// quarter of PLA's strength (wind on 0.12 m2 shared by two stakes)
tongue_w = 19.56;
tongue_t = 5.56;
tongue_l = 68;
pocket_w = tongue_w + 2 * clear;
pocket_t = tongue_t + 2 * clear;
pocket_d = tongue_l + 2;          // 2mm of room at the top, for grit
pocket_z = 2;                     // floor skin; the ceiling skin is the rest
assert(board_t - pocket_z - pocket_t >= 1.2 + 0.8,
       str("skin over the stake pocket only ", board_t - pocket_z - pocket_t, "mm"));
// the pocket's ceiling is a bridge pocket_w long, open at one end: anchored
// on both long sides, so it bridges (DESIGN-NOTES: anchored overhangs)

mark_w = 20;
mark_at = [560, 32];              // on the back of piece 3, clear of its pocket

function piece_x0(i) = min([for (p = split_piece(i)) p[0]]);

module piece_2d(i) intersection() { board_2d(); polygon(split_piece(i)); }

// (the check is in here, not at the top level, so split.py can read the art
// out of this file before sign_split.scad exists)
module board_3d(i) assert(min([for (x = split_pockets) abs(mark_at[0] - x)]) > pocket_w / 2 + mark_w / 2 + 5,
                          "mark hits a pocket") difference() {
    linear_extrude(board_t) piece_2d(i);
    for (x = split_pockets) translate([x - pocket_w / 2, -1, pocket_z]) cube([pocket_w, pocket_d + 1, pocket_t]);
    if (i == 2) translate([mark_at[0], mark_at[1], 0]) bx_mark_pocket(mark_w, face = "bottom");
}

// the art sits ON the board (z = 10 to 13): as two parts of one object the
// slicer prints them as one, so they need not overlap (Halloween Bookmarks)
module art_3d(i) translate([0, 0, board_t]) linear_extrude(relief) intersection() { art_2d(); piece_2d(i); }

// each piece's STLs share one frame, with the piece moved to x = 0
module at_origin(i) translate([-piece_x0(i), 0, 0]) children();

// ---- stakes ---------------------------------------------------------------------
shank_w = 24;          // wider than the pocket: the sign sits on its shoulders
shank_t = 12;
shank_l = 50;          // shoulder to grass: the sign's bottom edge stands this high
spike_l = 110;         // in the ground, the last 50 tapering to a point
taper_l = 50;
stake_l = tongue_l + shank_l + spike_l;
assert(stake_l <= 230, str("stake ", stake_l, "mm: too long for the P1S"));

// printed flat. The tongue and the shank share the bed face; push the tongue in
// with that flat face toward the FRONT of the sign, so the shank stands behind it
module stake() {
    // tongue, with its corners cut so it finds the pocket
    // (it starts 2mm inside the shank, so the two overlap rather than touch)
    linear_extrude(tongue_t) polygon([[-tongue_w / 2, -2], [tongue_w / 2, -2], [tongue_w / 2, tongue_l - 3],
                                      [tongue_w / 2 - 3, tongue_l], [-tongue_w / 2 + 3, tongue_l],
                                      [-tongue_w / 2, tongue_l - 3]]);
    // shank and spike: the spike narrows to a point in plan, and its top slopes
    // down to 4mm, a ramp that prints as a plain top surface
    hull() {
        translate([-shank_w / 2, -(shank_l + spike_l - taper_l), 0]) cube([shank_w, shank_l + spike_l - taper_l, shank_t]);
        translate([-1.5, -(shank_l + spike_l), 0]) cube([3, 1, 4]);
    }
}

module stakes() for (s = [-1, 1]) translate([s * (shank_w / 2 + 6), 0, 0]) rotate(s > 0 ? 180 : 0)
    translate([0, -(tongue_l - shank_l - spike_l) / 2, 0]) stake();

// ---- output ---------------------------------------------------------------------
if (part == "lib") ;                          // include<> this file for its modules only
else if (part == "pictures_2d") pictures_2d();   // read by split.py
else if (part == "border_2d") border_2d();
else if (part == "view_art") {
    color("#1a1a1a") linear_extrude(board_t) board_2d();
    color("#ff7a00") translate([0, 0, board_t - 0.01]) linear_extrude(relief) art_2d();
}
else if (part == "view_assembly") {     // the pieces in place, a little apart, on their stakes
    for (i = [0:split_n - 1]) translate([i * 4, 0, 0]) {
        color("#1a1a1a") board_3d(i);
        color("#ff7a00") art_3d(i);
    }
    for (x0 = split_pockets) let(x = x0 + 4 * len([for (i = [1:split_n - 1]) if (piece_x0(i) < x0) i]))
        color("#333") translate([x, 0, pocket_z + pocket_t - clear]) mirror([0, 0, 1]) stake();
}
else if (part == "stakes") stakes();
else if (part == "sign_3_mark_silver") at_origin(2) translate([mark_at[0], mark_at[1], 0]) bx_mark_inlay(mark_w, "B", face = "bottom");
else if (part == "sign_3_mark_red")    at_origin(2) translate([mark_at[0], mark_at[1], 0]) bx_mark_inlay(mark_w, "x", face = "bottom");
// one piece in one STL, both colours: for a filament change at z = 10 instead
// of two parts, and what the checks slice
else if (part == "sign_1") at_origin(0) { board_3d(0); art_3d(0); }
else if (part == "sign_2") at_origin(1) { board_3d(1); art_3d(1); }
else if (part == "sign_3") at_origin(2) { board_3d(2); art_3d(2); }
else if (part == "sign_1_board") at_origin(0) board_3d(0);
else if (part == "sign_1_art")   at_origin(0) art_3d(0);
else if (part == "sign_2_board") at_origin(1) board_3d(1);
else if (part == "sign_2_art")   at_origin(1) art_3d(1);
else if (part == "sign_3_board") at_origin(2) board_3d(2);
else if (part == "sign_3_art")   at_origin(2) art_3d(2);
else assert(false, str("unknown part ", part));
