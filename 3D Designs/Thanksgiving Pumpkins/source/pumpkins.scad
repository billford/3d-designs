// Two flat harvest pumpkins on tall stakes, to stand behind the Happy
// Thanksgiving sign and show above it. Same look as the sign: brown backing,
// raised orange art, details as grooves. PLA, out for a few weeks.
//
// THREE prints on a P1S, 0.2mm layers, no supports, no brim, prime tower off:
//   pumpkin_1_board + pumpkin_1_art   one object, two parts (brown, orange)
//   pumpkin_2_board + pumpkin_2_art   the same
//   stakes                            four stake pieces, one plate, brown
//   view_art, view_scene              pictures; do not slice
// The colours only meet at z = 10, so a pumpkin changes filament once.
//
// A stake is about 430mm from point to shoulder and the P1S bed is 256mm, so it
// is two pieces: a lower one with a tongue on top, an upper one with a sleeve.
// The join sits low, hidden behind the sign. Every flat (bed) face goes to the
// FRONT when assembled, at the join and in the pumpkin alike.

part = "view_scene";

// ---- what the height comes from: the sign these stand behind ------------------
sign_h     = 200;      // board height
sign_shank = 50;       // the sign's own stakes stand it this far off the ground
sign_top   = sign_shank + sign_h;
over_sign  = 15;       // daylight between the sign's top edge and a pumpkin
shoulder_h = sign_top + over_sign;   // ground to the bottom of a pumpkin

// ---- the board and its art ----------------------------------------------------
board_t = 10;          // as the sign: carries the pocket with 2mm skins
relief  = 3;           // raised art, 15 layers
groove  = 2.0;         // relief lines: >= 1.2 to print, 2 to read (DESIGN-RULES 4)
border  = 7;           // brown showing round the art
foot_w  = 44;          // flat tab on the bottom edge: the stake's shoulders sit on it
foot_d  = 8;           // how far it reaches below the backing

//          [ width, body height ]
pumpkin_1 = [165, 118];       // squat
pumpkin_2 = [140, 132];       // round

function dx(P)     = P[0] * 0.17;
function half_a(P, k) = abs(k) == 2 ? P[0] / 2 - 2 * dx(P) : P[0] * 0.20;
function half_b(P, k) = P[1] / 2 * [1, 0.96, 0.84][abs(k)];

module ellipse(a, b) scale([a, b]) circle(1, $fn = 96);

module lobe(P, k) translate([k * dx(P), 0]) ellipse(half_a(P, k), half_b(P, k));
module body_solid(P) for (k = [-2:2]) lobe(P, k);

// the lines between lobes: the edges of the front lobes, carried across
module lobe_edge(P, k) translate([k * dx(P), 0]) difference() {
    ellipse(half_a(P, k) + groove / 2, half_b(P, k) + groove / 2);
    ellipse(half_a(P, k) - groove / 2, half_b(P, k) - groove / 2);
}
module ribs(P) {
    lobe_edge(P, 0);
    for (s = [-1, 1]) intersection() {
        lobe_edge(P, s);
        translate([s > 0 ? s * dx(P) : s * dx(P) - P[0], -P[1]]) square([P[0], 2 * P[1]]);
    }
}

stem_pts = [[-13, -14], [13, -14], [11, 6], [15, 26], [20, 35], [3, 39], [-3, 34], [-6, 18], [-12, 2]];
module stem_solid(P) translate([0, P[1] / 2]) polygon(stem_pts);
module stem_line(P)  translate([0, P[1] / 2]) hull() {
    translate([2, -6]) circle(groove / 2, $fn = 16);
    translate([8, 31]) circle(groove / 2, $fn = 16);
}

leaf_len = 54;
module leaf_shape() {
    translate([leaf_len * 0.52, 0]) ellipse(leaf_len * 0.48, leaf_len * 0.21);
    for (s = [-1, 1]) rotate(s * 40) translate([leaf_len * 0.32, 0]) ellipse(leaf_len * 0.32, leaf_len * 0.15);
}
module at_leaf(P) translate([-10, P[1] / 2 + 3]) rotate(172) children();
module leaf_rib() translate([6, -groove / 2]) square([leaf_len * 0.8, groove]);

// the tendril: a spiral, stroke 4, turns 7mm apart, so 3mm of brown between
tendril_w = 4;
function tendril_p(P, t) = let(c = [34, P[1] / 2 + 17], r = 17 - (180 - t) * 0.02) c + r * [cos(t), sin(t)];
module tendril(P) {
    pts = concat([[9, P[1] / 2 + 13]], [for (t = [180:-15:-360]) tendril_p(P, t)]);
    for (i = [0:len(pts) - 2]) hull() {
        translate(pts[i]) circle(tendril_w / 2, $fn = 16);
        translate(pts[i + 1]) circle(tendril_w / 2, $fn = 16);
    }
}

module art_2d(P) {
    difference() {
        body_solid(P);
        ribs(P);
        offset(delta = groove) stem_solid(P);
        at_leaf(P) offset(delta = groove) leaf_shape();
    }
    difference() { stem_solid(P); stem_line(P); }
    at_leaf(P) difference() { leaf_shape(); leaf_rib(); }
    tendril(P);
}

function foot_y(P) = -P[1] / 2 - border - foot_d;

// everything solid, grown by the border, with a flat tab for the stake
module backing_2d(P) offset(r = -3) offset(r = 3) union() {
    offset(r = border) union() {
        body_solid(P);
        stem_solid(P);
        at_leaf(P) leaf_shape();
        tendril(P);
    }
    translate([-foot_w / 2, foot_y(P)]) square([foot_w, foot_d + border + 4]);
}

// ---- the join: the sign's tongue and pocket, at the proven clearance ----------
clear    = 0.22;       // per side (DESIGN-RULES 3, measured)
tongue_w = 19.56;
tongue_t = 5.56;
tongue_l = 42;         // the sign's is 68, for a board six times the area; 42 keeps a piece under 230
pocket_w = tongue_w + 2 * clear;
pocket_t = tongue_t + 2 * clear;
pocket_d = tongue_l + 2;          // 2mm of room at the top, for grit
pocket_z = 2;                     // floor skin; the ceiling skin is the rest
assert(board_t - pocket_z - pocket_t >= 2, "skin over the pocket");

module pocket(y0) translate([-pocket_w / 2, y0 - 1, pocket_z]) cube([pocket_w, pocket_d + 1, pocket_t]);

module board_3d(P) difference() {
    linear_extrude(board_t) backing_2d(P);
    pocket(foot_y(P));
}
module art_3d(P) translate([0, 0, board_t]) linear_extrude(relief) art_2d(P);

// ---- stakes ------------------------------------------------------------------
shank_w = 24;
shank_t = 12;
spike_l = 110;         // in the ground, the last 50 tapering to a point
taper_l = 50;
sleeve_w = 34;
sleeve_l = pocket_d + 6;
flare_l  = 5;

// the join height that makes the two pieces the same length
joint_h = (shoulder_h - spike_l) / 2;
lower_l = spike_l + joint_h + tongue_l;
upper_l = shoulder_h - joint_h + tongue_l;
assert(lower_l <= 230 && upper_l <= 230, str("stake pieces ", lower_l, ", ", upper_l, "mm: too long for the P1S"));
assert(joint_h > sign_shank && joint_h + sleeve_l + flare_l < sign_top, "the join must be hidden behind the sign");

module tongue(y0) translate([0, y0]) linear_extrude(tongue_t)
    polygon([[-tongue_w / 2, -2], [tongue_w / 2, -2], [tongue_w / 2, tongue_l - 3],
             [tongue_w / 2 - 3, tongue_l], [-tongue_w / 2 + 3, tongue_l], [-tongue_w / 2, tongue_l - 3]]);

// point at y = 0, tongue on top
module stake_lower() {
    top = spike_l + joint_h;
    hull() {
        translate([-shank_w / 2, taper_l, 0]) cube([shank_w, top - taper_l, shank_t]);
        translate([-1.5, 0, 0]) cube([3, 1, 4]);
    }
    tongue(top);
}

// sleeve at y = 0, tongue on top
module stake_upper() {
    top = shoulder_h - joint_h;
    difference() {
        union() {
            translate([-sleeve_w / 2, 0, 0]) cube([sleeve_w, sleeve_l, shank_t]);
            hull() {
                translate([-sleeve_w / 2, sleeve_l - 1, 0]) cube([sleeve_w, 1, shank_t]);
                translate([-shank_w / 2, sleeve_l + flare_l, 0]) cube([shank_w, 1, shank_t]);
            }
            translate([-shank_w / 2, sleeve_l, 0]) cube([shank_w, top - sleeve_l, shank_t]);
        }
        pocket(0);
    }
    tongue(top);
}

module stakes() {
    pitch = sleeve_w + 6;
    translate([-1.5 * pitch, 0, 0]) stake_lower();
    translate([-0.5 * pitch, 0, 0]) stake_lower();
    translate([ 0.5 * pitch, 0, 0]) stake_upper();
    translate([ 1.5 * pitch, 0, 0]) stake_upper();
}

// ---- output -------------------------------------------------------------------
brown  = "#6b4a24";
orange = "#ff7a2f";

module coloured(P) {
    color(brown) linear_extrude(board_t) backing_2d(P);
    color(orange) translate([0, 0, board_t - 0.01]) linear_extrude(relief) art_2d(P);
}
module stood(P, x) translate([x, shoulder_h - foot_y(P), 0]) coloured(P);

if (part == "view_art") { translate([-100, 0, 0]) coloured(pumpkin_1); translate([100, 0, 0]) coloured(pumpkin_2); }
else if (part == "view_scene") {
    // ground at y = 0: the sign's board, and the pumpkins on their stakes
    color("#7a4a12") translate([0, sign_shank, 0]) cube([600, sign_h, 13]);
    stood(pumpkin_1, 165);
    stood(pumpkin_2, 435);
    for (x = [165, 435]) color(brown) translate([x - shank_w / 2, 0, -14]) cube([shank_w, shoulder_h, 12]);
    color("#3a2a18") translate([-40, -6, -20]) cube([680, 6, 40]);
}
else if (part == "stakes") stakes();
else if (part == "stake_lower") stake_lower();
else if (part == "stake_upper") stake_upper();
else if (part == "pumpkin_1") { board_3d(pumpkin_1); art_3d(pumpkin_1); }
else if (part == "pumpkin_2") { board_3d(pumpkin_2); art_3d(pumpkin_2); }
else if (part == "pumpkin_1_board") board_3d(pumpkin_1);
else if (part == "pumpkin_1_art")   art_3d(pumpkin_1);
else if (part == "pumpkin_2_board") board_3d(pumpkin_2);
else if (part == "pumpkin_2_art")   art_3d(pumpkin_2);
else assert(false, str("unknown part ", part));
