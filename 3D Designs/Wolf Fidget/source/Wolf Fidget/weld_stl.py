"""Weld an STL to a 3dp grid in place, and prove it is watertight there.

    python weld_stl.py part.stl [more.stl ...]

Why (2026-11-11): clipping the traced wolf's colors to its outline leaves a
few vertex pairs under 0.001mm apart where a color meets the edge. Exact, but
the lint rounds to 3dp, merges them, and counts 3-9 edges "not shared by two
triangles". Same fix as Dragon Egg Box's weld() (DESIGN-NOTES, 2026-11-06):
snap to the grid, merge, drop collapsed triangles, assert every edge is used
exactly twice. Needs only numpy.
"""
import re
import sys

import numpy as np


def read_stl(path):
    data = open(path, "rb").read()
    if data[:5] == b"solid" and b"facet" in data[:400]:
        v = re.findall(rb"vertex\s+(\S+)\s+(\S+)\s+(\S+)", data)
        return np.array(v, dtype=float).reshape(-1, 3, 3)
    n = int(np.frombuffer(data[80:84], "<u4")[0])
    rec = np.frombuffer(data[84:84 + 50 * n], dtype=[("n", "<f4", 3), ("v", "<f4", (3, 3)), ("a", "<u2")])
    return rec["v"].astype(float)


def weld(tri, places=3):
    V = np.round(tri.reshape(-1, 3), places)
    V, inv = np.unique(V, axis=0, return_inverse=True)
    F = inv.reshape(-1, 3)
    F = F[(F[:, 0] != F[:, 1]) & (F[:, 1] != F[:, 2]) & (F[:, 0] != F[:, 2])]
    e = np.sort(np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]]), axis=1)
    _, counts = np.unique(e, axis=0, return_counts=True)
    bad = int((counts != 2).sum())
    assert bad == 0, f"{bad} edges not shared by exactly two triangles at {places}dp"
    return V[F]


def write_stl(tri, path):
    n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    rec = np.zeros(len(tri), dtype=[("n", "<f4", 3), ("v", "<f4", (3, 3)), ("a", "<u2")])
    rec["n"], rec["v"] = n, tri
    with open(path, "wb") as f:
        f.write(b"\0" * 80 + np.uint32(len(tri)).tobytes() + rec.tobytes())


if __name__ == "__main__":
    for p in sys.argv[1:]:
        t = read_stl(p)
        w = weld(t)
        write_stl(w, p)
        print(f"  welded {p}: {len(t)} -> {len(w)} triangles, watertight at 3dp")
