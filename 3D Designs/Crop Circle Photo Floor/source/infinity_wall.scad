// Grass infinity wall - a tiled cyclorama for the lens saucer to hover over,
// with a half-formed crop circle pressed into it.
//
// THIS IS A TILED SET, NOT ONE OBJECT. At 300mm wide it is:
//   3x floor_tile   100 x 200 x 8      flat, trivial, huge first layer
//   3x cove_tile    100 x  70 x 130    the curve, solid, hollowed from below
//   1x seam_gauge   print FIRST - tests the tongue-and-groove fit
//
//   openscad --render -D 'part="seam_gauge"' -o gw_seam_gauge.stl infinity_wall.scad
//   openscad --render -D 'part="floor_tile"' -D tile=0 -o gw_floor_0.raw.stl infinity_wall.scad
//
// The floor tiles come out SMOOTH. The supplied gw_floor_N.stl also carry a
// grass texture over the standing crop, added afterwards in Blender by grass.py.
//
// view_assembly is a PICTURE.
//
// WHY TWO ROWS AND NOT ONE CURVE
//
// The saucer is 138mm across, so the floor has to be about 200mm deep for it
// to sit on with any foreground. 200 + a 70mm cove is 270mm, past the P1S's
// ~230mm practical bed - the corner exclusion zones refused a 240mm frame
// before. Splitting at the TANGENT costs one seam and buys the whole set:
// there is no visual feature at the tangent, the grass texture crosses it, and
// each row then prints in its own best orientation.
//
// WHY THE COVE IS SOLID AND NOT A SHELL
//
// The cove's underside sweeps from 0 to 90 degrees. A constant-thickness sheet
// would be a 90-degree overhang at the tangent - unprintable, and not the
// bridging kind: nothing is anchored on the far side. As a solid wedge sitting
// flat on the plate the same surface is the TOP, which costs nothing. It is
// then hollowed from beneath, where the cavity ceiling IS anchored both sides
// and bridges: a ceiling held at both ends prints, a cantilever does not.
//
// SHOT FROM ABOVE, WHICH CHANGES TWO THINGS.
//
// The cove row does nothing. An infinity curve exists to hide the horizon when
// the camera is low; from overhead the frame is floor and the wall is never
// seen. It is also 59% of the material and the three tallest parts, so the
// floor row alone is the print. cove_tile stays here for a low-angle shot.
//
// AND DEPTH ALONE WILL NOT READ. The reference is an aerial photograph and the
// formation shows up there by TONE - pale laid crop against golden standing
// crop - not by shadow. Straight down under soft light, a 2.5mm step casts
// almost none. So the contrast has to be COLOUR:
//
//     CHANGE FILAMENT AT Z = plate_t - crop_depth = 5.6mm
//
// Below it is laid crop, above it is standing crop. ONE swap at one layer,
// not the 16 that turned an 8g part into 20g - that warning is about colour
// changes per layer, and this is a single purge. Free on the H2D's two nozzles.
//
// THE FORMATION, from the reference: a hexagonal rosette. Six large
// overlapping circles around a small spoked hub, each carrying an angular
// meander glyph, with tractor tramlines crossing the field. Half-formed, so
// the glyphs stop partway round and the last circle is an empty outline.

part = "seam_gauge";  // seam_gauge | floor_tile | cove_tile | view_assembly
tile = 0;             // WHICH tile: 0..n_tiles-1. The formation spans the
                      // whole set, so a tile has to know where it sits or the
                      // pattern lands on all three in the same place.

layer_h = 0.2;
$fn     = 128;

// -------------------------------------------------------------- the subject
saucer_d  = 138;            // the saucer this set was built for, across its rim
saucer_h  = 40;

// ----------------------------------------------------------------- the set
set_w     = 300;            // total width, across all tiles
n_tiles   = 3;
tile_w    = set_w / n_tiles;

floor_d   = 200;            // deep enough for the saucer plus foreground
cove_r    = 70;             // blend radius: the "infinity" part
wall_h    = 60;             // vertical wall above the cove

plate_t   = 8;              // floor tile thickness
shell_t   = 6;              // cove tile skin over its cavity
rib_every = 40;             // ribs break the cavity ceiling into short bridges

// ------------------------------------------------------------- the seams
// Tongue and groove on the VERTICAL side faces. Vertical in both tiles' print
// orientations, so neither is an overhang. Loose on purpose - this is a set
// that gets assembled and pulled apart on a shoot, not a press fit.
tongue_w  = 4;
tongue_d  = 3;
seam_clr  = 0.35;

// ------------------------------------------------------------- assertions
assert(max(tile_w, floor_d) < 230,
       str("tile is ", max(tile_w, floor_d),
           "mm - the P1S practical bed is ~230, not the nominal 256"));
assert(cove_r + wall_h < 250, "cove tile is taller than the Z travel");
assert(floor_d > saucer_d + 40,
       str("floor is ", floor_d, "mm for a ", saucer_d,
           "mm saucer - no foreground left"));
assert(tongue_w >= 1.2 && tongue_d >= 1.2, "seam feature under the 1.2mm floor");
assert(shell_t >= 2.4, "cove skin thinner than 6 perimeters");

echo(str("FILAMENT CHANGE AT Z = ", plate_t - crop_depth,
         "mm - below is laid crop, above is standing crop"));
echo(str("set: ", n_tiles, " x ", tile_w, "mm wide, floor ", floor_d,
         "mm deep, cove r", cove_r, ", wall ", wall_h,
         " -> total depth ", floor_d + cove_r, ", height ", cove_r + wall_h));

// ==========================================================================

// The cove cross-section, as a closed r-z polygon sitting on the plate.
// Quarter arc from the tangent up to vertical, then the wall.
function cove_pts() = concat(
    [[0, 0]],
    [for (i = [0 : 48])
        let (a = 90 * i / 48)
            [cove_r * sin(a), cove_r * (1 - cos(a))]],
    [[cove_r, cove_r + wall_h],
     [cove_r + shell_t, cove_r + wall_h],
     [cove_r + shell_t, 0]]
);

module cove_solid() {
    rotate([90, 0, 0]) translate([0, 0, -tile_w])
        linear_extrude(tile_w) polygon(cove_pts());
}

// The cavity, offset in from the cove surface. Its ceiling is anchored on both
// sides, so it bridges - unlike the outside of the same curve, which is not.
module cove_cavity() {
    inner = concat(
        [[0, shell_t]],
        [for (i = [0 : 48])
            let (a = 90 * i / 48)
                [max(0, cove_r * sin(a) - shell_t),
                 cove_r * (1 - cos(a)) + shell_t]],
        [[cove_r - shell_t, cove_r + wall_h + 1],
         [0, cove_r + wall_h + 1]]
    );
    rotate([90, 0, 0]) translate([0, 0, -(tile_w - 2 * shell_t)])
        linear_extrude(tile_w - 2 * shell_t) polygon(inner);
}

module ribs() {
    n = floor(tile_w / rib_every);
    for (i = [1 : max(1, n)])
        translate([-1, i * tile_w / (n + 1) - 1.2, -1])
            cube([cove_r + shell_t + 2, 2.4, cove_r + wall_h + 2]);
}

// ------------------------------------------------------------- the seams
// A HALF LAP, not a butt joint with a spike on it.
//
// The first version put the groove at y = -3.35..0, which is OUTSIDE a tile
// whose body starts at y=0 - so it cut nothing, every tile grew a tongue with
// no socket to go in, and at 100mm pitch each tongue collided with the next
// tile's body. The set could not be assembled at all. Invisible in a white
// render and obvious the moment the tiles were drawn in position.
//
// So: the tongue is the BOTTOM HALF of the far edge, and the near edge has its
// bottom half removed to receive the neighbour's. They lap, the top faces stay
// coplanar, and the seam falls where the grass texture crosses it.
module tongue(h) {
    translate([-1, tile_w, 0])
        cube([floor_d + cove_r + 2, tongue_d, h / 2]);
}
module groove(h) {
    translate([-1, -1, -1])
        cube([floor_d + cove_r + 2, tongue_d + seam_clr + 1, h / 2 + 1]);
}

// -------------------------------------------------------------- floor tile
// Prints flat. First layer is the whole tile - the best available, and a big
// flat one, so brim 5mm with brim-object gap 0.
// NUMBER THE TILES ON THE UNDERSIDE.
//
// The half lap keys ORIENTATION - a tile physically cannot go in backwards -
// but it does not key SEQUENCE. Nothing stops 0, 2, 1, and the formation would
// simply be wrong with no obvious culprit. Recessed into the bottom face,
// where it is never in shot and costs nothing.
module tile_number(idx) {
    translate([28, tile_w / 2, -1])
        linear_extrude(2.6)
            text(str(idx), size = 26, halign = "center", valign = "center",
                 font = "DejaVu Sans:style=Bold");
}

module floor_tile(idx = 0) {
    difference() {
        union() {
            cube([floor_d, tile_w, plate_t]);
            intersection() {
                tongue(plate_t);
                cube([floor_d, tile_w + tongue_d, plate_t]);
            }
        }
        groove(plate_t);
        translate([0, -idx * tile_w, 0]) crop_circle();
        tile_number(idx);
    }
}

// --------------------------------------------------------------- cove tile
// Prints with its flat underside on the plate, so the curve is the TOP.
module cove_tile() {
    difference() {
        union() {
            cove_solid();
            intersection() {
                tongue(cove_r + wall_h);
                translate([0, 0, 0])
                    cube([cove_r + shell_t, tile_w + tongue_d, cove_r + wall_h]);
            }
        }
        difference() { cove_cavity(); ribs(); }
        groove(cove_r + wall_h);
    }
}

// -------------------------------------------------------------- seam gauge
// Print this FIRST. Two stubs, one of each half, so the tongue-and-groove
// clearance is proved for ten minutes of plate time instead of after three
// hours of tiles.
module seam_gauge() {
    d = 30;
    difference() {
        cube([d, tile_w / 4, plate_t]);
        translate([0, -tongue_d - seam_clr, -1])
            cube([d + 1, tongue_d + seam_clr, plate_t + 2]);
    }
    translate([0, tile_w / 4 + 8, 0]) {
        cube([d, tile_w / 4, plate_t]);
        translate([0, tile_w / 4, 0]) cube([d, tongue_d, plate_t]);
    }
    // Snap-off bridges. Two separate stubs lint as separate bodies and print
    // as two objects; joined, it is one print you break apart to test.
    for (x = [4, d - 6])
        translate([x, tile_w / 4, 0]) cube([2, 8, 1.2]);
}

// ------------------------------------------------------- THE CROP CIRCLE
// A hexagonal rosette, from the reference photograph.
//
// RECESSED, not raised: a crop circle is flattened crop, and recesses survive
// at this scale where protrusions curl off. 2.5mm deep because under 1.5mm
// vanishes into the layer lines and 2mm+ reads as shadow.
//
// HALF-FORMED. `formed` sweeps round the six circles: complete ones with their
// glyphs, then a bare outline where the pattern is still being pressed, then
// nothing. The saucer is doing this now, and the eye reads the gap as motion.
// 2.4, not 2.5, so the recess floor lands on a LAYER BOUNDARY: 8 - 2.4 = 5.6
// = exactly 28 layers at 0.2mm. The colour change has to happen at that floor
// or the two tones will not line up with the geometry, and a swap the slicer
// rounds to the nearest layer would leave a stripe of the wrong green.
crop_depth = 2.4;

// CENTRED ON WHAT IS ACTUALLY DRAWN, not on the notional rosette centre.
// Only 3.5 of the 6 circles exist, so the rosette's geometric middle is not
// where the ink is: the drawn parts span local x -64.5..95, whose centre is
// +15.25. Placing the formation at the floor's centre therefore pushed it
// visibly low and right. Offsetting by that centroid squares it up, and still
// leaves ~20mm of field on both sides.
form_x     = floor_d * 0.5 - 15.25;
form_y     = set_w / 2;
ring_r     = 34;               // one of the six circles
ring_c     = 61;               // its centre, out from the middle
hub_r      = 13;
formed     = 0.62;             // 0..1 round the rosette
sweep      = 0.55;             // how far the in-progress circle has got
// The formed circles run from angle 0 upward, so without this the whole
// rosette crowds into one half of the set and the first tile gets nothing but
// a tramline. Rotating by half the formed arc straddles it across the middle.
form_rot   = -60;

glyph_w    = 46;
glyph_h    = 32;
glyph_st   = 3.5;              // stroke
glyph_gap  = 3.5;              // and the GAP obeys the same 1.2mm floor as the
                               // stroke - features much closer than that merge
                               // in the slicer, and nothing warns about it
tram_w     = 4.5;              // tractor tramlines
tram_pitch = 78;
// SHALLOWER THAN THE FORMATION, and deliberately so. At full depth the
// tramlines break through the filament change and print pure white, which made
// them the loudest thing in the frame - bolder than the formation and bolder
// than they are in any real aerial photograph. At 1.5mm their floor sits at
// 6.5mm, ABOVE the swap at 5.6, so they stay the standing crop's colour and
// read as tracks pressed into the crop instead of laid lanes.
tram_depth = 1.5;

assert(glyph_st >= 1.2 && glyph_gap >= 1.2,
       str("glyph stroke ", glyph_st, " / gap ", glyph_gap,
           " - one of them is under the 1.2mm floor and they will merge"));
assert(crop_depth >= 2.0,
       str(crop_depth, "mm deep - under 2mm it stops reading as shadow"));
// The two-tone swap only works if the recess floor IS a layer boundary.
assert(abs((plate_t - crop_depth) / layer_h
           - round((plate_t - crop_depth) / layer_h)) < 1e-6,
       str("recess floor at ", plate_t - crop_depth, "mm is ",
           (plate_t - crop_depth) / layer_h, " layers at ", layer_h,
           " - not a whole number, so the filament change cannot land on it"));
assert(ring_c + ring_r < floor_d / 2,
       str("formation is ", 2 * (ring_c + ring_r),
           "mm across but the floor is only ", floor_d, "mm deep"));
assert(ring_c < 2 * ring_r,
       "circles do not overlap - the reference rosette has them intersecting");
assert(plate_t - tram_depth > plate_t - crop_depth,
       "tramlines are cut deeper than the formation");
assert(tram_depth >= 1.2, "tramline shallower than the 1.2mm feature floor");

// Nested C-shapes with alternating openings: the angular meander inside each
// circle. Three is as many as fits before the gap drops under the floor.
module glyph_2d() {
    n = floor(min(glyph_w, glyph_h) / (2 * (glyph_st + glyph_gap)));
    for (i = [0 : n - 1]) {
        iw = glyph_w - i * 2 * (glyph_st + glyph_gap);
        ih = glyph_h - i * 2 * (glyph_st + glyph_gap);
        if (iw > 2.5 * glyph_st && ih > 2.5 * glyph_st)
            difference() {
                square([iw, ih], center = true);
                square([iw - 2 * glyph_st, ih - 2 * glyph_st], center = true);
                translate([(i % 2 ? 1 : -1) * iw / 2, 0])
                    square([2 * glyph_st, ih * 0.42], center = true);
            }
    }
}

// The hub: a flattened disc with the spokes left STANDING inside it.
module hub_2d() {
    difference() {
        circle(hub_r);
        for (a = [0 : 45 : 359])
            rotate([0, 0, a]) translate([hub_r / 2, 0])
                square([hub_r, 2.6], center = true);
    }
}

// A pie wedge, for the circle still being swept out.
module wedge_2d(r, deg) {
    n = max(3, ceil(deg / 10));
    polygon(concat([[0, 0]],
        [for (i = [0 : n]) let (a = deg * i / n) [r * cos(a), r * sin(a)]]));
}

// THE CROP IS FLATTENED, THE GLYPH IS LEFT STANDING.
//
// Modelled the other way round first - thin ring grooves - and the shaded
// render caught it before it cost a plate. In the reference the six circles
// are PALE, which is laid crop, and the angular glyph inside each is DARK,
// which is crop still standing. So the disc is the recess and the meander is
// an island in the middle of it. Flat viewport shading would have hidden this
// completely.
module formation_2d() {
    complete = floor(formed * 6);
    rotate([0, 0, form_rot]) {
    hub_2d();
    for (i = [0 : 5]) {
        a = i * 60;
        if (i < complete)
            rotate([0, 0, a]) translate([ring_c, 0])
                difference() {
                    circle(ring_r);
                    rotate([0, 0, -a]) glyph_2d();
                }
        else if (i == complete)
            // Being pressed right now: swept partway round, no glyph yet.
            rotate([0, 0, a]) translate([ring_c, 0])
                rotate([0, 0, 130]) wedge_2d(ring_r, 360 * sweep);
    }
    }
}

module tramlines_2d() {
    for (i = [-2 : 2])
        translate([0, i * tram_pitch])
            rotate([0, 0, 7])            // tractors never drive quite square
                square([floor_d * 3, tram_w], center = true);
}

module crop_circle() {
    // The formation, full depth, through the colour change.
    translate([form_x, form_y, plate_t - crop_depth])
        linear_extrude(crop_depth + 1) formation_2d();
    // The tramlines, shallower, staying above it.
    translate([form_x, form_y, plate_t - tram_depth])
        linear_extrude(tram_depth + 1)
            intersection() {
                tramlines_2d();
                square([floor_d * 3, set_w * 3], center = true);
            }
}

// ------------------------------------------------------------------ views
// The floor row alone, flat. This is the view that judges the FORMATION -
// the oblique assembly shot flattens it into nothing.
module view_floor() {
    for (i = [0 : n_tiles - 1]) translate([0, i * tile_w, 0]) floor_tile(i);
}

module view_assembly() {
    for (i = [0 : n_tiles - 1]) translate([0, i * tile_w, 0]) {
        color("darkseagreen") floor_tile(i);
        translate([floor_d, 0, 0]) color("olivedrab") cove_tile();
    }
    %translate([floor_d * 0.55, set_w / 2, saucer_h / 2])
        scale([1, 1, 0.3]) sphere(d = saucer_d);
}

if      (part == "floor_tile")    floor_tile(tile);
else if (part == "cove_tile")     cove_tile();
else if (part == "seam_gauge")    seam_gauge();
else if (part == "view_floor")    view_floor();
else if (part == "view_assembly") view_assembly();
else assert(false, str("unknown part: ", part));
