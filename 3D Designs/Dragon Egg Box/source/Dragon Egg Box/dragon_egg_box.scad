// Dragon-scale gift box for the Textured Twisty Dragon Egg fidget. 2026-11-06.
// The egg (not included) is NUKDDD's, printed at 100%:
//   https://makerworld.com/en/models/2865269-textured-twisty-dragon-egg-fidget
//
// SEPARATE PRINTS: 2 objects, one plate, no supports, no brim, 0.2mm layers:
//   base  - upright, open side up; the BX mark is engraved under it
//   lid   - upright, rim on the bed, finial up
//
// view_assembly.stl and view_with_egg.stl are PICTURES. Never slice them.
//
// The shapes are box_base_shape.stl and box_lid_shape.stl, written by box.py:
// re-run it after changing anything there. Every fit and overhang is asserted
// there, not here.

use <../Makers Mark/mark.scad>

part = "base";   // base | lid
mark = true;     // engraved: no inlay parts, so the pocket prints as a recess
mark_w = 20;     // on the 74mm plinth's underside, centred under the egg's floor

if (part == "base") difference() {
    import("box_base_shape.stl", convexity = 8);
    if (mark) bx_mark_pocket(mark_w, face = "bottom");
}
else if (part == "lid") import("box_lid_shape.stl", convexity = 8);
else assert(false, str("unknown part: ", part));
