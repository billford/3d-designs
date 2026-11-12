"""Collapse sliver edges in an exported STL, keeping it manifold.

    .venv/bin/python clean_mesh.py planter_shell.stl [tolerance_mm]

WHY. The tentacles meet the stone along curves, and every boolean along a
curve leaves a few sliver triangles a thousandth of a millimeter across. The
mesh is exactly manifold (0 bad edges at full precision), but a mesh checker
that rounds vertices to 3 decimals counts those slivers as 4- to 10-way
edges: "not manifold, do not slice" on a sound part (2026-10-27). Chasing them
one by one in the geometry took four rounds and they kept moving. Manifold's
simplify() collapses edges shorter than the tolerance and keeps the result
manifold, unlike a plain vertex weld, which on this part turned a sound mesh
into one with real holes.

Writes the STL back in place (binary), and refuses if the result is not a
valid manifold, or if the surface moved on average by more than the tolerance
(volume change / surface area). That replaced a 0.01% volume limit, which
refused the Dracula shell: a thin-walled 120mm part has so much surface that
an average shift of 0.0008mm moved its volume 0.02% (2026-10-28).
"""
import struct
import sys
import numpy as np
import manifold3d as m3d


def read_stl(path):
    data = open(path, "rb").read()
    if data[:5] == b"solid" and b"facet" in data[:300]:
        import re
        v = np.array(re.findall(rb"vertex\s+(\S+)\s+(\S+)\s+(\S+)", data), float).reshape(-1, 3)
    else:
        n = struct.unpack("<I", data[80:84])[0]
        rec = np.frombuffer(data[84:84 + 50 * n], dtype=np.dtype([("n", "<3f4"), ("v", "<9f4"), ("a", "<u2")]))
        v = rec["v"].reshape(-1, 3).astype(float)
    # STL repeats each vertex per triangle: index them exactly
    uniq, idx = np.unique(v, axis=0, return_inverse=True)
    return uniq, idx.reshape(-1, 3)


def write_stl(path, verts, tris):
    t = verts[tris]
    nrm = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
    nrm /= np.maximum(np.linalg.norm(nrm, axis=1), 1e-12)[:, None]
    rec = np.zeros(len(tris), dtype=np.dtype([("n", "<3f4"), ("v", "<9f4"), ("a", "<u2")]))
    rec["n"] = nrm
    rec["v"] = t.reshape(-1, 9)
    with open(path, "wb") as f:
        f.write(b"clean_mesh.py".ljust(80, b" "))
        f.write(struct.pack("<I", len(tris)))
        f.write(rec.tobytes())


def main():
    path = sys.argv[1]
    tol = float(sys.argv[2]) if len(sys.argv) > 2 else 0.01   # 0.005 still left 2
    v, f = read_stl(path)
    mesh = m3d.Mesh(vert_properties=np.asarray(v, np.float32), tri_verts=np.asarray(f, np.uint32))
    before = m3d.Manifold(mesh)
    if before.status() != m3d.Error.NoError:
        sys.exit(f"{path}: not a valid manifold to start with ({before.status()})")
    after = before.simplify(tol)
    if after.status() != m3d.Error.NoError:
        sys.exit(f"simplify failed: {after.status()}")
    dv = abs(after.volume() - before.volume()) / before.volume()
    shift = abs(after.volume() - before.volume()) / before.surface_area()
    if shift > tol:
        sys.exit(f"surface moved {shift:.4f}mm on average, over the {tol}mm tolerance: refusing")
    out = after.to_mesh()
    write_stl(path, np.asarray(out.vert_properties)[:, :3].astype(float), np.asarray(out.tri_verts))
    print(f"{path}: {len(f)} -> {len(out.tri_verts)} triangles, volume moved {dv:.5%} ({shift:.5f}mm)")


if __name__ == "__main__":
    main()
