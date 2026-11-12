// "Happy Thanksgiving" yard sign: a brown board with raised orange lettering,
// a turkey and a border, on two printed ground stakes. 600 x 200mm, PLA (it is
// out for a few weeks, not a season). The board, joins and stakes are the
// Don't Hit My Pumpkins sign's; the art is new.
//
// FIVE prints: three sign pieces and a plate of two stakes. Each piece is one
// plate, lying flat, face up, with two STLs loaded as ONE object with two parts:
//   part = "sign_1_board" .. "sign_3_board"   brown: the board, 10mm
//   part = "sign_1_art"   .. "sign_3_art"     orange: the raised art, 3mm on top
//   part = "sign_3_mark_silver", "sign_3_mark_red"   the BX mark, on piece 3's back
//   part = "stakes"                           two stakes, one plate, one colour
//   part = "view_art", "view_assembly"        pictures; do not slice
// The colours only meet at z = 10, so each plate changes filament ONCE.
//
// The joins between pieces come from split.py, which routes each one between
// the letters (sign_split.scad). Re-run it after changing any art. The pieces
// join on two jigsaw knobs per join. The stakes go in pockets in the bottom
// edges of pieces 1 and 3, a quarter of the way in from each end.

use <fonts/LuckiestGuy-Regular.ttf>
use <../Makers Mark/mark.scad>
include <sign_split.scad>

part = "view_art";

font    = "Luckiest Guy";
line1   = "HAPPY";
line2   = "THANKSGIVING";
cap1    = 54;          // cap heights, mm. THANKSGIVING is ~9.5x its cap wide,
cap2    = 33;          // so it sets the text block's width; HAPPY gets the size
size_k  = 1.0;         // Luckiest Guy's caps stand 1.0 x the size passed to text()
lead    = 14;          // gap between the lines, mm
track   = 1.12;        // letter spacing: at 1.06 the S-G gap the join threads was 1.9mm

board_w = 600;
board_h = 200;
board_r = 14;          // corner radius
border_in = 8;         // border sits this far in from the board edge
border_w  = 5;

tk_w = 170;            // the turkey's box: tail fan to tail fan, fan tip to toes
tk_h = 156;
margin = 24;           // inside the border, to the art
gap    = 18;           // turkey to text

text_x0 = border_in + border_w + margin + tk_w + gap;      // left edge of the text block
text_w  = board_w - text_x0 - border_in - border_w - margin;
text_cx = text_x0 + text_w / 2;

module board_2d() offset(r = board_r) offset(delta = -board_r) square([board_w, board_h]);

module border_2d() difference() {
    offset(delta = -border_in) board_2d();
    offset(delta = -border_in - border_w) board_2d();
}

// both lines centred in the text block
module words_2d() {
    y0 = (board_h - (cap1 + lead + cap2)) / 2;
    translate([text_cx, y0 + cap2 + lead]) text(line1, size = cap1 / size_k, font = font, halign = "center", spacing = track);
    translate([text_cx, y0]) text(line2, size = cap2 / size_k, font = font, halign = "center", spacing = track);
}

// ---- turkey -------------------------------------------------------------------
// Front on, tail fanned. One colour: the details are grooves and holes, so the
// brown board shows through them. Origin at the middle of the body.
groove = 2.0;          // relief lines: >= 1.2 to print, 2 to read (DESIGN-RULES 4)

feathers = 7;
fan_c    = [0, 12];    // the tail fans out from here, behind the body
fan_a0   = 18;         // the lowest feathers' angle above horizontal
fth_r    = 42;         // fan centre to a feather's centre
fth_a    = 38;         // feather half-length and half-width
fth_b    = 15.5;
band_r   = 58;         // the band across the tail, at this radius from fan_c

body_c = [0, -6];
body_a = 38;           // half-width, half-height
body_b = 44;
head_c = [0, 44];
head_r = 19;

module ellipse(c, a, b, ang = 0) translate(c) rotate(ang) scale([a, b]) circle(1, $fn = 96);

function fth_ang(i) = fan_a0 + i * (180 - 2 * fan_a0) / (feathers - 1);
module feather(i) let(t = fth_ang(i))
    ellipse(fan_c + fth_r * [cos(t), sin(t)], fth_a, fth_b, t);

module bird_2d() union() {             // body and head, one silhouette
    ellipse(body_c, body_a, body_b);
    translate(head_c) circle(head_r, $fn = 96);
}

module tail_2d() difference() {
    union() for (i = [0:feathers - 1]) feather(i);
    // a groove down between each pair of feathers, and a band across them all
    for (i = [0:feathers - 2]) let(t = (fth_ang(i) + fth_ang(i + 1)) / 2)
        translate(fan_c) rotate(t) translate([0, -groove / 2]) square([2 * tk_w, groove]);
    translate(fan_c) difference() { circle(band_r + groove / 2, $fn = 160); circle(band_r - groove / 2, $fn = 160); }
    offset(delta = groove) bird_2d();   // and a groove round the body
}

beak    = [[-6, 45], [6, 45], [0, 33]];

module face_2d() {
    for (s = [-1, 1]) translate(head_c + [s * 7.5, 9]) circle(3.4, $fn = 48);   // eyes
    polygon(beak);
}

// the wings: a curve down each side of the body, inside it
module wings_2d() intersection() {
    offset(delta = -5) ellipse(body_c, body_a, body_b);
    for (s = [-1, 1]) difference() {
        ellipse(body_c + [s * 25, -8], 14, 30, s * 12);
        ellipse(body_c + [s * 25, -8], 14 - groove, 30 - groove, s * 12);
    }
}

// chest feathers: rows of little scallops between the wings
module chest_2d() intersection() {
    ellipse(body_c + [0, -4], 10, 24);
    for (row = [0:2], k = (row % 2 ? [-0.5, 0.5] : [-1, 0, 1]))
        translate(body_c + [k * 8, 8 - row * 10]) difference() {
            circle(5, $fn = 48);
            circle(5 - groove, $fn = 48);
            translate([-6, 0]) square([12, 6]);
        }
}

// legs and three-toed feet, under the body
toe = 3.6;
module feet_2d() for (s = [-1, 1]) let(x = s * 14, top = body_c[1] - body_b + 4, y = top - 8) {
    hull() { translate([x, top]) circle(toe / 2, $fn = 24); translate([x, y]) circle(toe / 2, $fn = 24); }
    for (d = [[-8, -5], [0, -7], [8, -5]])
        hull() { translate([x, y]) circle(toe / 2, $fn = 24); translate([x + d[0], y + d[1]]) circle(toe / 2, $fn = 24); }
}

module turkey_2d() {
    tail_2d();
    difference() {
        bird_2d();
        // the head's outline where it sits on the body, out through the silhouette
        intersection() {
            translate(head_c) difference() { circle(head_r + groove, $fn = 96); circle(head_r, $fn = 96); }
            offset(delta = 1) ellipse(body_c, body_a, body_b);
        }
        face_2d();
        // the wattle, hanging beside the beak: 1.5mm of head left between them
        hull() { translate(head_c + [5, -9]) circle(2, $fn = 32); translate(head_c + [6, -19]) circle(3.3, $fn = 40); }
        wings_2d();
        chest_2d();
    }
    feet_2d();
}

// the turkey's extent, from the shapes above: centre its box on the board
tk_top = fan_c[1] + fth_r + fth_a;
tk_bot = body_c[1] - body_b + 4 - 8 - 7 - toe / 2;
assert(tk_top - tk_bot <= tk_h, str("turkey is ", tk_top - tk_bot, "mm tall, box is ", tk_h));

// the lettering and the turkey: the joins between pieces must miss these
module pictures_2d() {
    words_2d();
    translate([border_in + border_w + margin + tk_w / 2, board_h / 2 - (tk_top + tk_bot) / 2])
        turkey_2d();
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
    color("#7c4b00") linear_extrude(board_t) board_2d();
    color("#ffb673") translate([0, 0, board_t - 0.01]) linear_extrude(relief) art_2d();
}
else if (part == "view_assembly") {     // the pieces in place, a little apart, on their stakes
    for (i = [0:split_n - 1]) translate([i * 4, 0, 0]) {
        color("#7c4b00") board_3d(i);
        color("#ffb673") art_3d(i);
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
