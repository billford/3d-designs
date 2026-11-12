// Traced gremlin artwork, four ink layers.
//
// Produced by trace_gremlin.py from a raster illustration. The outlines in the
// source are ~8px on 1254px, which lands under 0.6mm at any sane sign size and
// will not print - so the colour layers are ERODED and the dark layer fills
// the gap. That manufactures a keyline of whatever width we choose (currently
// ~1.34mm at 110mm wide) instead of relying on the artwork's own line weight.
//
// Fine detail is gone by design: the hoodie lettering, the RJ45 pin blocks and
// the cable's coloured cores are all well below the 1.2mm floor.

art_dir = "art";

// Traced figure measures 404.9 x 393.5 units; scale is applied by the caller.
grem_units_w = 404.9;
grem_units_h = 393.5;
grem_off     = [21.6, 33.3];   // origin of the traced bbox

// $fn from the sign applies to every traced Bezier and explodes the mesh -
// the dark layer came out at 385k triangles and a 92MB STL. Curve tolerance
// is the right control here: 0.5mm segments are far finer than a 0.4mm
// nozzle can resolve anyway.
module grem_layer(name) {
    $fn = 0; $fs = 0.5; $fa = 8;
    translate([-grem_off[0] - grem_units_w / 2,
               -grem_off[1] - grem_units_h / 2])
        import(str(art_dir, "/", name, ".svg"));
}

// 2D, centred on the origin, scaled so the figure is `w` mm wide.
module gremlin(name, w) {
    scale(w / grem_units_w) grem_layer(name);
}
