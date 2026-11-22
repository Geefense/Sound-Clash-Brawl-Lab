#!/usr/bin/env python3
"""UV-preserving FBX decimator for the Sound Clash fighter uploads.

The uploads are binary FBX 7.4 files made by ImageToStl: one static mesh, one
material, one embedded 1024x1024 PNG. pymeshlab can collapse the mesh but cannot
read FBX, so this tool

  1. parses the FBX geometry (control points, polygon indices, UV table),
  2. round-trips it through a temporary OBJ so pymeshlab gets real per-corner UVs,
  3. runs ``meshing_decimation_quadric_edge_collapse_with_texture``,
  4. rebuilds the FBX node tree with the decimated Vertices / PolygonVertexIndex /
     normals / UVs while keeping every other node byte-for-byte (Model transforms,
     Material, Texture, Video with the embedded PNG, Connections),
  5. writes the result and prints the triangle / texture / bounds audit.

Usage:
  .venv/bin/python godot/tools/decimate_fbx.py <src.fbx> <dst.fbx> [--target 28000]

pymeshlab needs libOpenGL.so.0 on Linux. On this image the library is unpacked
under ``.f3d/.local-libs/root/usr/lib/x86_64-linux-gnu``; run with
``LD_LIBRARY_PATH=$PWD/.local-libs/root/usr/lib/x86_64-linux-gnu``.

The FBX writer only handles FBX 7.4 binary files, which is all this project has.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import struct
import subprocess
import sys
import tempfile
import zlib

import numpy as np

MAGIC = b"Kaydara FBX Binary  \x00"
FOOTER_ID = bytes.fromhex("fabcab09d0c8d466b176fb831cf7267e")


# =========================================================================
# FBX binary reader (same layout as the project's inspection scripts)
# =========================================================================
def read_fbx(path: str):
    data = open(path, "rb").read()
    assert data[:21] == MAGIC, "not a binary FBX"
    version = struct.unpack_from("<I", data, 23)[0]
    assert version == 7400, f"unsupported FBX version {version}"
    pos = [27]

    def props(n: int):
        out = []
        for _ in range(n):
            kind = chr(data[pos[0]])
            pos[0] += 1
            if kind == "Y":
                value = struct.unpack_from("<h", data, pos[0])[0]
                pos[0] += 2
            elif kind == "C":
                value = bool(data[pos[0]])
                pos[0] += 1
            elif kind == "I":
                value = struct.unpack_from("<i", data, pos[0])[0]
                pos[0] += 4
            elif kind == "F":
                value = struct.unpack_from("<f", data, pos[0])[0]
                pos[0] += 4
            elif kind == "D":
                value = struct.unpack_from("<d", data, pos[0])[0]
                pos[0] += 8
            elif kind == "L":
                value = struct.unpack_from("<q", data, pos[0])[0]
                pos[0] += 8
            elif kind in "SR":
                length = struct.unpack_from("<I", data, pos[0])[0]
                pos[0] += 4
                value = data[pos[0] : pos[0] + length]
                pos[0] += length
            elif kind in "fdlib":
                count, encoding, compressed = struct.unpack_from("<III", data, pos[0])
                pos[0] += 12
                raw = data[pos[0] : pos[0] + compressed]
                pos[0] += compressed
                if encoding == 1:
                    raw = zlib.decompress(raw)
                fmt = {"f": "f", "d": "d", "l": "q", "i": "i", "b": "B"}[kind]
                value = list(struct.unpack("<%d%s" % (count, fmt), raw))
            else:
                raise ValueError(f"unknown FBX property type {kind!r}")
            out.append((kind, value))
        return out

    def node():
        if pos[0] >= len(data):
            return None
        end, nprops, plen = struct.unpack_from("<III", data, pos[0])
        if end == 0:
            return None
        pos[0] += 12
        name_len = data[pos[0]]
        pos[0] += 1
        name = data[pos[0] : pos[0] + name_len].decode("utf-8", "replace")
        pos[0] += name_len
        node_props = props(nprops)
        children = []
        while pos[0] < end:
            child = node()
            if child is None:
                break
            children.append(child)
        # ImageToStl writes the child-list terminator even for leaf nodes, so a
        # childless node may end 13 bytes after its properties. Accept both shapes.
        if pos[0] + 13 == end:
            pos[0] = end
        assert pos[0] == end, f"{name} ended at {pos[0]}, expected {end}"
        return (name, node_props, children)

    root = []
    while True:
        item = node()
        if item is None:
            break
        root.append(item)
    return data, version, root


# =========================================================================
# Geometry extraction
# =========================================================================
def children_named(node, name):
    return [c for c in node[2] if c[0] == name]


def child(node, name):
    found = children_named(node, name)
    assert found, f"missing {name} under {node[0]}"
    return found[0]


def prop_value(node, index=0):
    return node[1][index][1]


def text_prop(node) -> str:
    return prop_value(node).decode("utf-8", "replace")


def find_geometry(root):
    for item in root:
        if item[0] == "Objects":
            for obj in item[2]:
                if obj[0] == "Geometry":
                    return obj
    raise RuntimeError("FBX has no Geometry node")


def geometry_arrays(geom):
    verts = np.array(prop_value(child(geom, "Vertices")), dtype=np.float64).reshape(-1, 3)
    raw = prop_value(child(geom, "PolygonVertexIndex"))
    faces = []
    polygon = []
    for value in raw:
        if value < 0:
            polygon.append(-value - 1)
            for i in range(1, len(polygon) - 1):
                faces.append((polygon[0], polygon[i], polygon[i + 1]))
            polygon = []
        else:
            polygon.append(value)
    assert not polygon, "unterminated polygon"
    faces = np.array(faces, dtype=np.int32)

    uv_node = child(geom, "LayerElementUV")
    uvs = np.array(prop_value(child(uv_node, "UV")), dtype=np.float64).reshape(-1, 2)
    uv_index = prop_value(child(uv_node, "UVIndex"))
    mapping = text_prop(child(uv_node, "MappingInformationType"))
    reference = text_prop(child(uv_node, "ReferenceInformationType"))
    if mapping == "ByPolygonVertex" and reference == "IndexToDirect":
        corner_uv = uvs[np.array(uv_index, dtype=np.int64)]
    else:
        raise RuntimeError(f"unsupported UV mapping {mapping}/{reference}")
    return verts, faces, corner_uv


def write_obj(path, verts, faces, corner_uv):
    lines = []
    for v in verts:
        lines.append(f"v {v[0]:.9g} {v[1]:.9g} {v[2]:.9g}\n")
    for uv in corner_uv:
        lines.append(f"vt {uv[0]:.9g} {uv[1]:.9g}\n")
    base = 1
    for i, f in enumerate(faces):
        a, b, c = (int(x) for x in f)
        u, v, w = base + i * 3, base + i * 3 + 1, base + i * 3 + 2
        # OBJ UV indices share the `vt` list, so no offset by vertex count here.
        lines.append(f"f {a + 1}/{u} {b + 1}/{v} {c + 1}/{w}\n")
    with open(path, "w", encoding="utf-8") as fh:
        fh.writelines(lines)


# =========================================================================
# Decimation
# =========================================================================
def decimate(src: str, target: int, quality: float = 0.8, uv_weight: float = 0.35):
    import pymeshlab

    verts, faces, corner_uv = geometry_arrays(find_geometry(read_fbx(src)[2]))
    print(f"  source: {len(verts)} verts, {len(faces)} tris, {len(corner_uv)} corner UVs")
    with tempfile.TemporaryDirectory() as tmp:
        src_obj = os.path.join(tmp, "source.obj")
        write_obj(src_obj, verts, faces, corner_uv)
        ms = pymeshlab.MeshSet()
        ms.load_new_mesh(src_obj)
        ms.meshing_decimation_quadric_edge_collapse_with_texture(
            targetfacenum=target,
            qualitythr=quality,
            extratcoordw=uv_weight,
            preserveboundary=False,
            boundaryweight=1.0,
            optimalplacement=True,
            preservenormal=True,
            planarquadric=True,
            selected=False,
        )
        mesh = ms.current_mesh()
        out_verts = np.array(mesh.vertex_matrix(), dtype=np.float64)
        out_faces = np.array(mesh.face_matrix(), dtype=np.int32)
        out_normals = np.array(mesh.vertex_normal_matrix(), dtype=np.float64)
        out_wedges = np.array(mesh.wedge_tex_coord_matrix(), dtype=np.float64)
    if out_wedges.shape[0] != len(out_faces) * 3:
        raise RuntimeError(f"lost wedge UVs: {out_wedges.shape} vs {len(out_faces) * 3} corners")
    return out_verts, out_faces, out_normals, out_wedges


# =========================================================================
# FBX binary writer
# =========================================================================
def encode_property(kind: str, value) -> bytes:
    if kind == "Y":
        return b"Y" + struct.pack("<h", value)
    if kind == "C":
        return b"C" + bytes([1 if value else 0])
    if kind == "I":
        return b"I" + struct.pack("<i", value)
    if kind == "F":
        return b"F" + struct.pack("<f", value)
    if kind == "D":
        return b"D" + struct.pack("<d", value)
    if kind == "L":
        return b"L" + struct.pack("<q", value)
    if kind == "S":
        return b"S" + struct.pack("<I", len(value)) + value
    if kind == "R":
        return b"R" + struct.pack("<I", len(value)) + value
    if kind in "fdlib":
        fmt = {"f": "f", "d": "d", "l": "q", "i": "i", "b": "B"}[kind]
        raw = struct.pack("<%d%s" % (len(value), fmt), *value)
        packed = zlib.compress(raw, 6)
        return kind.encode() + struct.pack("<III", len(value), 1, len(packed)) + packed
    raise ValueError(f"cannot encode property type {kind!r}")


def serialise_node(node, base: int) -> bytes:
    name, properties, children = node
    name_bytes = name.encode("utf-8")
    body = b"".join(encode_property(kind, value) for kind, value in properties)
    child_bytes = []
    cursor = base + 12 + 1 + len(name_bytes) + len(body)
    for child_node in children:
        encoded = serialise_node(child_node, cursor)
        child_bytes.append(encoded)
        cursor += len(encoded)
    tail = b"".join(child_bytes)
    has_children = bool(children)
    total = 12 + 1 + len(name_bytes) + len(body) + len(tail) + (13 if has_children else 0)
    header = struct.pack("<III", base + total, len(properties), len(body))
    header += bytes([len(name_bytes)]) + name_bytes
    return header + body + tail + (b"\x00" * 13 if has_children else b"")


def array_node(name, kind, values):
    return (name, [(kind, values)], [])


def scalar_node(name, kind, value):
    return (name, [(kind, value)], [])


def string_node(name, value):
    return (name, [("S", value.encode("utf-8"))], [])


def build_geometry_node(original, verts, faces, normals, wedges):
    face_count = len(faces)
    flat_indices = []
    for tri in faces:
        flat_indices.extend((int(tri[0]), int(tri[1]), -int(tri[2]) - 1))
    corner_normals = []
    for tri in faces:
        for index in tri:
            corner_normals.extend((float(normals[index][0]), float(normals[index][1]),
                                   float(normals[index][2])))
    uv_flat = []
    for uv in wedges:
        uv_flat.extend((float(uv[0]), float(uv[1])))

    def layer_element(kind: str, index: int, mapping: str, reference: str, payload):
        return ("LayerElement" + kind, [("I", index)], [
            scalar_node("Version", "I", 101),
            string_node("Name", ""),
            string_node("MappingInformationType", mapping),
            string_node("ReferenceInformationType", reference),
            payload,
        ])

    layers = ("Layer", [("I", 0)], [
        scalar_node("Version", "I", 100),
        ("LayerElement", [], [
            string_node("Type", "LayerElementNormal"),
            scalar_node("TypedIndex", "I", 0),
        ]),
        ("LayerElement", [], [
            string_node("Type", "LayerElementMaterial"),
            scalar_node("TypedIndex", "I", 0),
        ]),
        ("LayerElement", [], [
            string_node("Type", "LayerElementUV"),
            scalar_node("TypedIndex", "I", 0),
        ]),
    ])

    def payload(name, kind, values):
        return (name, [(kind, values)], [])

    new_children = [
        array_node("Vertices", "d", [float(x) for row in verts for x in row]),
        array_node("PolygonVertexIndex", "i", flat_indices),
        scalar_node("GeometryVersion", "I", 124),
        layer_element("Normal", 0, "ByPolygonVertex", "Direct",
                      payload("Normals", "d", corner_normals)),
        layer_element("Material", 0, "ByPolygon", "IndexToDirect",
                      payload("Materials", "i", [0] * face_count)),
        layer_element("UV", 0, "ByPolygonVertex", "Direct", payload("UV", "d", uv_flat)),
        layers,
    ]
    return (original[0], original[1], new_children)


def write_fbx(src, dst, verts, faces, normals, wedges):
    data, version, root = read_fbx(src)
    geometry = find_geometry(root)
    rebuilt = build_geometry_node(geometry, verts, faces, normals, wedges)
    replaced = []
    for item in root:
        if item[0] == "Objects":
            replaced.append((item[0], item[1],
                             [rebuilt if child_node is geometry else child_node
                              for child_node in item[2]]))
        else:
            replaced.append(item)

    out = bytearray(MAGIC + b"\x1a\x00" + struct.pack("<I", version))
    for top in replaced:
        out += serialise_node(top, len(out))
    out += b"\x00" * 13
    footer_at = data.find(FOOTER_ID)
    assert footer_at > 0, "no FBX footer"
    out += data[footer_at:]

    stitched = bytes(out)
    # Structural sanity: re-read what we just wrote before replacing the game asset.
    with tempfile.NamedTemporaryFile(suffix=".fbx", delete=False) as tmp:
        tmp.write(stitched)
        check_path = tmp.name
    try:
        check_root = read_fbx(check_path)[2]
        check_geom = find_geometry(check_root)
        check_faces = len(prop_value(child(check_geom, "PolygonVertexIndex"))) // 3
        assert check_faces == len(faces), (check_faces, len(faces))
        objects = next(n for n in check_root if n[0] == "Objects")
        embedded = []
        for name, _props, video_children in objects[2]:
            if name != "Video":
                continue
            for child_name, child_props, _child_children in video_children:
                if child_name == "Content":
                    embedded.append(len(child_props[0][1]))
    finally:
        os.unlink(check_path)
    os.makedirs(os.path.dirname(os.path.abspath(dst)), exist_ok=True)
    with open(dst, "wb") as fh:
        fh.write(stitched)
    return embedded, version


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("src")
    parser.add_argument("dst")
    parser.add_argument("--target", type=int, default=28000)
    parser.add_argument("--quality", type=float, default=0.8)
    parser.add_argument("--uv-weight", type=float, default=0.35)
    args = parser.parse_args()

    verts, faces, normals, wedges = decimate(args.src, args.target, args.quality, args.uv_weight)
    embedded, version = write_fbx(args.src, args.dst, verts, faces, normals, wedges)
    raw = open(args.dst, "rb").read()
    print(f"  output: {len(verts)} verts, {len(faces)} tris, UVs {wedges.shape[0]}")
    print(f"  bounds: y {verts[:, 1].min():.4f}..{verts[:, 1].max():.4f} "
          f"(height {verts[:, 1].max() - verts[:, 1].min():.4f})")
    print(f"  embedded PNGs: {embedded} bytes")
    print(f"  FBX {version}, {len(raw)} bytes, sha256 {hashlib.sha256(raw).hexdigest()}")


if __name__ == "__main__":
    main()
