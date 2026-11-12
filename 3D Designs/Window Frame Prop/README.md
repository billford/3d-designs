# Window Frame Prop

![Window Frame Prop](images/window_frame.png)

A 200 × 200 mm window frame with four square panes, for shooting through in
product and portrait photography. Put it close to the lens and out of focus
for a "through the window" look, or light it from behind to cast pane
shadows.

It prints flat as one piece, 8 mm thick.

## Files

| file | what it is |
|---|---|
| `window_frame.stl` | the frame, ready to print |
| `window_frame.scad` | the OpenSCAD source |

## Printing

- Any filament. PLA is fine. Matte black or white photographs best.
- 0.2 mm layers, 0.4 mm nozzle, no supports.
- It needs a 200 × 200 mm bed area. On a smaller printer, shrink `outer`
  (see Remixing).
- It is a big flat part, so if the corners lift, add a 5 mm brim with a
  0 mm brim-object gap.

## Remixing

Open `window_frame.scad` in [OpenSCAD](https://openscad.org/) and change the
numbers at the top:

| setting | default | what it does |
|---|---|---|
| `outer` | 200 | overall width and height, mm |
| `border` | 20 | width of the outer frame |
| `bar` | 15 | width of the centre cross bars |
| `depth` | 8 | thickness, which is also the print height |

Press F6 to render, then File > Export > Export as STL.

## Licence

[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). See
`LICENSE`.
