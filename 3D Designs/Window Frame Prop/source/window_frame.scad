// Simple 2x2-pane window frame prop, printed flat as one piece.
// Open OpenSCAD, tweak the numbers below, press F6 (render), then File > Export > Export as STL.

outer  = 200; // overall width/height (mm) - keep well under 256 to clear P1S corner exclusion zones
border = 20;  // width of the outer frame members (mm)
bar    = 15;  // width of the center cross bars / mullions (mm)
depth  = 8;   // thickness of the frame (mm) - this becomes print height (Z)

pane_w = (outer - 2*border - bar) / 2;
pane_h = pane_w; // square outer + symmetric grid -> square panes

module frame2d() {
    difference() {
        square([outer, outer]);

        // four pane openings (bottom-left, bottom-right, top-left, top-right)
        translate([border, border])
            square([pane_w, pane_h]);
        translate([border + pane_w + bar, border])
            square([pane_w, pane_h]);
        translate([border, border + pane_h + bar])
            square([pane_w, pane_h]);
        translate([border + pane_w + bar, border + pane_h + bar])
            square([pane_w, pane_h]);
    }
}

linear_extrude(height = depth)
    frame2d();
