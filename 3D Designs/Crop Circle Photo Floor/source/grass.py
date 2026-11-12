"""Displace standing crop into grass texture, leaving the laid crop smooth.

    blender --background --python grass.py -- in.stl out.stl [feature] [amp]

WHY THIS IS AN ADDED CARPET AND NOT A DISPLACED SURFACE

The obvious move is to subdivide the tile's top face and push the vertices
around. Two things kill it: subdividing a 200mm triangle down to 0.7mm is
4^8 triangles per face, and any remesh dense enough to texture the grass also
rounds off the formation's edges - which are the entire point of the model.

So the original mesh is never touched. A carpet is built ONLY over the standing
crop, sunk far enough to overlap, displaced, and unioned on. The formation's
edges survive exactly as OpenSCAD cut them.

WHY THE LAID CROP IS MASKED OUT

Two reasons, and the second is the one that would have bitten.

  It is smooth in life: flattened stems lie flat, which is why they read paler
  in every aerial photograph of a formation.

  And the recess floor sits EXACTLY on the filament-change layer (5.6mm = layer
  28 at 0.2mm). Displacing it up by even one layer would print laid crop in the
  standing crop's colour, and the two-tone trick is the only reason the
  formation reads at all from directly overhead.

Which surface is which is decided by RAYCASTING down onto the real mesh, not by
assuming - a grid point over standing crop hits near the top, one over laid
crop hits the recess floor, one off the edge hits nothing.
"""

import sys

import bmesh
import bpy
from mathutils import Vector
from mathutils import noise as mnoise

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if len(argv) < 2:
    print("usage: grass.py -- in.stl out.stl [feature_mm] [amplitude_mm]")
    sys.exit(1)

src, dst = argv[0], argv[1]
feature = float(argv[2]) if len(argv) > 2 else 2.0    # noise wavelength
amp = float(argv[3]) if len(argv) > 3 else 0.6        # peak-to-zero height
step = feature / 3.0                                   # grid pitch
sink = 1.0                                             # carpet overlap into the tile
TOL = 0.35                                             # "is this the top surface"

bpy.ops.wm.read_factory_settings(use_empty=True)
if hasattr(bpy.ops.wm, "stl_import"):
    bpy.ops.wm.stl_import(filepath=src)
else:
    bpy.ops.import_mesh.stl(filepath=src)

tile = bpy.context.selected_objects[0]
bpy.context.view_layer.objects.active = tile

lo = Vector((min(c[0] for c in tile.bound_box),
             min(c[1] for c in tile.bound_box),
             min(c[2] for c in tile.bound_box)))
hi = Vector((max(c[0] for c in tile.bound_box),
             max(c[1] for c in tile.bound_box),
             max(c[2] for c in tile.bound_box)))
top_z = hi.z
print(f"[grass] {src}: {lo.x:.1f}..{hi.x:.1f} x {lo.y:.1f}..{hi.y:.1f}, "
      f"top at z={top_z:.2f}")

nx = int((hi.x - lo.x) / step) + 1
ny = int((hi.y - lo.y) / step) + 1
print(f"[grass] grid {nx} x {ny} at {step:.2f}mm "
      f"(feature {feature}mm, amplitude {amp}mm)")


def on_standing_crop(x, y):
    """Raycast down: True only where the STANDING crop's top surface is."""
    origin = Vector((x, y, top_z + 10.0))
    hit, loc, _, _ = tile.ray_cast(origin, Vector((0, 0, -1)))
    return hit and abs(loc.z - top_z) < TOL


def grass_h(x, y):
    """Fractal noise, so it reads as a crop rather than as ripples."""
    v = Vector((x / feature, y / feature, 0.0))
    return amp * mnoise.fractal(v, 1.0, 2.0, 3)


# ------------------------------------------------------------ build the carpet
mask = [[on_standing_crop(lo.x + i * step, lo.y + j * step)
         for j in range(ny)] for i in range(nx)]

# A FLAT bottom, and a skirt walked cell by cell.
#
# Solidify was tried and is wrong here: it offsets the displaced surface along
# its own normals, so wherever the noise curves tighter than the thickness the
# offset copy crosses itself. That reports ZERO non-manifold edges and is still
# self-intersecting, and an exact boolean against it silently threw the tile
# away and kept the grass - twice. A flat bottom cannot self-intersect.
cells = {(i, j) for i in range(nx - 1) for j in range(ny - 1)
         if all(mask[i + di][j + dj] for di, dj in ((0, 0), (1, 0), (1, 1), (0, 1)))}
if not cells:
    print("[grass] NOTHING TO TEXTURE - no standing crop at the top surface. "
          "Check TOL against this model's recess depth.")
    sys.exit(2)

# DIAGONAL PINCHES break the skirt. Where two cells meet only at a corner -
# (i,j) and (i+1,j+1) present, the other two absent - the boundary passes
# through that corner twice and the skirt wraps it twice, giving an edge with
# three faces. The manifold gate caught exactly one of these on tile 0 and
# stopped the build, which is the gate working; this removes the cause.
def depinch(cs):
    dropped = 0
    while True:
        hits = []
        for (i, j) in cs:
            a, b = (i, j) in cs, (i + 1, j) in cs
            c, d = (i, j + 1) in cs, (i + 1, j + 1) in cs
            if a and d and not b and not c:
                hits.append((i + 1, j + 1))
            elif b and c and not a and not d:
                hits.append((i, j + 1))
        hits = [h for h in hits if h in cs]
        if not hits:
            return dropped
        for h in hits:
            cs.discard(h)
        dropped += len(hits)


pinched = depinch(cells)
if pinched:
    print(f"[grass] removed {pinched} diagonal pinch cell(s)")

corners = {c for (i, j) in cells
           for c in ((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1))}

bm = bmesh.new()
bot_z = top_z - sink
top = {}
bot = {}
for (i, j) in corners:
    x, y = lo.x + i * step, lo.y + j * step
    top[(i, j)] = bm.verts.new((x, y, top_z + grass_h(x, y)))
    bot[(i, j)] = bm.verts.new((x, y, bot_z))
bm.verts.index_update()

for (i, j) in cells:
    c = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]
    bm.faces.new([top[k] for k in c])
    bm.faces.new([bot[k] for k in reversed(c)])

# Skirt: for every cell edge with no neighbouring cell, close the side. Walked
# from the CELL set, so it needs no vertex lookup and cannot mis-pair.
sides = {(-1, 0): ((0, 0), (0, 1)), (1, 0): ((1, 0), (1, 1)),
         (0, -1): ((0, 0), (1, 0)), (0, 1): ((0, 1), (1, 1))}
skirt = 0
for (i, j) in cells:
    for (di, dj), (p, q) in sides.items():
        if (i + di, j + dj) in cells:
            continue
        ka = (i + p[0], j + p[1])
        kb = (i + q[0], j + q[1])
        bm.faces.new([top[ka], top[kb], bot[kb], bot[ka]])
        skirt += 1

bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
open_edges = sum(1 for e in bm.edges if len(e.link_faces) != 2)
print(f"[grass] carpet: {len(cells)} cells, {skirt} skirt faces, "
      f"{len(bm.verts)} verts, {open_edges} non-manifold edges")
if open_edges:
    print("[grass] REFUSING TO BOOLEAN a non-manifold carpet - the union "
          "would silently drop the tile.")
    sys.exit(3)

mesh = bpy.data.meshes.new("grass")
bm.to_mesh(mesh)
bm.free()
carpet = bpy.data.objects.new("grass", mesh)
bpy.context.collection.objects.link(carpet)

# ------------------------------------------------------------------ union it
bpy.context.view_layer.objects.active = tile
mod = tile.modifiers.new("grass", "BOOLEAN")
mod.operation = "UNION"
mod.object = carpet
mod.solver = "EXACT"
bpy.ops.object.modifier_apply(modifier="grass")
bpy.data.objects.remove(carpet, do_unlink=True)

tile.select_set(True)
bpy.context.view_layer.objects.active = tile
zs = [v.co.z for v in tile.data.vertices]
print(f"[grass] result: {len(tile.data.polygons)} faces, "
      f"tile z {min(zs):.2f}..{max(zs):.2f}")
print(f"[grass] objects in scene: "
      f"{[(o.name, len(o.data.vertices)) for o in bpy.data.objects]}")

if hasattr(bpy.ops.wm, "stl_export"):
    bpy.ops.wm.stl_export(filepath=dst, export_selected_objects=False)
else:
    bpy.ops.export_mesh.stl(filepath=dst)
print(f"[grass] wrote {dst}")
