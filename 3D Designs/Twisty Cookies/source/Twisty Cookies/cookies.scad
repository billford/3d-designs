// Twisty Cookies: a palm-sized stack of four sandwich cookies that spin
// independently on a hidden post. A fidget, in the spirit of the Oreo twisty
// fidget, redesigned to print reliably (2026-10-12).
//
// WHY IT IS FOUR FLAT PRINTS AND NOT PRINT-IN-PLACE. The original prints the
// stack standing up: every cookie has to start in mid-air over a one-layer
// gap above the one below, with walls Studio flags as "floating" and a
// colour change at every cream band. On the P1S it failed twice into
// spaghetti. Printed side by side and flat, nothing starts in mid-air, and
// every cookie changes colour at the SAME heights: two colour changes for the
// whole plate, so the prime tower stops at ~5mm and cannot topple.
//
// Assembly, no glue: the bottom cookie carries a post. Drop the two middle
// cookies over it, then press the top cookie on until it clicks. The post's
// top is split into two prongs with a barb, which springs into a hidden
// pocket inside the top cookie. The top three cookies spin freely.
//
// SEPARATE PRINTS: 1 plate, two colours, H2D (one filament per nozzle).
//   wafer - the dark cookies and the post (galaxy)
//   cream - the cream filling (white)
// Load both STLs together as ONE object with two parts.
// view_stack is a picture. Never slice it.
//
// Print orientation: every cookie flat, bottom face on the bed. The top
// cookie's relief faces up. The bottom cookie's post stands straight up.

use <../Makers Mark/mark.scad>

part = "view_stack";    // wafer | cream | view_stack

/* [Cookie] */
cookies = 4;
cookie_d = 30;          // palm size: about 2/3 of the 43mm original
wafer_t = 2.6;          // 13 layers; real sandwich cookies are about 1/3 cream
cream_t = 2.0;
cream_in = 0.5;         // cream sits back from the rim so it reads as filling
edge_c = 0.6;           // chamfer on the wafers' outer edges
ribs = 24;              // scalloped cookie edge
rib_d = 0.5;            // texture, not a shadow line (that would need 2mm)

/* [Top relief] */
relief_h = 0.6;         // 3 layers, on the top cookie only

/* [Post and snap] */
post_d = 7;
spin_fit = 0.3;         // ROTATING fit, looser than the proven 0.22 locating fit
barb = 0.8;             // barb radius beyond the post
slit = 1.4;             // splits the post's top into two prongs
prong_l = 12;           // flexing length of each prong
// Axial play. The barb's underside is a 45-degree cone, so it only meets the
// lip after the stack lifts by play PLUS spin_fit: 0.4 in all. Measured on the
// model by pulling the top cookie up until the barb bit (2026-10-12).
play = 0.1;
lead_in = 30;           // barb's entry taper, degrees from vertical
ceiling = 1.2;          // solid above the snap pocket in the top cookie

/* [Makers mark] */
mark = true;            // engraved under the bottom cookie
mark_w = 18;            // the library's minimum is ~17.1

layer_h = 0.2;
spacing = cookie_d + 6; // plate layout

$fn = 96;

// ---- derived ----
R = cookie_d / 2;
T = 2 * wafer_t + cream_t;              // one cookie
r_s = post_d / 2;
r_h = r_s + spin_fit;                   // the hole the post spins in
cav_r = r_s + barb + spin_fit;          // snap pocket in the top cookie
barb_h = barb + 0.4 + (barb + 0.5) / tan(lead_in);   // 45 underside, flat, lead-in
cav_h = ceil((play + barb_h + spin_fit) / layer_h) * layer_h;   // whole layers
step = T - ceiling - cav_h;             // the lip the barb hooks over, from the top cookie's base
post_top = (cookies - 1) * T + step + play + barb_h;   // above the bed, bottom cookie
prong_t = r_s - slit / 2;               // prong thickness in its bending direction
flex = barb - spin_fit;                 // how far each prong bends to pass a hole

overhang_limit = atan(0.42 / (2 * layer_h));
// a cantilever snap: strain = 1.5 t y / L^2. PLA takes ~2% repeatedly.
snap_strain = 1.5 * prong_t * flex / (prong_l * prong_l);
assert(snap_strain <= 0.02, str("prong strain ", snap_strain * 100, "%: over 2% PLA will crack. Lengthen prong_l"));
assert(flex <= slit / 2, "the prongs can't bend far enough: the slit closes first");
assert(flex >= 0.4, "the barb barely overlaps the hole: it would pull out");
assert(step >= 1.2, str("top cookie's lip is ", step, "mm: too thin to hold the barb"));
assert(prong_l <= post_top - T - 1, "prongs reach down into the bottom cookie");
assert(prong_t >= 1.2 && slit >= 1.2, "prong or slit under the 1.2mm minimum");
for (h = [wafer_t, cream_t, T, step]) assert(abs(h / layer_h - round(h / layer_h)) < 1e-6,
    str(h, "mm is not a whole number of ", layer_h, "mm layers: the colour bands would blur"));
assert(cream_in <= edge_c + 0.21 && cream_in >= rib_d,
    "the wafer above the cream must step out at 45 degrees from the cream's edge");
assert(norm([mark_w / 2, bx_mark_h(mark_w) / 2]) <= R - edge_c - 1.2, "mark runs into the bottom cookie's chamfer");

// ---- a cookie ----

// a wafer, with chamfers: c_lo at its bottom edge, c_hi at its top edge.
// Built as one polyhedron, ring by ring, with the radius the smaller of the
// scalloped edge and the chamfer. Intersecting a chamfer cone with the
// scalloped prism instead left 2688 non-manifold slivers where the two
// surfaces run nearly tangent.
function rib_r(a) = R - rib_d * (0.5 - 0.5 * cos(ribs * a));
function wafer_r(a, z, c_lo, c_hi) = min(rib_r(a), R - c_lo + z, R - c_hi + (wafer_t - z));
module wafer(c_lo, c_hi) {
    na = ribs * 8;
    zs = concat([for (z = [0 : 0.05 : c_lo]) z], [for (z = [wafer_t - c_hi : 0.05 : wafer_t]) z]);
    pts = concat([for (z = zs) for (i = [0 : na - 1]) let(a = 360 * i / na, r = wafer_r(a, z, c_lo, c_hi))
                     [r * cos(a), r * sin(a), z]],
                 [[0, 0, 0], [0, 0, wafer_t]]);
    nz = len(zs);
    P = function(i, j) i * na + (j % na);
    c = nz * na;
    polyhedron(pts, concat(
        [for (i = [0 : nz - 2]) for (j = [0 : na - 1]) each [
            [P(i, j), P(i + 1, j), P(i + 1, j + 1)], [P(i, j), P(i + 1, j + 1), P(i, j + 1)]]],
        [for (j = [0 : na - 1]) [c, P(0, j), P(0, j + 1)]],
        [for (j = [0 : na - 1]) [c + 1, P(nz - 1, j + 1), P(nz - 1, j)]]), convexity = 4);
}

// The wafer above the cream steps out from the cream's edge at 45 degrees, so
// it never overhangs it; the one below mirrors it to look the same.
module wafers() {
    wafer(edge_c, cream_in);
    translate([0, 0, wafer_t + cream_t]) wafer(cream_in, edge_c);
}
module cream() translate([0, 0, wafer_t]) cylinder(r = R - cream_in, h = cream_t);

// generic sandwich-cookie face: a rim, a ring of dots, a flower. Every line
// and gap is at least 1.2mm.
module relief2d() {
    difference() { circle(r = R - 1.6); circle(r = R - 3.0); }
    for (k = [0 : 15]) rotate(360 * k / 16 + 11.25) translate([R - 5.2, 0]) circle(r = 0.8);
    for (k = [0 : 7]) rotate(45 * k) translate([3.6, 0]) circle(r = 1.6);
    circle(r = 1.2);
}

// k: 0 = bottom (carries the post), cookies-1 = top (snap pocket, relief)
module cookie_wafer(k) {
    top = k == cookies - 1;
    difference() {
        union() {
            wafers();
            // sunk 0.4 into the face: touching at a plane, each dot is a loose solid
            if (top) translate([0, 0, T - 0.4]) linear_extrude(relief_h + 0.4) relief2d();
        }
        if (k > 0) translate([0, 0, -1]) cylinder(r = r_h, h = top ? step + 1.001 : T + 2);
        if (top) translate([0, 0, step]) cylinder(r = cav_r, h = cav_h);
        if (k == 0 && mark) bx_mark_pocket(mark_w, face = "bottom");
    }
}
module cookie_cream(k) difference() {
    cream();
    if (k > 0) translate([0, 0, -1]) cylinder(r = r_h, h = T + 2);
    if (k == cookies - 1) translate([0, 0, step]) cylinder(r = cav_r, h = cav_h);
}

// ---- the post, on the bottom cookie ----

module barb_profile() {
    z0 = 0;
    polygon([[0, z0], [r_s, z0], [r_s + barb, z0 + barb], [r_s + barb, z0 + barb + 0.4],
             [r_s - 0.5, barb_h], [0, barb_h]]);
}
module post() difference() {
    union() {
        // runs down into the cookie by 0.6 so the two are one solid
        translate([0, 0, T - 0.6]) cylinder(r = r_s, h = post_top - barb_h - T + 0.6);
        translate([0, 0, post_top - barb_h]) rotate_extrude() barb_profile();
    }
    translate([-slit / 2, -R, post_top - prong_l]) cube([slit, 2 * R, prong_l + 1]);
}

// Colour is a function of height alone: each cookie's cream band, everywhere
// on the plate, is the same layers. The post above the bottom cookie is wafer.
module part_wafer(k) { cookie_wafer(k); if (k == 0) post(); }

module plate(which) for (k = [0 : cookies - 1])
    translate([(k % 2 - 0.5) * spacing, (floor(k / 2) - 0.5) * spacing, 0])
        if (which == "wafer") part_wafer(k); else cookie_cream(k);

// assembled: cookies resting on each other, the barb in the top pocket
module view_stack() {
    for (k = [0 : cookies - 1]) translate([0, 0, k * T]) {
        color("#424379") cookie_wafer(k);
        color("#F7F3F0") cookie_cream(k);
    }
    color("#424379") post();
}

if (part == "wafer") plate("wafer");
else if (part == "cream") plate("cream");
else if (part == "view_stack") view_stack();
