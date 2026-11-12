// Bokeh masks - Halloween shapes cut into a disc that sits in the lens's
// filter thread. Every out-of-focus highlight becomes that shape.
//
// THIS IS ONE MASK PER PRINT, PLUS A GAUGE YOU PRINT FIRST.
//
//   openscad --render -o bk_gauge_67.stl -D 'part="gauge"' -D thread=67 bokeh.scad
//   openscad --render -o bk_ghost_67.stl -D 'part="mask"' -D 'who="ghost"' \
//       -D thread=67 bokeh.scad
//
//
// view_sheet is a PICTURE, not a part.
//
// HOW IT WORKS. The blur disc of an out-of-focus highlight is an image of the
// APERTURE. Put a shaped hole in front of the lens and every highlight takes
// that shape. No glass, no optics - the lens does all of it. Costs light, like
// stopping down, and works best between f/1.4 and f/2.8.
//
// ============================ THE TWO RULES ============================
//
// 1. BACKGROUND BOKEH IS UPSIDE DOWN.
//
// Highlights BEYOND the focal plane render the aperture inverted - a triangle
// cut pointing down photographs pointing up. Highlights in FRONT of it are the
// right way up. Nearly every use of this is lights behind the subject, so
// every asymmetric shape here is rotated 180 degrees in the mask to come out
// upright in the picture. A ghost cut the obvious way photographs on its head.
//
// Set invert = false if you are ever shooting foreground highlights.
//
// 2. THE CUTOUT MUST BE SMALLER THAN THE ENTRANCE PUPIL,
//    which is focal_length / f_number:
//
//      85mm f/1.8   ->  47.2mm     50mm f/1.8  ->  27.8mm
//      70mm f/4     ->  17.5mm     24mm f/4    ->   6.0mm
//
// Bigger than that and the lens's own aperture takes over and the shape simply
// does not appear. This is per-LENS, not per-camera, and it is asserted below.

part   = "gauge";   // gauge | mask | view_sheet
who    = "ghost";   // ghost | frank | alien | robot | pumpkin
                    // bat | cat | hat | moon | saucer
thread = 67;        // 62 | 67 | 77 | 82 - the diameter marked on the lens front

invert   = true;    // rule 1 above
// 16mm is the SAFE DEFAULT, not the best one. It fits inside the pupil of
// every fast prime and every f/2.8 zoom past about 45mm, so a mask cut at 16
// works on most of the bag. Go bigger for a brighter, bolder shape whenever
// the lens has room - on an 85mm f/1.8 you could take this to 30 and still
// have margin. The assert below is what stops you overreaching.
cut_size = 16;      // largest dimension of the cutout, mm

// The lens this mask is FOR. Only used to check cut_size, but that check is
// the difference between a mask that works and a disc that does nothing.
//
// WHICH LENS TO PUT IT ON: the longest, fastest one. Pupil is
// focal_length/f_number, so a zoom is a different lens at each end -
//
//   85mm f/1.8      47.2mm    plenty of room
//   105mm f/2.8     37.5mm    plenty
//   50mm f/1.8      27.8mm    comfortable
//   70-200 f/2.8    71mm at 200, 25mm at 70
//   24-70 f/2.8     25mm at 70, 8.6mm at 24     - long end only
//   24-120 f/4      30mm at 120, 6mm at 24      - long end only
//   14-30 f/4       7.5mm at 30                 - will not work at all
//
// A wide lens at f/4 simply has no room, and no amount of design fixes that.
lens_fl = 85;       // focal length, mm
lens_fn = 1.8;      // widest f-number you will actually shoot at

// ------------------------------------------------------------------ the body
// A SMOOTH PLUG, not a printed thread. A filter thread is M<d>x0.75, so a
// smooth cylinder a few tenths under the nominal diameter slides into the
// female thread and is gripped lightly by the crests - self-centring, and
// nothing to cross-thread into a lens that costs more than the printer.
//
// Centring matters more than it looks: an off-axis cutout skews every
// highlight in the frame, and there is no fixing that afterwards.
// MEASURED on a printed gauge against a real 67mm thread, not computed: 0.4mm
// under nominal was the one of four that slid in snugly. This is a
// PRINTED-DIMENSION number like hotshoe.scad's 18.75mm foot - re-run the gauge
// if the material changes. Filter threads are 0.75mm pitch at every size here,
// so it should carry across 62/67/77/82, but gauge one other size to be sure.
plug_clear = 0.4;
plug_h     = 3.0;
flange_w   = 5.0;   // stops it going in too far, and gives you something to pull
flange_t   = 1.6;
plate_t    = 1.0;   // 5 layers at 0.2 - opaque in black, and thin enough that
                    // the cutout edge does not tunnel and vignette itself
tab_w      = 9;

pupil = lens_fl / lens_fn;
assert(cut_size < pupil,
       str("cutout is ", cut_size, "mm but ", lens_fl, "mm f/", lens_fn,
           " has a ", pupil, "mm entrance pupil - the lens aperture would win ",
           "and the shape would not appear at all"));
assert(plate_t >= 0.8, "plate thinner than 4 layers will not be opaque");
echo(str("mask for ", thread, "mm thread, ", who, ", cutout ", cut_size,
         "mm against a ", pupil, "mm pupil (", round(100*cut_size/pupil), "%)"));

// ------------------------------------------------------------- silhouettes
// Alien and robot are the outlines of the Halloween hot shoe covers' heads, so
// the bokeh matches the prop. The other shapes are drawn for the mask: at
// bokeh size a shape has to read from its outline (or, for the pumpkin, from
// a big carved face), and a smooth dome has no outline worth having.
//
// The two projections are FROZEN here as polygons, so this file builds on its
// own: each is the outline of the hot shoe cover's head seen face-on
// (projection of the head turned rotate([90,0,0]) rotate([0,0,180])).
// Both heads came out of the projection upside down and below the axis, unlike
// every other shape here; mirror() undoes the projection's flip without
// swapping left and right, and the translate centres the outline's box on the
// lens axis first.
module sil_alien() {
    mirror([0, 1]) translate([0.93582, 13.7981])
    polygon([[7.92837, -17.1], [2.59714, -8.42926], [6.32852, -5.3],
             [-6.4, -5.3], [-2.98456, -8.13232], [-9.8, -17.1],
             [-4.9, -22.2962], [3.96418, -22.2962]]);
}

// Head and antenna are two pieces; the hairline gap between them is real.
module sil_robot() {
    mirror([0, 1]) translate([0, 15.9]) {
    polygon([[9, -17.5], [9, -15.5], [9.4, -15.5], [9.4, -10.4568],
             [9, -10.4568], [9, -7.5], [8.2, -6.11436], [-8.2, -6.11436],
             [-9, -7.5], [-9, -10.3], [-9.4, -10.3], [-9.4, -15.3432],
             [-9, -15.3432], [-9, -17.5], [-8.2, -18.8856], [8.2, -18.8856]]);
    polygon([[1.6, -24.3], [0.8, -22.9144], [0.606763, -22.9144],
             [0.606763, -18.9], [-0.75, -18.9], [-0.75, -22.9144],
             [-0.8, -22.9144], [-1.6, -24.3], [-0.8, -25.6856],
             [0.8, -25.6856]]);
    }
}

// The classic sheet ghost: domed head, straight shoulders, scalloped hem. It
// is the hem that says "ghost" - without it this is a tombstone.
module sil_ghost() {
    difference() {
        union() {
            translate([0, 1.4]) circle(r = 3.9, $fn = 56);
            translate([-3.9, -4.2]) square([7.8, 5.7]);
        }
        for (x = [-2.6, 0, 2.6])
            translate([x, -4.3]) circle(r = 1.5, $fn = 32);
    }
}

// Flat top, heavy jaw, and the neck bolts standing out sideways. The bolts are
// what carry it - a flat-topped head alone is just a box.
module sil_frank() {
    polygon([[-3.3, 4.0], [3.3, 4.0], [3.3, -1.2], [2.5, -4.0],
             [-2.5, -4.0], [-3.3, -1.2]]);
    for (sx = [-1, 1])
        translate([sx * 4.0, -0.8]) square([1.9, 1.7], center = true);
}

// A jack-o'-lantern's OUTLINE is a ribbed ellipse with a nub - unreadable at
// bokeh size. Its face is the recognisable thing, and separate holes are fine:
// the blur spot is an image of the whole aperture, however many pieces it is
// in. Each highlight becomes a glowing carved face, which is what a lit
// pumpkin actually looks like at night.
//
// The features are deliberately bold: a bokeh ball is a few dozen pixels, so
// eyes, nose and mouth have to be a large fraction of the aperture or they
// mush together.
module sil_pumpkin() {
    // eyes: big, angled, apex inward and down
    polygon([[-5.6, 5.0], [-1.7, 4.2], [-3.4, 1.0]]);
    polygon([[5.6, 5.0], [1.7, 4.2], [3.4, 1.0]]);
    // nose: the piece that sells it as a face
    polygon([[-1.5, -0.2], [1.5, -0.2], [0, 2.6]]);
    // mouth: wide, curving up at the ends, two bold teeth
    difference() {
        polygon([[-6.4, -1.8], [-4.8, -2.9], [4.8, -2.9], [6.4, -1.8],
                 [4.6, -5.4], [-4.6, -5.4]]);
        polygon([[-2.6, -2.6], [-0.4, -2.6], [-1.5, -4.4]]);
        polygon([[0.4, -2.6], [2.6, -2.6], [1.5, -4.4]]);
    }
}

// Wings up and forward, body narrow. A bat reads at almost any size, which is
// why it is on every Halloween anything.
module sil_bat() {
    polygon([[0, 3.2], [1.1, 1.4], [3.2, 2.6], [4.6, 1.2], [7.4, 2.2],
             [6.2, -0.4], [8.0, -1.6], [4.4, -1.4], [2.0, -3.2], [0.9, -1.0],
             [0, -1.6], [-0.9, -1.0], [-2.0, -3.2], [-4.4, -1.4], [-8.0, -1.6],
             [-6.2, -0.4], [-7.4, 2.2], [-4.6, 1.2], [-3.2, 2.6], [-1.1, 1.4]]);
    // ears, as notches OFF the outline rather than separate pieces
    polygon([[-1.3, 2.4], [-0.5, 4.6], [0.2, 2.6]]);
    polygon([[0.2, 2.6], [0.9, 4.6], [1.7, 2.4]]);
}

// Sitting cat. Big ears and a raised tail: at this size the pose has to be
// carried by two or three bold features, not by the body.
module sil_cat() {
    hull() {
        translate([0, -3.0]) scale([2.9, 2.2]) circle(r = 1, $fn = 40);
        translate([0, 1.6]) scale([2.0, 1.8]) circle(r = 1, $fn = 40);
    }
    polygon([[-2.0, 2.2], [-2.8, 5.6], [-0.3, 3.3]]);    // ears, tall
    polygon([[2.0, 2.2], [2.8, 5.6], [0.3, 3.3]]);
    polygon([[2.4, -4.4], [4.9, -3.4], [5.2, 1.8], [3.7, 1.8],
             [3.5, -2.2], [2.2, -2.8]]);                  // tail, up the side
}

module sil_hat() {
    polygon([[-1.9, 5.4], [1.5, 5.2], [3.0, -0.8], [-3.0, -0.8]]);   // cone
    polygon([[-6.4, -0.8], [6.0, -0.8], [5.0, -2.4], [-5.4, -2.4]]); // brim
}

module sil_moon() {
    difference() {
        circle(r = 5, $fn = 64);
        translate([2.6, 1.1]) circle(r = 4.6, $fn = 64);
    }
}

// The lens saucer's own profile: a shallow lens with a rim and a crown.
module sil_saucer() {
    hull() {
        translate([0, 0.4]) scale([7.6, 1.5]) circle(r = 1, $fn = 48);
        translate([0, -0.8]) scale([4.6, 1.2]) circle(r = 1, $fn = 48);
    }
    translate([0, 1.4]) scale([2.6, 1.7]) circle(r = 1, $fn = 40);   // crown
}

module silhouette(name) {
    if      (name == "ghost")   sil_ghost();
    else if (name == "frank")   sil_frank();
    else if (name == "pumpkin") sil_pumpkin();
    else if (name == "bat")     sil_bat();
    else if (name == "cat")     sil_cat();
    else if (name == "hat")     sil_hat();
    else if (name == "moon")    sil_moon();
    else if (name == "saucer")  sil_saucer();
    else if (name == "alien")   sil_alien();
    else if (name == "robot")   sil_robot();
    else assert(false, str("unknown shape: ", name));
}

// Fitted to cut_size and turned upside down, per rule 1.
module cutout(name) {
    rotate([0, 0, invert ? 180 : 0])
        resize([cut_size, 0], auto = true)
            silhouette(name);
}

// ------------------------------------------------------------------- parts
module mask(name = who) {
    d = thread;
    difference() {
        union() {
            cylinder(h = plug_h, d = d - plug_clear, $fn = 220);
            translate([0, 0, plug_h])
                cylinder(h = flange_t, d = d + flange_w, $fn = 220);
            // pull tab, so it comes back out of a metal thread
            translate([0, 0, plug_h])
                hull() {
                    cylinder(h = flange_t, d = d + flange_w, $fn = 220);
                    translate([(d + flange_w) / 2 + 5, 0, 0])
                        cylinder(h = flange_t, d = tab_w, $fn = 40);
                }
        }
        // the aperture itself, straight through everything
        translate([0, 0, plate_t])
            linear_extrude(plug_h + flange_t + 2)
                circle(d = d - plug_clear - 3, $fn = 200);
        translate([0, 0, -1]) linear_extrude(plate_t + 2) cutout(name);
    }
}

// PRINT THIS FIRST. Four plug diameters on one bar: the filter thread is metal
// and the fit has to be found, not computed - the same reason hotshoe.scad
// gauges its shoe foot rather than trusting the published ISO dimensions.
gauge_steps = [0.4, 0.6, 0.8, 1.0];
module gauge() {
    // TWO BY TWO, not a row. Four 67mm rings on a bar is 300mm long and the
    // Bambu P1S refuses anything past about 230.
    //
    // And JOINED, because four loose rings lint as four separate bodies, print
    // as four objects, and end up as four identical rings on a bench with
    // nothing to say which is which. The numbers are on the parts for the same
    // reason.
    pitch = thread + 6;
    for (i = [0 : len(gauge_steps) - 1])
        translate([(i % 2) * pitch - pitch / 2,
                   floor(i / 2) * pitch - pitch / 2, 0]) {
            difference() {
                union() {
                    cylinder(h = plug_h, d = thread - gauge_steps[i], $fn = 220);
                    translate([0, 0, plug_h])
                        cylinder(h = flange_t, d = thread + flange_w, $fn = 220);
                }
                translate([0, 0, -1])
                    cylinder(h = plug_h + flange_t + 2, d = thread - 16, $fn = 120);
            }
            translate([0, -(thread / 2 - 5), plug_h + flange_t - 0.6])
                linear_extrude(0.8)
                    text(str(gauge_steps[i]), size = 6, halign = "center",
                         valign = "center", font = "DejaVu Sans:style=Bold");
        }
    // snap-off webs, so it is one print you break apart
    for (r = [0, 1])
        translate([-pitch / 2, r * pitch - pitch / 2, 0])
            cube([pitch, 4, 1.2], center = false);
    translate([-2, -pitch / 2, 0]) cube([4, pitch, 1.2]);
}

module view_sheet() {
    names = ["ghost", "frank", "alien", "robot", "pumpkin",
             "bat", "cat", "hat", "moon", "saucer"];
    for (i = [0 : len(names) - 1])
        translate([(i % 5) * 34 - 68, -floor(i / 5) * 34, 0])
            linear_extrude(1) cutout(names[i]);
}

if      (part == "mask")       mask();
else if (part == "gauge")      gauge();
else if (part == "view_sheet") view_sheet();
else assert(false, str("unknown part: ", part));
