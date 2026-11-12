// Sleek one-piece flying saucer - no seam, no holes, no dome to fit.
//
// Lit from OUTSIDE with studio RGBs shining through translucent filament, so
// there is nothing to get inside for: no lift-off dome, no spindle, no USB
// slot, no light holes. That removes every mating surface, which is where the
// two-part version spent its failures.
//
//   openscad --render -D 'part="shell"'   -o ufo_sleek.stl   ufo_sleek.scad
//   openscad --render -D 'part="section"' ...                cutaway, check walls
//
// Print it open-side down. The bottom ring is the first layer.

part   = "shell";        // "shell" | "section"

// ------------------------------------------------------------------ sizes
dia         = 150;      // widest point
base_r      = 66;       // flat bottom radius. Wide, which is what keeps the
                        // saucer LOW: rim_z falls out of this and under_deg,
                        // so a narrow base forces a tall, bubbly part.
under_deg   = 40;       // underside cone angle from vertical. THE critical
                        // number: the limit is atan(width/(2*layer)) = 46 at
                        // 0.2mm, and a curved underside cannot stay inside it
                        // without a base so wide there is no curve left. A
                        // straight cone at 40 keeps 6 degrees of margin.
// Top profile: a shallow cone (the BRIM) with a smooth bump on it (the DOME).
//
//   z(r) = (R - r) * tan(brim_deg)  +  dome_h * exp(-(r/dome_r)^2)
//
// The bump is a Gaussian, so it blends into the brim with no shoulder line at
// any radius. A cone meeting a hemisphere gives a hard junction, and that -
// plus a tall dome - is what made the earlier two-part version look like a
// bowler hat. Wide brim plus a LOW dome reads as a saucer; the brim was never
// the problem, the dome height was.
brim_deg    = 6;    // rise of the brim from rim to centre - keep it shallow
dome_r      = 32;   // how far out the central bump reaches
dome_h      = 22;   // its height above the brim
top_h       = 26;   // (unused by the bump profile, kept for the old lens)   // 150 x 37mm, ratio 0.24 - chosen over flatter
                    // variants: sleeker costs a wider unsupported top cap       // height of the top curve above the rim. ONE smooth
                        // curve from rim to apex - a separate canopy on a brim
                        // gives a shoulder corner, which reads as bubbly.
wall        = 1.8;      // thin, so the RGBs read through it
foot_w      = 4.0;      // width of the flat ring on the plate. Offsetting the
                        // inner void vertically on a 40-degree cone leaves a
                        // bottom edge under 1mm wide - 120mm2 of contact for a
                        // 150mm part, which peels. This sets it explicitly.

lip_h       = 2.0;      // short VERTICAL band at the widest point. A flange
                        // sticking out here would be a horizontal overhang;
                        // a vertical step is free to print and still catches a
                        // highlight line when the light rakes across it.

steps       = 72;       // dome smoothness
$fn         = 200;

rim_z = (dia / 2 - base_r) / tan(under_deg);

// ------------------------------------------------------------------ profile
// Underside: straight cone. Dome: quarter ellipse, which narrows going up and
// so never overhangs - except at the very crown, which is unavoidable on any
// closed dome.

// Quarter SUPERELLIPSE from rim to apex: |r/R|^n + |z/h|^n = 1.
//
//   top_n = 2.0  plain ellipse - a lens, no brim to speak of
//   top_n < 2.0  flatter near the rim and steeper in the middle, which reads
//                as a brim with a dome on it - WITHOUT the shoulder line that
//                a separate cone-plus-dome produces (that version came out
//                looking like a bowler hat)
//
// Below 2 also SHRINKS the unsupported cap at the apex, because the curve is
// steeper there. Flatter brim and easier print from the same parameter.
function top_z(r, R, bd, dr, dh) =
    (R - r) * tan(bd) + dh * exp(-pow(r / dr, 2));

function top_pt(i, R, dummy) =
    let (r = R * (1 - i / steps))
    [r, top_z(r, R, brim_deg, dome_r, dome_h)];

// [0,0] must be here. Without it polygon() closes from the canopy's apex
// straight back to the base radius, and the result has no flat bottom at all -
// it linted as 0mm2 of plate contact, which is what caught it.
//
// The RIM is what makes this read as a saucer rather than a dome on a cone:
// the underside cone and the upper face meet at dia/2 in a sharp edge, and the
// canopy starts inboard of it. Leaving the brim out was the first attempt and
// it looked like an egg.
function shell_profile(rim, br, rz, th, lip) = concat(
    [[0, 0], [br, 0], [rim, rz]],
    [for (i = [0 : steps]) top_pt(i, rim, th) + [0, rz + lip]]
);

module profile_2d() {
    polygon(shell_profile(dia / 2, base_r, rim_z, top_h, lip_h));
}

// Constant wall via offset() on the 2D profile, NOT by subtracting a second
// solid built from shrunken parameters. That approach cannot hold a wall on a
// slope: with the inner copy dropped 1.8mm and its base pulled in 4mm, the two
// 40-degree cones CONVERGED - 2.12mm of wall at the foot down to 0.29mm at the
// rim, under one extrusion width, and the slicer reported an empty layer
// between z8.2 and z9.2. offset(r = -wall) is perpendicular everywhere.
//
// It does close the bottom, so the floor is cut away explicitly - keeping a
// ring foot_w wide for the plate.
module shell() {
    rotate_extrude()
        difference() {
            profile_2d();
            offset(r = -wall) profile_2d();
            translate([-1, -1]) square([base_r - foot_w + 1, wall + 1]);
        }
}

// ------------------------------------------------------------------ output
if (part == "section")
    difference() { shell(); translate([0, -dia, -5]) cube([dia, dia * 2, dia]); }
else
    shell();
